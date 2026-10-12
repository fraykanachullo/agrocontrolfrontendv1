import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../network/connectivity_service.dart';
import '../network/dio_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Core ──
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  sl.registerLazySingleton<DioClient>(
    () => DioClient(secureStorage: sl()),
  );

  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(),
  );

  // ── Repositories (Phase 2) ──
  // sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
  //   dioClient: sl(),
  //   secureStorage: sl(),
  // ));

  // ── Services (Phase 2) ──
  // sl.registerLazySingleton<AuthService>(() => AuthService(
  //   authRepository: sl(),
  // ));
}

/// Reset all registrations (for testing)
Future<void> reset() async {
  await sl.reset();
}
