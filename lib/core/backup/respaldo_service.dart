import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

const _dbEnZip = 'agrocontrol.db';
const _manifiestoEnZip = 'respaldo.json';
const _fotosEnZip = 'evidencias';

/// Nombre del archivo de respaldo: `agrocontrol_respaldo_2026-11-15_0930.zip`.
String nombreRespaldo(DateTime t) => 'agrocontrol_respaldo_${DateFormat('yyyy-MM-dd_HHmm').format(t)}.zip';

/// Solo se aceptan fotos con nombre simple: nada de carpetas ni "..".
bool nombreFotoValido(String nombre) =>
    nombre.isNotEmpty && nombre == p.basename(nombre) && !nombre.startsWith('.') && !nombre.contains('\\');

/// Por qué un respaldo no se puede restaurar, o null si sirve.
String? problemaDelManifiesto(Map<String, dynamic>? m, {required int versionBase}) {
  if (m == null || m['app'] != 'agrocontrol') return 'El archivo no es un respaldo de AgroControl.';
  final v = m['version_base'];
  if (v is! int) return 'El respaldo está incompleto.';
  if (v > versionBase) return 'El respaldo es de una versión más nueva de la app. Actualiza AgroControl primero.';
  return null;
}

/// Copia de seguridad de todo lo del teléfono (base local y fotos) en un
/// solo .zip, y su restauración. Mientras la sincronización no esté lista,
/// es la única forma de no perder una campaña si se pierde el teléfono.
class RespaldoService {
  Future<Directory> get _docs => getApplicationDocumentsDirectory();

  /// Arma el .zip en la carpeta temporal y devuelve su ruta para compartirlo.
  Future<File> exportar() async {
    final db = await AppDatabase.database;
    // Pasa a la base todo lo que quedó en el registro WAL, para copiar un solo archivo completo.
    await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');

    final docs = await _docs;
    final destino = File(p.join((await getTemporaryDirectory()).path, nombreRespaldo(DateTime.now())));
    final info = await PackageInfo.fromPlatform();
    final manifiesto = File(p.join((await getTemporaryDirectory()).path, _manifiestoEnZip))
      ..writeAsStringSync(jsonEncode({
        'app': 'agrocontrol',
        'version_app': info.version,
        'version_base': AppDatabase.version,
        'fecha': DateTime.now().toIso8601String(),
        'carpeta_documentos': docs.path,
      }));

    final zip = ZipFileEncoder()..create(destino.path);
    await zip.addFile(manifiesto, _manifiestoEnZip);
    await zip.addFile(File(db.path), _dbEnZip);
    final fotos = Directory(p.join(docs.path, _fotosEnZip));
    if (fotos.existsSync()) {
      for (final f in fotos.listSync().whereType<File>()) {
        await zip.addFile(f, '$_fotosEnZip/${p.basename(f.path)}');
      }
    }
    await zip.close();
    return destino;
  }

  /// Reemplaza todo lo del teléfono por el respaldo. Antes guarda una copia
  /// de la base actual en `respaldos/antes_de_restaurar.db` por si acaso.
  /// Lanza [RespaldoInvalido] si el archivo no sirve; en ese caso no toca nada.
  Future<void> restaurar(File archivo) async {
    final tmp = await Directory(p.join((await getTemporaryDirectory()).path, 'restaurar')).create();
    try {
      await _restaurar(archivo, tmp);
    } finally {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    }
  }

  Future<void> _restaurar(File archivo, Directory tmp) async {
    final entrada = InputFileStream(archivo.path);
    final Archive zip;
    try {
      zip = ZipDecoder().decodeStream(entrada);
    } catch (_) {
      await entrada.close();
      throw const RespaldoInvalido('El archivo no es un respaldo de AgroControl.');
    }

    try {
      Map<String, dynamic>? manifiesto;
      final fotos = <ArchiveFile>[];
      ArchiveFile? base;
      for (final f in zip.files.where((f) => f.isFile)) {
        if (f.name == _manifiestoEnZip) {
          manifiesto = jsonDecode(utf8.decode(f.readBytes() ?? const [])) as Map<String, dynamic>?;
        } else if (f.name == _dbEnZip) {
          base = f;
        } else if (f.name.startsWith('$_fotosEnZip/') && nombreFotoValido(f.name.substring(_fotosEnZip.length + 1))) {
          fotos.add(f);
        }
      }
      final problema = problemaDelManifiesto(manifiesto, versionBase: AppDatabase.version);
      if (problema != null) throw RespaldoInvalido(problema);
      if (base == null) throw const RespaldoInvalido('El respaldo está incompleto.');

      // Se revisa la base copiada aparte antes de tocar la del teléfono.
      final nueva = File(p.join(tmp.path, _dbEnZip))..writeAsBytesSync(base.readBytes()!);
      await _verificarBase(nueva.path);

      final docs = await _docs;
      final actual = File(p.join(await getDatabasesPath(), AppDatabase.nombreArchivo));
      final copias = await Directory(p.join(docs.path, 'respaldos')).create(recursive: true);

      final db = await AppDatabase.database;
      await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
      await AppDatabase.close();
      if (actual.existsSync()) actual.copySync(p.join(copias.path, 'antes_de_restaurar.db'));
      for (final extra in ['-wal', '-shm', '-journal']) {
        final f = File('${actual.path}$extra');
        if (f.existsSync()) f.deleteSync();
      }
      nueva.copySync(actual.path);

      final carpetaFotos = await Directory(p.join(docs.path, _fotosEnZip)).create(recursive: true);
      for (final f in fotos) {
        File(p.join(carpetaFotos.path, p.basename(f.name))).writeAsBytesSync(f.readBytes()!);
      }

      // Si el respaldo viene de otro teléfono, las rutas de las fotos apuntan a su carpeta.
      final carpetaOrigen = manifiesto!['carpeta_documentos'] as String?;
      final reabierta = await AppDatabase.database;
      if (carpetaOrigen != null && carpetaOrigen != docs.path) {
        await _cambiarRutas(reabierta, carpetaOrigen, docs.path);
      }
    } finally {
      await entrada.close();
    }
  }

  Future<void> _verificarBase(String ruta) async {
    Database? db;
    try {
      db = await openDatabase(ruta, readOnly: true, singleInstance: false);
      final tablas = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name IN ('campanas','users')");
      if (tablas.length < 2) throw const RespaldoInvalido('El respaldo está dañado.');
      final check = await db.rawQuery('PRAGMA quick_check');
      if (check.first.values.first != 'ok') throw const RespaldoInvalido('El respaldo está dañado.');
    } on RespaldoInvalido {
      rethrow;
    } catch (_) {
      throw const RespaldoInvalido('El respaldo está dañado.');
    } finally {
      await db?.close();
    }
  }

  /// Cambia la carpeta de origen por la de este teléfono en todos los textos de la base.
  Future<void> _cambiarRutas(Database db, String origen, String destino) async {
    final tablas = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'");
    for (final t in tablas) {
      final tabla = t['name'] as String;
      final columnas = await db.rawQuery('PRAGMA table_info("$tabla")');
      for (final c in columnas.where((c) => '${c['type']}'.toUpperCase().contains('TEXT'))) {
        final col = c['name'] as String;
        await db.rawUpdate('UPDATE "$tabla" SET "$col" = replace("$col", ?, ?) WHERE instr("$col", ?) > 0', [origen, destino, origen]);
      }
    }
  }
}

class RespaldoInvalido implements Exception {
  final String mensaje;
  const RespaldoInvalido(this.mensaje);

  @override
  String toString() => mensaje;
}
