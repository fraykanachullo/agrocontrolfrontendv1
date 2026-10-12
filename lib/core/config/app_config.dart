class AppConfig {
  AppConfig._();

  // ── Environment ──
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static bool get isDev => env == 'development';
  static bool get isProd => env == 'production';

  // ── API ──
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.116.14.84/api',
  );

  static const String apiVersion = 'v1';
  static const String apiPrefix = '$apiBaseUrl/$apiVersion';

  // ── Timeouts ──
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Storage Keys ──
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String campanaIdKey = 'active_campana_id';
  static const String unitKey = 'measurement_unit';

  // ── Pagination ──
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ── Sync ──
  static const int syncBatchSize = 50;
  static const Duration syncInterval = Duration(minutes: 5);
}
