import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../errors/exceptions.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  DioClient({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiPrefix,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_secureStorage),
      _ErrorInterceptor(),
      if (AppConfig.isDev) _LogInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}

// ── Auth Interceptor: adds Bearer token ──
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthRoute(options.path)) {
      return handler.next(options);
    }

    final token = await _storage.read(key: AppConfig.tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefreshToken(err.requestOptions);
      if (refreshed) {
        final newToken =
            await _storage.read(key: AppConfig.tokenKey);
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await Dio().fetch(err.requestOptions);
        return handler.resolve(response);
      }
      await _storage.delete(key: AppConfig.tokenKey);
      await _storage.delete(key: AppConfig.refreshTokenKey);
    }

    return handler.next(err);
  }

  bool _isAuthRoute(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/reset-password');
  }

  Future<bool> _tryRefreshToken(RequestOptions requestOptions) async {
    try {
      final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConfig.apiPrefix}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newToken = response.data['data']['token'];
        await _storage.write(key: AppConfig.tokenKey, value: newToken);
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}

// ── Error Interceptor: maps Dio errors to ServerException via handler.reject ──
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
        message: exception.message,
      ),
    );
  }

  ServerException _mapDioException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerException(
          message: 'Tiempo de espera agotado. Verifica tu conexión.',
          statusCode: 408,
        );
      case DioExceptionType.connectionError:
        return const ServerException(
          message: 'Sin conexión a internet.',
          statusCode: 0,
        );
      case DioExceptionType.badResponse:
        return _handleBadResponse(err.response);
      default:
        return ServerException(
          message: err.message ?? 'Error desconocido',
          statusCode: 500,
        );
    }
  }

  ServerException _handleBadResponse(Response? response) {
    if (response == null) {
      return const ServerException(
        message: 'Sin respuesta del servidor.',
        statusCode: 500,
      );
    }

    final statusCode = response.statusCode ?? 500;
    String message;

    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        message = data['message'] ?? _getDefaultMessage(statusCode);
        if (data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        }
      } else {
        message = _getDefaultMessage(statusCode);
      }
    } catch (_) {
      message = _getDefaultMessage(statusCode);
    }

    return ServerException(message: message, statusCode: statusCode);
  }

  String _getDefaultMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Solicitud incorrecta.';
      case 401:
        return 'Credenciales inválidas.';
      case 403:
        return 'No tienes permiso para esta acción.';
      case 404:
        return 'Recurso no encontrado.';
      case 409:
        return 'Conflicto: hay datos pendientes.';
      case 422:
        return 'Error de validación.';
      case 500:
        return 'Error interno del servidor.';
      default:
        return 'Error del servidor ($statusCode).';
    }
  }
}

// ── Log Interceptor (dev only) ──
class _LogInterceptor extends Interceptor {
  final _log = _Logger();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) {
    _log.info('┌────── REQUEST ──────');
    _log.info('│ ${options.method} ${options.uri}');
    if (options.data != null) _log.info('│ Body: ${options.data}');
    _log.info('└────────────────────');
    return handler.next(options);
  }

  @override
  void onResponse(
      Response response, ResponseInterceptorHandler handler) {
    _log.info('┌────── RESPONSE ─────');
    _log.info('│ ${response.statusCode} ${response.requestOptions.uri}');
    _log.info('└─────────────────────');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.info('┌────── ERROR ────────');
    _log.info('│ ${err.type} ${err.requestOptions.uri}');
    _log.info('│ ${err.message}');
    _log.info('└─────────────────────');
    return handler.next(err);
  }
}

class _Logger {
  void info(String message) {
    // ignore: avoid_print
    print('[API] $message');
  }
}
