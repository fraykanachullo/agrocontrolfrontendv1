import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/dio_client.dart';
import '../network/connectivity_service.dart';
import '../errors/exceptions.dart';
import '../sync/sync_queue_service.dart';
import '../sync/sync_manager.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/campanas/data/datasources/campana_remote_datasource.dart';
import '../../features/campanas/data/datasources/campana_local_datasource.dart';
import '../../features/campanas/data/repositories/campana_repository_impl.dart';
import '../../features/campanas/domain/entities/campana.dart';
import '../../features/campanas/domain/repositories/campana_repository.dart';
import '../../features/cuaderno/domain/entities/actividad.dart';
import '../../features/cuaderno/domain/entities/transaccion.dart';
import '../../features/cosechas/domain/entities/cosecha.dart';
import '../../features/cosechas/domain/entities/cosecha_clase.dart';
import '../../features/cosechas/domain/entities/cosecha_detalle.dart';
import '../../features/planillas/domain/entities/planilla.dart';
import '../../features/planillas/data/datasources/planilla_local_datasource.dart';

String mapError(dynamic error) {
  if (error is DioException) {
    final inner = error.error;
    if (inner is ServerException) return inner.message;
    return error.message ?? 'Error de conexión';
  }
  if (error is ServerException) return error.message;
  if (error is Exception) return error.toString().replaceAll('Exception: ', '');
  return 'Error inesperado: $error';
}

// ── Infrastructure Providers ──

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(secureStorage: ref.watch(secureStorageProvider));
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
});

// ── Auth Providers ──

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.watch(dioClientProvider));
});

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  return AuthLocalDatasource(ref.watch(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDatasourceProvider),
    ref.watch(authLocalDatasourceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final checkAuthUseCaseProvider = Provider<CheckAuthUseCase>((ref) {
  return CheckAuthUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  return ForgotPasswordUseCase(ref.watch(authRepositoryProvider));
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.watch(authRepositoryProvider));
});

// ── Auth State ──

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  factory AuthState.initial() => const AuthState();
  factory AuthState.loading() => const AuthState(isLoading: true);
  factory AuthState.authenticated(User user) =>
      AuthState(isAuthenticated: true, user: user);
  factory AuthState.unauthenticated() => const AuthState();
  factory AuthState.error(String message) => AuthState(error: message);
}

// ── Auth Notifier ──

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckAuthUseCase _checkAuthUseCase;
  final RegisterUseCase _registerUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  AuthNotifier(
    this._loginUseCase,
    this._logoutUseCase,
    this._checkAuthUseCase,
    this._registerUseCase,
    this._forgotPasswordUseCase,
    this._resetPasswordUseCase,
  ) : super(AuthState.initial());

  Future<void> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await _loginUseCase(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(mapError(e));
    }
  }

  Future<bool> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();
    try {
      final user = await _registerUseCase(
        nombre: nombre,
        email: email,
        password: password,
      );
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error(mapError(e));
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _forgotPasswordUseCase(email);
      return true;
    } catch (e) {
      state = AuthState.error(mapError(e));
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    try {
      await _resetPasswordUseCase(
        email: email,
        token: token,
        password: password,
      );
      return true;
    } catch (e) {
      state = AuthState.error(mapError(e));
      return false;
    }
  }

  Future<void> checkAuth() async {
    state = AuthState.loading();
    try {
      final user = await _checkAuthUseCase();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> logout() async {
    await _logoutUseCase();
    state = AuthState.unauthenticated();
  }

  void clearError() {
    if (state.error != null) {
      state = AuthState(
        isLoading: state.isLoading,
        isAuthenticated: state.isAuthenticated,
        user: state.user,
      );
    }
  }
}

// ── Provider ──

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(loginUseCaseProvider),
    ref.watch(logoutUseCaseProvider),
    ref.watch(checkAuthUseCaseProvider),
    ref.watch(registerUseCaseProvider),
    ref.watch(forgotPasswordUseCaseProvider),
    ref.watch(resetPasswordUseCaseProvider),
  );
});

