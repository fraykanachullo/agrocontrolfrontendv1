import '../config/app_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String _base = AppConfig.apiPrefix;

  // ── Auth ──
  static const String login = '$_base/auth/login';
  static const String register = '$_base/auth/register';
  static const String logout = '$_base/auth/logout';
  static const String me = '$_base/auth/me';
  static const String forgotPassword = '$_base/auth/forgot-password';
  static const String resetPassword = '$_base/auth/reset-password';

  // ── Campañas ──
  static const String campanas = '$_base/campanas';
  static String campanaById(String id) => '$_base/campanas/$id';
  static String cerrarCampana(String id) => '$_base/campanas/$id/cerrar';
  static String balanceCampana(String id) => '$_base/campanas/$id/balance';

  // ── Actividades ──
  static String actividades(String campanaId) =>
      '$_base/campanas/$campanaId/actividades';

  // ── Transacciones ──
  static String transacciones(String campanaId) =>
      '$_base/campanas/$campanaId/transacciones';
  static String transaccionById(String id) => '$_base/transacciones/$id';

  // ── Cosechas/Envíos ──
  static String cosechasEnvios(String campanaId) =>
      '$_base/campanas/$campanaId/cosechas-envios';
  static String cosechaEnvioById(String id) => '$_base/cosechas-envios/$id';
  static String liquidarCosecha(String id) =>
      '$_base/cosechas-envios/$id/liquidar';

  // ── Dashboard ──
  static String dashboard(String campanaId) =>
      '$_base/campanas/$campanaId/dashboard';
  static String historial(String campanaId) =>
      '$_base/campanas/$campanaId/historial';

  // ── Evidencias ──
  static const String evidencias = '$_base/evidencias';

  // ── Reportes (Premium) ──
  static String reportePdf(String campanaId) =>
      '$_base/reportes/$campanaId/pdf';
  static String reporteExcel(String campanaId) =>
      '$_base/reportes/$campanaId/excel';

  // ── Sync ──
  static const String syncCampanas = '$_base/sync/campanas';
  static const String syncActividades = '$_base/sync/actividades';
  static const String syncTransacciones = '$_base/sync/transacciones';
  static const String syncCosechas = '$_base/sync/cosechas-envios';
  static const String syncCosechasLiquidar = '$_base/sync/cosechas-envios/liquidar';
  static const String syncEvidencias = '$_base/sync/evidencias/upload';
  static String syncPull(DateTime since) =>
      '$_base/sync/pull?since=${since.toUtc().toIso8601String()}';
}
