import 'package:intl/intl.dart';
import '../datasources/campana_remote_datasource.dart';
import '../datasources/campana_local_datasource.dart';
import '../../domain/entities/campana.dart';
import '../../domain/repositories/campana_repository.dart';
import '../../../../core/sync/sync_queue_service.dart';

/// Usuario dueño de los datos locales. Aún fijo: falta tomarlo de la sesión.
const kLocalUserId = 2;

class CampanaRepositoryImpl implements CampanaRepository {
  final CampanaRemoteDatasource _remote;
  final CampanaLocalDatasource _local;
  final SyncQueueService _syncQueue;
  final int _userId;

  CampanaRepositoryImpl(this._remote, this._local, this._syncQueue, {int userId = kLocalUserId})
      : _userId = userId;

  @override
  Future<List<Campana>> listCampanas() async {
    // Try online first, fall back to local
    try {
      final campanas = await _remote.listCampanas();
      // Cache to local DB. El servidor aún no conoce terreno, variedad ni
      // fecha de siembra: se conservan los valores locales.
      for (final c in campanas) {
        final local = await _local.getCampana(c.id);
        await _local.insertCampana({
          'terreno_id': local?.terrenoId,
          'variedad': local?.variedad,
          'fecha_siembra': local?.fechaSiembra?.toIso8601String().substring(0, 10),
          'id': c.id,
          'user_id': _userId,
          'nombre': c.nombre,
          'cultivo': c.cultivo,
          'extension': c.extension,
          'tipo_extension': c.tipoExtension,
          'latitud': c.latitud,
          'longitud': c.longitud,
          'estado': c.estado,
          'fecha_inicio': c.fechaInicio?.toIso8601String(),
          'fecha_cierre': c.fechaCierre?.toIso8601String(),
          'balance_neto_final': c.balanceNetoFinal,
          'created_at': c.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'is_synced': 1,
        });
      }
      return await _local.listCampanas(_userId);
    } catch (_) {
      // Offline: read from local DB
      return await _local.listCampanas(_userId);
    }
  }

  @override
  Future<Campana> getCampana(int id) async {
    try {
      return await _remote.getCampana(id);
    } catch (_) {
      final campana = await _local.getCampana(id);
      if (campana != null) return campana;
      rethrow;
    }
  }

  @override
  Future<Campana> createCampana({
    required String nombre,
    required String cultivo,
    required double extension,
    required String tipoExtension,
    required DateTime fechaInicio,
    double? latitud,
    double? longitud,
    int? terrenoId,
    String? variedad,
  }) async {
    final uuidLocal = SyncQueueService.generateUuid();
    final data = {
      'user_id': _userId,
      'nombre': nombre,
      'cultivo': cultivo,
      'extension': extension,
      'tipo_extension': tipoExtension,
      'latitud': latitud,
      'longitud': longitud,
      'estado': 'activa',
      'fecha_inicio': fechaInicio.toIso8601String().substring(0, 10),
      'terreno_id': terrenoId,
      'variedad': variedad,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Try online first
    try {
      final campana = await _remote.createCampana(
        nombre: nombre,
        cultivo: cultivo,
        extension: extension,
        tipoExtension: tipoExtension,
        fechaInicio: fechaInicio,
        latitud: latitud,
        longitud: longitud,
      );
      // Also save locally with the server ID
      await _local.insertCampana({
        ...data,
        'id': campana.id,
        'is_synced': 1,
      });
      return (await _local.getCampana(campana.id)) ?? campana;
    } catch (_) {
      // Offline: save to local DB + queue for sync
      final id = await _local.insertCampana({
        ...data,
        'uuid_local': uuidLocal,
      });
      await _syncQueue.enqueue(
        tabla: 'campanas',
        operacion: 'create',
        datos: {
          ...data,
        },
      );
      return Campana(
        id: id,
        nombre: nombre,
        cultivo: cultivo,
        extension: extension,
        tipoExtension: tipoExtension,
        latitud: latitud,
        longitud: longitud,
        estado: 'activa',
        fechaInicio: fechaInicio,
        terrenoId: terrenoId,
        variedad: variedad,
      );
    }
  }

  @override
  Future<Campana> updateCampana(int id, {String? nombre, String? cultivo}) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (cultivo != null) data['cultivo'] = cultivo;

    try {
      return await _remote.updateCampana(id, nombre: nombre, cultivo: cultivo);
    } catch (_) {
      await _local.updateCampana(id, data);
      await _syncQueue.enqueue(
        tabla: 'campanas',
        operacion: 'update',
        datos: {'id': id, ...data},
      );
      final campana = await _local.getCampana(id);
      if (campana != null) return campana;
      rethrow;
    }
  }

  @override
  Future<Campana> cerrarCampana(int id) async {
    try {
      return await _remote.cerrarCampana(id);
    } catch (_) {
      await _local.updateCampana(id, {
        'estado': 'cerrada',
        'fecha_cierre': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
      await _syncQueue.enqueue(
        tabla: 'campanas',
        operacion: 'update',
        datos: {
          'id': id,
          'estado': 'cerrada',
          'fecha_cierre': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        },
      );
      final campana = await _local.getCampana(id);
      if (campana != null) return campana;
      rethrow;
    }
  }

  @override
  Future<void> registrarSiembra(int id, DateTime fecha) async {
    final data = {'fecha_siembra': DateFormat('yyyy-MM-dd').format(fecha)};
    await _local.updateCampana(id, data);
    await _syncQueue.enqueue(tabla: 'campanas', operacion: 'update', datos: {'id': id, ...data});
  }
}
