import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

// ── Base Failure ──
abstract class Failure {
  final String message;

  const Failure({required this.message});
}

// ── Server Failure ──
@freezed
class ServerFailure extends Failure with _$ServerFailure {
  const factory ServerFailure({
    required String message,
    int? statusCode,
  }) = _ServerFailure;
}

// ── Network Failure ──
@freezed
class NetworkFailure extends Failure with _$NetworkFailure {
  const factory NetworkFailure({
    @Default('Sin conexión a internet.') String message,
  }) = _NetworkFailure;
}

// ── Auth Failure ──
@freezed
class AuthFailure extends Failure with _$AuthFailure {
  const factory AuthFailure({
    @Default('Credenciales inválidas.') String message,
    int? statusCode,
  }) = _AuthFailure;
}

// ── Cache Failure ──
@freezed
class CacheFailure extends Failure with _$CacheFailure {
  const factory CacheFailure({
    @Default('Error al acceder a los datos locales.') String message,
  }) = _CacheFailure;
}

// ── Validation Failure ──
@freezed
class ValidationFailure extends Failure with _$ValidationFailure {
  const factory ValidationFailure({
    required String message,
    Map<String, dynamic>? errors,
  }) = _ValidationFailure;
}