// ── Campana Providers ──

final campanaRemoteDatasourceProvider = Provider<CampanaRemoteDatasource>((
  ref,
) {
  return CampanaRemoteDatasource(ref.watch(dioClientProvider));
});

final campanaLocalDatasourceProvider = Provider<CampanaLocalDatasource>((ref) {
  return CampanaLocalDatasource();
});

final planillaLocalDatasourceProvider = Provider<PlanillaLocalDatasource>((
  ref,
) {
  return PlanillaLocalDatasource();
});

final campanaRepositoryProvider = Provider<CampanaRepository>((ref) {
  return CampanaRepositoryImpl(
    ref.watch(campanaRemoteDatasourceProvider),
    ref.watch(campanaLocalDatasourceProvider),
    ref.watch(syncQueueServiceProvider),
  );
});

class CampanaListState {
  final bool isLoading;
  final List<Campana> campanas;
  final String? error;

  const CampanaListState({
    this.isLoading = false,
    this.campanas = const [],
    this.error,
  });

  factory CampanaListState.initial() => const CampanaListState();
  factory CampanaListState.loading() => const CampanaListState(isLoading: true);
  factory CampanaListState.loaded(List<Campana> campanas) =>
      CampanaListState(campanas: campanas);
  factory CampanaListState.error(String message) =>
      CampanaListState(error: message);
}

class CampanaListNotifier extends StateNotifier<CampanaListState> {
  final CampanaRepository _repository;

  CampanaListNotifier(this._repository) : super(CampanaListState.initial());

  Future<void> loadCampanas() async {
    state = CampanaListState.loading();
    try {
      final campanas = await _repository.listCampanas();
      state = CampanaListState.loaded(campanas);
    } catch (e) {
      state = CampanaListState.error(mapError(e));
    }
  }

  Future<Campana?> createCampana({
    required String nombre,
    required String cultivo,
    required double extension,
    required String tipoExtension,
    required DateTime fechaInicio,
    double? latitud,
    double? longitud,
  }) async {
    try {
      final campana = await _repository.createCampana(
        nombre: nombre,
        cultivo: cultivo,
        extension: extension,
        tipoExtension: tipoExtension,
        fechaInicio: fechaInicio,
        latitud: latitud,
        longitud: longitud,
      );
      state = CampanaListState.loaded([...state.campanas, campana]);
      return campana;
    } catch (e) {
      state = CampanaListState.error(mapError(e));
      return null;
    }
  }
}

final campanaListProvider =
    StateNotifierProvider<CampanaListNotifier, CampanaListState>((ref) {
      return CampanaListNotifier(ref.watch(campanaRepositoryProvider));
    });

/// ID de la campaña activa seleccionada por el usuario
final activeCampanaIdProvider = StateProvider<int?>((ref) => null);

/// Campaña activa derivada del ID seleccionado
final activeCampanaProvider = Provider<Campana?>((ref) {
  final id = ref.watch(activeCampanaIdProvider);
  final listState = ref.watch(campanaListProvider);
  if (id == null || listState.campanas.isEmpty) return null;
  try {
    return listState.campanas.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});

/// Trigger para forzar refresh del dashboard después de mutaciones
final dashboardRefreshTrigger = StateProvider<int>((ref) => 0);

// ── Dashboard Provider ──

final dashboardDataProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  ref.watch(dashboardRefreshTrigger);
  final campanaId = ref.watch(activeCampanaIdProvider);
  if (campanaId == null) return null;
  final localDs = ref.watch(campanaLocalDatasourceProvider);
  return await localDs.getDashboardData(campanaId);
});

final gastosPorCategoriaProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  ref.watch(dashboardRefreshTrigger);
  final campanaId = ref.watch(activeCampanaIdProvider);
  if (campanaId == null) return [];
  final localDs = ref.watch(campanaLocalDatasourceProvider);
  return await localDs.getGastosPorCategoria(campanaId);
});

/// Balance de una campaña para listados (selector de campañas).
class CampanaResumen {
  final double gastos;
  final double ingresos;
  final int cosechas;
  final int porLiquidar;

  const CampanaResumen({required this.gastos, required this.ingresos, required this.cosechas, required this.porLiquidar});

  double get utilidad => ingresos - gastos;
  double? get rentabilidad => gastos > 0 ? utilidad / gastos * 100 : null;
}

final campanaResumenesProvider = FutureProvider<Map<int, CampanaResumen>>((ref) async {
  ref.watch(dashboardRefreshTrigger);
  ref.watch(campanaListProvider);
  final rows = await ref.read(campanaLocalDatasourceProvider).getResumenCampanas();
  return {
    for (final r in rows)
      r['campana_id'] as int: CampanaResumen(
        gastos: (r['gastos'] as num).toDouble(),
        ingresos: (r['ingresos_directos'] as num).toDouble() + (r['ventas'] as num).toDouble(),
        cosechas: r['cosechas'] as int,
        porLiquidar: r['por_liquidar'] as int,
      ),
  };
});

final gastosPorEtapaProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dashboardRefreshTrigger);
  final campanaId = ref.watch(activeCampanaIdProvider);
  if (campanaId == null) return [];
  return ref.watch(campanaLocalDatasourceProvider).getGastosPorEtapa(campanaId);
});

// ── Cuaderno Providers (Actividades + Transacciones) ──

class CuadernoState {
  final bool isLoading;
  final List<dynamic> actividades;
  final List<dynamic> transaccionesGasto;
  final List<dynamic> transaccionesIngreso;
  final String? error;

  const CuadernoState({
    this.isLoading = false,
    this.actividades = const [],
    this.transaccionesGasto = const [],
    this.transaccionesIngreso = const [],
    this.error,
  });
}

class CuadernoNotifier extends StateNotifier<CuadernoState> {
  final CampanaLocalDatasource _localDatasource;
  final SyncQueueService _syncQueue;

  CuadernoNotifier(this._localDatasource, this._syncQueue)
    : super(const CuadernoState());

  Future<void> loadData(int campanaId) async {
    state = const CuadernoState(isLoading: true);
    try {
      final actividades = await _localDatasource.listActividades(campanaId);
      final transacciones = await _localDatasource.listTransacciones(campanaId);
      state = CuadernoState(
        actividades: actividades.map((m) => Actividad.fromMap(m)).toList(),
        transaccionesGasto: transacciones
            .where((m) => m['tipo'] == 'gasto')
            .map((m) => Transaccion.fromMap(m))
            .toList(),
        transaccionesIngreso: transacciones
            .where((m) => m['tipo'] == 'ingreso')
            .map((m) => Transaccion.fromMap(m))
            .toList(),
      );
    } catch (e) {
      state = CuadernoState(error: mapError(e));
    }
  }

  Future<int> addActividad(
    int campanaId,
    String descripcion,
    String fecha,
  ) async {
    final uuidLocal = SyncQueueService.generateUuid();
    final id = await _localDatasource.insertActividad({
      'campana_id': campanaId,
      'descripcion': descripcion,
      'fecha': fecha,
      'created_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
      'uuid_local': uuidLocal,
    });
    await _syncQueue.enqueue(
      tabla: 'actividades',
      operacion: 'create',
      datos: {
        'campana_id': campanaId,
        'descripcion': descripcion,
        'fecha': fecha,
      },
    );
    await loadData(campanaId);
    return id;
  }

