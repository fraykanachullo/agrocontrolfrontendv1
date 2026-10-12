import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  Future<void> call({
    required String email,
    required String token,
    required String password,
  }) {
    return _repository.resetPassword(
      email: email,
      token: token,
      password: password,
    );
  }
}