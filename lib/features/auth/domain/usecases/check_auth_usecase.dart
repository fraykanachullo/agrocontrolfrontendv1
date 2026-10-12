import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CheckAuthUseCase {
  final AuthRepository _repository;

  CheckAuthUseCase(this._repository);

  /// Returns the cached user if a token exists, or null if not authenticated.
  Future<User?> call() async {
    final token = await _repository.getToken();
    if (token == null) return null;
    return await _repository.getCachedUser();
  }
}