  Future<int> addTransaccion(
    int campanaId, {
    required String tipo,
    required String categoria,
    required double monto,
    required String descripcion,
    required String fecha,
    String estadoPago = 'pendiente',
    String? etapa,
  }) async {
    final uuidLocal = SyncQueueService.generateUuid();
    final id = await _localDatasource.insertTransaccion({
      'campana_id': campanaId,
      'tipo': tipo,
      'categoria': categoria,
      'monto': monto,
      'descripcion': descripcion,
      'fecha': fecha,
      'estado_pago': estadoPago,
      'etapa': etapa,
      'created_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
      'uuid_local': uuidLocal,
    });
    await _syncQueue.enqueue(
      tabla: 'transacciones',
      operacion: 'create',
      datos: {
        'campana_id': campanaId,
        'tipo': tipo,
        'categoria': categoria,
        'monto': monto,
        'descripcion': descripcion,
        'fecha': fecha,
        'estado_pago': estadoPago,
        'etapa': etapa,
      },
    );
    await loadData(campanaId);
    return id;
  }
}

final cuadernoProvider = StateNotifierProvider<CuadernoNotifier, CuadernoState>(
  (ref) {
    return CuadernoNotifier(
      ref.watch(campanaLocalDatasourceProvider),
      ref.watch(syncQueueServiceProvider),
    );
  },
);

// ── Cosechas Provider ──

class CosechasState {
  final bool isLoading;
  final List<Cosecha> pendientes;
  final List<Cosecha> entregadas;
  final String? error;

  const CosechasState({
    this.isLoading = false,
    this.pendientes = const [],
    this.entregadas = const [],
    this.error,
  });
}

class CosechasNotifier extends StateNotifier<CosechasState> {
  final CampanaLocalDatasource _localDatasource;
  final SyncQueueService _syncQueue;

  CosechasNotifier(this._localDatasource, this._syncQueue)
    : super(const CosechasState());

  Future<void> loadData(int campanaId) async {
    state = const CosechasState(isLoading: true);
    try {
      final maps = await _localDatasource.listCosechas(campanaId);
      final all = <Cosecha>[];
      for (final m in maps) {
        final cosecha = Cosecha.fromMap(m);
        if (cosecha.id != null) {
          final clasesMaps = await _localDatasource.listCosechaClases(
            cosecha.id!,
          );
          final clases = clasesMaps
              .map((cm) => CosechaClase.fromMap(cm))
              .toList();
          final detallesMaps = await _localDatasource.listCosechaDetalles(
            cosecha.id!,
          );
          final detalles = detallesMaps
              .map((dm) => CosechaDetalle.fromMap(dm))
              .toList();
          all.add(
            Cosecha(
              id: cosecha.id,
              campanaId: cosecha.campanaId,
              tipoVenta: cosecha.tipoVenta,
              modoCosecha: cosecha.modoCosecha,
              tipoCalculoVenta: cosecha.tipoCalculoVenta,
              unidadEmpaque: cosecha.unidadEmpaque,
              totalBultos: cosecha.totalBultos,
              pesoTotalKg: cosecha.pesoTotalKg,
              cantidadUnidades: cosecha.cantidadUnidades,
              conductor: cosecha.conductor,
              mercadoDestino: cosecha.mercadoDestino,
              estado: cosecha.estado,
              precioUnitario: cosecha.precioUnitario,
              descuentosLogistica: cosecha.descuentosLogistica,
              montoNetoFinal: cosecha.montoNetoFinal,
              fechaEnvio: cosecha.fechaEnvio,
              fechaLiquidacion: cosecha.fechaLiquidacion,
              liquidacion: cosecha.liquidacion,
              createdAt: cosecha.createdAt,
              isSynced: cosecha.isSynced,
              clases: clases,
              detalles: detalles,
            ),
          );
        } else {
          all.add(cosecha);
        }
      }
      state = CosechasState(
        pendientes: all
            .where(
              (c) =>
                  c.estado == 'pendiente' ||
                  c.estado == 'pendiente_de_liquidacion',
            )
            .toList(),
        entregadas: all
            .where(
              (c) =>
                  c.estado != 'pendiente' &&
                  c.estado != 'pendiente_de_liquidacion',
            )
            .toList(),
      );
    } catch (e) {
      state = CosechasState(error: mapError(e));
    }
  }

