import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final AuthLocalDatasource _local;

  AuthRepositoryImpl(this._remote, this._local);

  @override
  Future<User> login(String email, String password) async {
    // Try online first
    try {
      final response = await _remote.login(email, password);
      await _local.saveToken(response.token);
      await _local.saveUser(response.user);
      await _local.saveUserToDb(response.user, password: password);
      return response.user;
    } catch (_) {
      // Fallback to offline login
      final user = await _local.loginOffline(email, password);
      if (user != null) {
        await _local.saveUser(user);
        return user;
      }
      rethrow;
    }
  }

  @override
  Future<User> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remote.register(
        nombre: nombre,
        email: email,
        password: password,
        passwordConfirmation: password,
      );
      await _local.saveToken(response.token);
      await _local.saveUser(response.user);
      await _local.saveUserToDb(response.user, password: password);
      return response.user;
    } catch (_) {
      // Offline: create locally
      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombreCompleto: nombre,
        email: email,
        planSuscripcion: 'gratuito',
        tenantId: 1,
      );
      await _local.saveUserToDb(user, password: password);
      await _local.saveUser(user);
      return user;
    }
  }

  @override
  Future<User> getCurrentUser() async {
    try {
      return await _remote.getCurrentUser();
    } catch (_) {
      final cached = await _local.getCachedUser();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Ignore logout errors — clear local data anyway
    }
    await _local.clearAll();
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _remote.forgotPassword(email);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    await _remote.resetPassword(
      email: email,
      token: token,
      password: password,
      passwordConfirmation: password,
    );
  }

  @override
  Future<String?> getToken() async {
    return await _local.getToken();
  }

  @override
  Future<User?> getCachedUser() async {
    return await _local.getCachedUser();
  }

  @override
  Future<void> clearAuth() async {
    await _local.clearAll();
  }
}
