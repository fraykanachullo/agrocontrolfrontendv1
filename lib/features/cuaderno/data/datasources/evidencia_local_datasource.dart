import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/app_database.dart';

class EvidenciaLocalDatasource {
  /// Copia una foto (cámara o galería) a la carpeta de evidencias de la app,
  /// para que siga disponible hasta que se suba al servidor.
  Future<File> copyToEvidencias(String originalPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/evidencias');
    if (!await dir.exists()) await dir.create(recursive: true);
    final fileName = 'evid_${DateTime.now().millisecondsSinceEpoch}${p.extension(originalPath)}';
    return File(originalPath).copy('${dir.path}/$fileName');
  }

  Future<int> saveEvidencia({
    required int relacionId,
    required String relacionTipo,
    required String rutaArchivo,
  }) async {
    final db = await AppDatabase.database;
    return await db.insert('evidencias', {
      'relacion_id': relacionId,
      'relacion_tipo': relacionTipo,
      'ruta_archivo': rutaArchivo,
      'created_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getEvidencias({
    required int relacionId,
    required String relacionTipo,
  }) async {
    final db = await AppDatabase.database;
    return await db.query(
      'evidencias',
      where: 'relacion_id = ? AND relacion_tipo = ?',
      whereArgs: [relacionId, relacionTipo],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPendingEvidencias() async {
    final db = await AppDatabase.database;
    return await db.query(
      'evidencias',
      where: 'is_synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markSynced(int id, String uuidLocal) async {
    final db = await AppDatabase.database;
    await db.update(
      'evidencias',
      {'is_synced': 1, 'uuid_local': uuidLocal},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