  /// Registra una venta o despacho y devuelve su id local.
  Future<int> addCosecha(
    int campanaId, {
    required String tipoVenta,
    required int cantidadUnidades,
    required String conductor,
    required String mercadoDestino,
    required String fechaEnvio,
    String? modoCosecha,
    String? tipoCalculoVenta,
    String? unidadEmpaque,
    int? totalBultos,
    double? pesoTotalKg,
    List<Map<String, dynamic>> detalles = const [],
  }) async {
    final uuidLocal = SyncQueueService.generateUuid();
    final now = DateTime.now().toIso8601String();

    final id = await _localDatasource.insertCosecha({
      'campana_id': campanaId,
      'tipo_venta': tipoVenta,
      'modo_cosecha': modoCosecha,
      'tipo_calculo_venta': tipoCalculoVenta,
      'unidad_empaque': unidadEmpaque,
      'total_bultos': totalBultos,
      'peso_total_kg': pesoTotalKg,
      'cantidad_unidades': cantidadUnidades,
      'conductor': conductor,
      'mercado_destino': mercadoDestino,
      'estado': 'pendiente',
      'fecha_envio': fechaEnvio,
      'created_at': now,
      'is_synced': 0,
      'uuid_local': uuidLocal,
    });

    final detallesSync = <Map<String, dynamic>>[];
    for (final d in detalles) {
      final detUuid = SyncQueueService.generateUuid();
      await _localDatasource.insertCosechaDetalle({
        'cosecha_id': id,
        'categoria': d['categoria'],
        'simbolo': d['simbolo'],
        'posicion_fila': d['posicion_fila'],
        'cantidad_bultos': d['cantidad_bultos'] ?? 0,
        'peso_promedio_bulto_kg': d['peso_promedio_bulto_kg'],
        'peso_kg': d['peso_kg'],
        'created_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
        'uuid_local': detUuid,
      });
      detallesSync.add({
        'categoria': d['categoria'],
        'simbolo': d['simbolo'],
        'posicion_fila': d['posicion_fila'],
        'cantidad_bultos': d['cantidad_bultos'] ?? 0,
        'peso_promedio_bulto_kg': d['peso_promedio_bulto_kg'],
        'peso_kg': d['peso_kg'],
        'uuid_local': detUuid,
      });
    }

    await _syncQueue.enqueue(
      tabla: 'cosechas',
      operacion: 'create',
      datos: {
        'campana_id': campanaId,
        'tipo_venta': tipoVenta,
        'modo_cosecha': modoCosecha,
        'tipo_calculo_venta': tipoCalculoVenta,
        'unidad_empaque': unidadEmpaque,
        'total_bultos': totalBultos,
        'peso_total_kg': pesoTotalKg,
        'cantidad_unidades': cantidadUnidades,
        'conductor': conductor,
        'mercado_destino': mercadoDestino,
        'fecha_envio': fechaEnvio,
        'detalles': detallesSync,
      },
    );
    await loadData(campanaId);
    return id;
  }

