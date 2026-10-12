import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final UserModel user;
  final String token;
  final String tokenType;
  final String message;

  const AuthResponseModel({
    required this.success,
    required this.user,
    required this.token,
    required this.tokenType,
    required this.message,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthResponseModel(
      success: json['success'] as bool? ?? false,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String? ?? '',
      tokenType: data['token_type'] as String? ?? 'Bearer',
      message: json['message'] as String? ?? '',
    );
  }
}
