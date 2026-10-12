import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register({
    required String nombre,
    required String email,
    required String password,
  });
  Future<User> getCurrentUser();
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  });
  Future<String?> getToken();
  Future<User?> getCachedUser();
  Future<void> clearAuth();
}