  Future<void> liquidarCosecha(
    int campanaId,
    int cosechaId, {
    required List<Map<String, dynamic>> detallesPrecios,
    required double descuentosLogistica,
    double? precioUnitarioGlobal,
    /// Bultos realmente vendidos por categoría (si hubo merma). Sin dato = todo lo anotado.
    Map<String, int> vendidos = const {},
    /// Detalle de la liquidación que se guarda tal cual (descuentos, forma de cobro, comprobante).
    Map<String, dynamic>? detalle,
  }) async {
    final maps = await _localDatasource.listCosechas(campanaId);
    final cosechaMap = maps.firstWhere(
      (m) => m['id'] == cosechaId,
      orElse: () => <String, dynamic>{},
    );
    final cosechaUuid = cosechaMap['uuid_local'] as String?;
    final tipoCalculo =
        cosechaMap['tipo_calculo_venta'] as String? ?? 'por_kilo';

    final detMaps = await _localDatasource.listCosechaDetalles(cosechaId);
    final detalles = detMaps.map((d) => CosechaDetalle.fromMap(d)).toList();

    double totalBruto = 0;
    final liquidacionSync = <Map<String, dynamic>>[];
    final anotados = <String, int>{};
    for (final d in detalles) {
      final cat = d.categoria;
      if (cat != null) anotados[cat] = (anotados[cat] ?? 0) + d.cantidadBultos;
    }

    for (final d in detalles) {
      double? precio;
      for (final dp in detallesPrecios) {
        if (d.categoria != null && dp['categoria'] == d.categoria) {
          precio = (dp['precio_venta'] as num?)?.toDouble();
          break;
        }
      }
      if (precio == null && precioUnitarioGlobal != null) {
        precio = precioUnitarioGlobal;
      }
      if (precio == null || precio <= 0 || d.id == null) continue;

      // Con merma, el monto de la calidad se reparte entre sus filas en proporción.
      final anotado = anotados[d.categoria] ?? 0;
      final vendido = vendidos[d.categoria];
      final factor = (vendido != null && anotado > 0) ? vendido / anotado : 1.0;
      final monto = d.montoUnidad(tipoCalculo, precio) * factor;
      totalBruto += monto;

      await _localDatasource.updateCosechaDetalle(d.id!, {
        'precio_venta': precio,
        'monto_parcial': monto,
        'is_synced': 0,
      });
      liquidacionSync.add({'categoria': d.categoria, 'precio_venta': precio});
    }

    // Ruta legacy sin detalles: precio global × peso total o cantidad
    if (detalles.isEmpty) {
      // Sin detalle por calidad, la clave '*' trae los bultos vendidos de toda la carga.
      final base = vendidos['*']?.toDouble() ??
          (cosechaMap['peso_total_kg'] as num?)?.toDouble() ??
          (cosechaMap['cantidad_unidades'] as num?)?.toDouble() ??
          0;
      totalBruto = base * (precioUnitarioGlobal ?? 0);
    }

    final montoNeto = totalBruto - descuentosLogistica;

    await _localDatasource.updateCosecha(cosechaId, {
      'estado': 'entregado',
      'precio_unitario': precioUnitarioGlobal,
      'descuentos_logistica': descuentosLogistica,
      'monto_neto_final': montoNeto,
      'fecha_liquidacion': DateTime.now().toIso8601String(),
      'liquidacion_json': detalle == null ? null : jsonEncode(detalle),
      'is_synced': 0,
    });

    await _syncQueue.enqueue(
      tabla: 'cosechas',
      operacion: 'liquidar',
      datos: {
        'cosecha_uuid': cosechaUuid,
        'precio_unitario': precioUnitarioGlobal,
        'descuentos_logistica': descuentosLogistica,
        'fecha_liquidacion': DateTime.now().toIso8601String(),
        'detalles': liquidacionSync,
      },
    );
    await loadData(campanaId);
  }
}

final cosechasProvider = StateNotifierProvider<CosechasNotifier, CosechasState>(
  (ref) {
    return CosechasNotifier(
      ref.watch(campanaLocalDatasourceProvider),
      ref.watch(syncQueueServiceProvider),
    );
  },
);

// ── Planillas Provider ──

class PlanillasState {
  final bool isLoading;
  final List<Planilla> planillas;
  final String? error;

  const PlanillasState({
    this.isLoading = false,
    this.planillas = const [],
    this.error,
  });
}

class PlanillasNotifier extends StateNotifier<PlanillasState> {
  final PlanillaLocalDatasource _localDatasource;

