import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository _repository;

  ForgotPasswordUseCase(this._repository);

  Future<void> call(String email) {
    return _repository.forgotPassword(email);
  }
}