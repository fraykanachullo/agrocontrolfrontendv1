import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../network/connectivity_service.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';
import '../database/app_database.dart';
import 'sync_queue_service.dart';

enum SyncStatus { idle, syncing, error }

class SyncManager {
  final SyncQueueService _queueService;
  final DioClient _dioClient;
  final ConnectivityService _connectivityService;

  StreamSubscription? _connectivitySubscription;
  Timer? _periodicRefresh;
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();

  SyncManager(this._queueService, this._dioClient, this._connectivityService);

  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<int> get pendingCountStream => _pendingCountController.stream;
  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  void init() {
    _connectivitySubscription = _connectivityService.statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        syncPending();
      }
    });
    _refreshPendingCount();
    _periodicRefresh = Timer.periodic(const Duration(seconds: 10), (_) => _refreshPendingCount());
    _queueService.clearStuck().then((c) {
      if (c > 0) _refreshPendingCount();
    });
    Future.delayed(const Duration(seconds: 3), () => syncPending());
  }

  Future<void> refreshPendingCount() async {
    await _refreshPendingCount();
  }

  Future<void> syncPending() async {
    if (_currentStatus == SyncStatus.syncing) return;

    final isOnline = await _connectivityService.isConnected;
    if (!isOnline) return;

    _updateStatus(SyncStatus.syncing);

    try {
      final pending = await _queueService.getPending();
      if (pending.isEmpty) {
        _updateStatus(SyncStatus.idle);
        return;
      }

      final byTable = <String, List<SyncOperation>>{};
      for (final op in pending) {
        byTable.putIfAbsent(op.tabla, () => []).add(op);
      }

      for (final entry in byTable.entries) {
        final creates = entry.value.where((o) => o.operacion != 'liquidar').toList();
        final liquidaciones = entry.value.where((o) => o.operacion == 'liquidar').toList();
        if (creates.isNotEmpty) await _syncBatch(entry.key, 'create', creates);
        if (liquidaciones.isNotEmpty) await _syncBatch(entry.key, 'liquidar', liquidaciones);
      }

      await _refreshPendingCount();
      final remaining = await _queueService.getPendingCount();
      _updateStatus(remaining > 0 ? SyncStatus.error : SyncStatus.idle);
    } catch (e) {
      _updateStatus(SyncStatus.error);
    }
  }

  Future<void> _syncBatch(String tabla, String operacion, List<SyncOperation> operations) async {
    final endpoint = _getEndpoint(tabla, operacion);
    if (endpoint == null) return;

    final registros = operations.map((op) => {
      'uuid_local': op.uuidLocal,
      ...op.datos,
    }).toList();

    try {
      final response = await _dioClient.dio.post(
        endpoint,
        data: {'registros': registros},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final confirmados = data['confirmados'] as List<dynamic>? ?? [];

        for (final confirmado in confirmados) {
          final uuid = confirmado['uuid_local'] as String;
          final idRemoto = confirmado['id_remoto'] as int;
          await _queueService.markRecordSynced(tabla, uuid, idRemoto);
          final op = operations.firstWhere((o) => o.uuidLocal == uuid);
          if (op.id != null) await _queueService.delete(op.id!);
        }

        final rechazados = data['rechazados'] as List<dynamic>? ?? [];
        for (final rechazado in rechazados) {
          final uuid = rechazado['uuid_local'] as String;
          final op = operations.firstWhere((o) => o.uuidLocal == uuid);
          final currentIntentos = await _queueService.incrementAttempts(op.id!);
          if (currentIntentos >= 3) {
            await _queueService.delete(op.id!);
          }
        }
      }
    } catch (e) {
      for (final op in operations) {
        final currentIntentos = await _queueService.incrementAttempts(op.id!);
        if (currentIntentos >= 5) {
          await _queueService.delete(op.id!);
        }
      }
    }
  }

  String? _getEndpoint(String tabla, String operacion) {
    if (tabla == 'cosechas' && operacion == 'liquidar') {
      return ApiEndpoints.syncCosechasLiquidar;
    }
    switch (tabla) {
      case 'campanas':
        return ApiEndpoints.syncCampanas;
      case 'actividades':
        return ApiEndpoints.syncActividades;
      case 'transacciones':
        return ApiEndpoints.syncTransacciones;
      case 'cosechas':
        return ApiEndpoints.syncCosechas;
      default:
        return null;
    }
  }

  Future<void> pullRemoteChanges() async {
    final isOnline = await _connectivityService.isConnected;
    if (!isOnline) return;

    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.syncPull(DateTime.now().subtract(const Duration(days: 30))),
      );
      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _mergeRemoteData(data);
      }
    } catch (_) {}
  }

  Future<void> _mergeRemoteData(Map<String, dynamic> data) async {
    final db = await AppDatabase.database;

    final campanas = data['campanas'] as List<dynamic>? ?? [];
    for (final c in campanas) {
      await db.insert('campanas', {
        'id': c['id'],
        'user_id': c['user_id'] ?? 2,
        'nombre': c['nombre'],
        'cultivo': c['cultivo'],
        'extension': c['extension'],
        'tipo_extension': c['tipo_extension'],
        'latitud': c['latitud'],
        'longitud': c['longitud'],
        'estado': c['estado'],
        'fecha_inicio': c['fecha_inicio'],
        'fecha_cierre': c['fecha_cierre'],
        'created_at': c['created_at'] ?? DateTime.now().toIso8601String(),
        'is_synced': 1,
        'uuid_local': c['uuid_local'],
      });
    }

    final actividades = data['actividades'] as List<dynamic>? ?? [];
    for (final a in actividades) {
      await db.insert('actividades', {
        'id': a['id'],
        'campana_id': a['campana_id'],
        'descripcion': a['descripcion'],
        'fecha': a['fecha'],
        'created_at': a['created_at'] ?? DateTime.now().toIso8601String(),
        'is_synced': 1,
        'uuid_local': a['uuid_local'],
      });
    }

    final transacciones = data['transacciones'] as List<dynamic>? ?? [];
    for (final t in transacciones) {
      await db.insert('transacciones', {
        'id': t['id'],
        'campana_id': t['campana_id'],
        'tipo': t['tipo'],
        'categoria': t['categoria'],
        'monto': t['monto'],
        'descripcion': t['descripcion'],
        'fecha': t['fecha'],
        'estado_pago': t['estado_pago'],
        'created_at': t['created_at'] ?? DateTime.now().toIso8601String(),
        'is_synced': 1,
        'uuid_local': t['uuid_local'],
      });
    }

    final cosechas = data['cosechas_envios'] as List<dynamic>? ?? [];
    for (final c in cosechas) {
      await db.insert('cosechas', {
        'id': c['id'],
        'campana_id': c['campana_id'],
        'tipo_venta': c['tipo_venta'],
        'modo_cosecha': c['modo_cosecha'],
        'tipo_calculo_venta': c['tipo_calculo_venta'],
        'unidad_empaque': c['unidad_empaque'],
        'total_bultos': c['total_bultos'],
        'peso_total_kg': c['peso_total_kg'],
        'cantidad_unidades': c['cantidad_unidades'],
        'conductor': c['conductor'],
        'mercado_destino': c['mercado_destino'],
        'estado': c['estado'],
        'precio_unitario': c['precio_unitario'],
        'descuentos_logistica': c['descuentos_logistica'],
        'monto_neto_final': c['monto_neto_final'],
        'fecha_envio': c['fecha_envio'],
        'fecha_liquidacion': c['fecha_liquidacion'],
        'created_at': c['created_at'] ?? DateTime.now().toIso8601String(),
        'is_synced': 1,
        'uuid_local': c['uuid_local'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final detalles = data['cosecha_envio_detalles'] as List<dynamic>? ?? [];
    for (final d in detalles) {
      await db.insert('cosecha_detalles', {
        'id': d['id'],
        'cosecha_id': d['cosecha_envio_id'],
        'categoria': d['categoria'],
        'simbolo': d['simbolo'],
        'posicion_fila': d['posicion_fila'],
        'cantidad_bultos': d['cantidad_bultos'] ?? 0,
        'peso_promedio_bulto_kg': d['peso_promedio_bulto_kg'],
        'peso_kg': d['peso_kg'],
        'precio_venta': d['precio_venta'],
        'monto_parcial': d['monto_parcial'],
        'created_at': DateTime.now().toIso8601String(),
        'is_synced': 1,
        'uuid_local': d['uuid_local'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  Future<void> _refreshPendingCount() async {
    final count = await _queueService.getPendingCount();
    _pendingCountController.add(count);
  }

  void dispose() {
    _periodicRefresh?.cancel();
    _connectivitySubscription?.cancel();
    _statusController.close();
    _pendingCountController.close();
  }
}
