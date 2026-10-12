import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final DioClient _dioClient;

  AuthRemoteDatasource(this._dioClient);

  Future<AuthResponseModel> login(String email, String password) async {
    final response = await _dioClient.post(
      ApiEndpoints.login,
      data: {
        'correo_electronico': email,
        'password': password,
      },
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponseModel> register({
    required String nombre,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.register,
      data: {
        'nombre_completo': nombre,
        'correo_electronico': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _dioClient.get(ApiEndpoints.me);
    return UserModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _dioClient.post(ApiEndpoints.logout);
  }

  Future<void> forgotPassword(String email) async {
    await _dioClient.post(
      ApiEndpoints.forgotPassword,
      data: {'correo_electronico': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _dioClient.post(
      ApiEndpoints.resetPassword,
      data: {
        'correo_electronico': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }
}
