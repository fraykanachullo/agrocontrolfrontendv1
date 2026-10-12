import 'package:freezed_annotation/freezed_annotation.dart';

part 'exceptions.freezed.dart';

// ── Base Exception ──
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => '[$runtimeType] $message (Status: $statusCode)';
}

// ── Server Exception ──
@freezed
class ServerException extends AppException with _$ServerException {
  const factory ServerException({
    required String message,
    int? statusCode,
  }) = _ServerException;
}

// ── Cache Exception ──
@freezed
class CacheException extends AppException with _$CacheException {
  const factory CacheException({
    @Default('Error al acceder a los datos locales.') String message,
    int? statusCode,
  }) = _CacheException;
}

// ── Network Exception ──
@freezed
class NetworkException extends AppException with _$NetworkException {
  const factory NetworkException({
    @Default('Sin conexión a internet.') String message,
    int? statusCode,
  }) = _NetworkException;
}

// ── Auth Exception ──
@freezed
class AuthException extends AppException with _$AuthException {
  const factory AuthException({
    @Default('Sesión expirada. Inicia sesión nuevamente.') String message,
    int? statusCode,
  }) = _AuthException;
}
