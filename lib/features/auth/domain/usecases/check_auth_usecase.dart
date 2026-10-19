import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CheckAuthUseCase {
  final AuthRepository _repository;

  CheckAuthUseCase(this._repository);

  /// La sesión sigue abierta mientras haya un usuario guardado en el
  /// teléfono, tenga o no token del servidor: si se entró sin señal no hay
  /// token, y la app debe seguir funcionando offline (ERS 4.3). El token solo
  /// hace falta para sincronizar.
  Future<User?> call() => _repository.getCachedUser();
}