  PlanillasNotifier(this._localDatasource) : super(const PlanillasState());

  Future<void> loadData(int campanaId) async {
    state = const PlanillasState(isLoading: true);
    try {
      final maps = await _localDatasource.listPlanillas(campanaId);
      final all = maps.map((m) => Planilla.fromMap(m)).toList();
      state = PlanillasState(planillas: all);
    } catch (e) {
      state = PlanillasState(error: e.toString());
    }
  }

  Future<Planilla> addPlanilla(Planilla planilla) async {
    final id = await _localDatasource.insertPlanilla(planilla.toMap());
    final saved = planilla.copyWith(id: id);
    state = PlanillasState(
      planillas: [saved, ...state.planillas.where((p) => p.id != id)],
    );
    return saved;
  }

  Future<void> updatePlanilla(Planilla planilla) async {
    if (planilla.id == null) return;
    final now = DateTime.now().toIso8601String();
    final updated = planilla.copyWith(updatedAt: now);
    await _localDatasource.updatePlanilla(updated.id!, updated.toMap());
    state = PlanillasState(
      planillas: state.planillas
          .map((p) => p.id == updated.id ? updated : p)
          .toList(),
    );
  }

  Future<void> deletePlanilla(int id) async {
    await _localDatasource.deletePlanilla(id);
    state = PlanillasState(
      planillas: state.planillas.where((p) => p.id != id).toList(),
    );
  }
}

final planillasProvider =
    StateNotifierProvider<PlanillasNotifier, PlanillasState>((ref) {
      return PlanillasNotifier(ref.watch(planillaLocalDatasourceProvider));
    });

// ── Historial Provider ──

class HistorialEntry {
  final String tipo;
  final String titulo;
  final String descripcion;
  final String hora;
  final double? monto;
  final bool isSynced;

  const HistorialEntry({
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.hora,
    this.monto,
    this.isSynced = false,
  });
}

