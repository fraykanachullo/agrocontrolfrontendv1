import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<User> call({
    required String nombre,
    required String email,
    required String password,
  }) {
    return _repository.register(
      nombre: nombre,
      email: email,
      password: password,
    );
  }
}