final historialDayProvider = FutureProvider.family<List<HistorialEntry>, (int, DateTime)>((
  ref,
  params,
) async {
  ref.watch(dashboardRefreshTrigger);
  final campanaId = params.$1;
  final date = params.$2;
  final localDs = ref.read(campanaLocalDatasourceProvider);
  final dateStr =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  final actividades = await localDs.listActividadesForDay(campanaId, dateStr);
  final transacciones = await localDs.listTransaccionesForDay(
    campanaId,
    dateStr,
  );
  final cosechas = await localDs.listCosechasForDay(campanaId, dateStr);

  final cosechaIds = cosechas.map((c) => c['id'] as int).toList();
  final allClases = await localDs.listCosechaClasesForIds(cosechaIds);
  final clasesByCosecha = <int, List<Map<String, dynamic>>>{};
  for (final cl in allClases) {
    final cid = cl['cosecha_id'] as int;
    clasesByCosecha.putIfAbsent(cid, () => []).add(cl);
  }

  final entries = <HistorialEntry>[];

  for (final a in actividades) {
    final fecha = (a['fecha'] as String?) ?? '';
    final time = fecha.contains('T')
        ? fecha.split('T')[1].substring(0, 5)
        : '--:--';
    final descripcion = a['descripcion'] as String? ?? '';
    final isIncident = descripcion.startsWith(kIncidentPrefix);
    final detalle = isIncident ? descripcion.substring(kIncidentPrefix.length) : descripcion;
    final partes = detalle.split(' · ');
    entries.add(
      HistorialEntry(
        tipo: isIncident ? 'incidencia' : 'actividad',
        titulo: isIncident ? 'Incidencia: ${partes.first}' : partes.first,
        descripcion: partes.skip(1).join(' · '),
        hora: time,
        isSynced: (a['is_synced'] as int? ?? 0) == 1,
      ),
    );
  }

  for (final t in transacciones) {
    final fecha = (t['fecha'] as String?) ?? '';
    final time = fecha.contains('T')
        ? fecha.split('T')[1].substring(0, 5)
        : '--:--';
    final tipo = t['tipo'] as String? ?? 'gasto';
    entries.add(
      HistorialEntry(
        tipo: tipo,
        titulo: (t['categoria'] as String?)?.isNotEmpty == true
            ? t['categoria'] as String
            : (tipo == 'gasto' ? 'Gasto' : 'Ingreso'),
        descripcion: t['descripcion'] as String? ?? '',
        hora: time,
        monto: (t['monto'] as num?)?.toDouble(),
        isSynced: (t['is_synced'] as int? ?? 0) == 1,
      ),
    );
  }

  for (final c in cosechas) {
    final fecha = (c['fecha_envio'] as String?) ?? '';
    final fechaLiq = (c['fecha_liquidacion'] as String?) ?? '';
    final cosechaId = c['id'] as int?;
    final isKilo = (c['tipo_venta'] as String?) != 'por_unidad';
    final clasesMaps = cosechaId != null
        ? (clasesByCosecha[cosechaId] ?? [])
        : <Map<String, dynamic>>[];
    final claseResumen = clasesMaps
        .map((cl) {
          final nombre = cl['clase'] as String? ?? '';
          final cant = (cl['cantidad'] as num?)?.toDouble() ?? 0;
          final precio = (cl['precio_unitario'] as num?)?.toDouble() ?? 0;
          final peso = (cl['peso_kg'] as num?)?.toDouble();
          if (peso != null && peso > 0) {
            return '$nombre: ${cant.toInt()} sacos × ${peso.toStringAsFixed(1)}kg × S/${precio.toStringAsFixed(2)}';
          }
          return '$nombre: ${cant.toInt()} × S/${precio.toStringAsFixed(2)}';
        })
        .join(', ');

    if (fecha.startsWith(dateStr)) {
      final time = fecha.contains('T')
          ? fecha.split('T')[1].substring(0, 5)
          : '--:--';
      final montoNeto = (c['monto_neto_final'] as num?)?.toDouble();
      final desc = claseResumen.isNotEmpty
          ? claseResumen
          : 'Destino: ${c['mercado_destino'] ?? ''}';
      entries.add(
        HistorialEntry(
          tipo: 'cosecha',
          titulo:
              'Envío: ${c['cantidad_unidades']} ${isKilo ? "sacos" : "javas"}',
          descripcion: desc,
          hora: time,
          monto: montoNeto,
          isSynced: (c['is_synced'] as int? ?? 0) == 1,
        ),
      );
    }
    if (fechaLiq.startsWith(dateStr) && !fecha.startsWith(dateStr)) {
      final time = fechaLiq.contains('T')
          ? fechaLiq.split('T')[1].substring(0, 5)
          : '--:--';
      final montoNeto = (c['monto_neto_final'] as num?)?.toDouble();
      final desc = claseResumen.isNotEmpty
          ? '$claseResumen → ${c['mercado_destino'] ?? ''}'
          : '${c['cantidad_unidades']} ${isKilo ? "sacos" : "javas"} → ${c['mercado_destino'] ?? ''}';
      entries.add(
        HistorialEntry(
          tipo: 'cosecha',
          titulo: 'Liquidación #${c['id'] ?? ""}',
          descripcion: desc,
          hora: time,
          monto: montoNeto,
          isSynced: (c['is_synced'] as int? ?? 0) == 1,
        ),
      );
    }
  }

  entries.sort((a, b) => b.hora.compareTo(a.hora));
  return entries;
});

// ── Sync Providers ──

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  return SyncQueueService();
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(
    ref.watch(syncQueueServiceProvider),
    ref.watch(dioClientProvider),
    ref.watch(connectivityServiceProvider),
  );
  manager.init();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final syncPendingCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncManagerProvider).pendingCountStream;
});
