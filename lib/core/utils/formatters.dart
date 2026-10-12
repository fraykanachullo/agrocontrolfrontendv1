import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  // ── Currency (Peruvian Soles) ──
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );

  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  // ── Dates ──
  static String date(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'es').format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'es').format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'es').format(date);
  }

  static String dayMonth(DateTime date) {
    return DateFormat('dd MMM', 'es').format(date);
  }

  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} sem';
    if (diff.inDays < 365) return 'Hace ${(diff.inDays / 30).floor()} mes';
    return 'Hace ${(diff.inDays / 365).floor()} año';
  }

  // ── Area ──
  static String area(double value, String unit) {
    final formatted = value.toStringAsFixed(2);
    switch (unit) {
      case 'ha':
        return '$formatted ha';
      case 'topos':
        return '$formatted topos';
      case 'm2':
        return '$formatted m²';
      default:
        return '$formatted $unit';
    }
  }

  // ── Percentage ──
  static String percentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  // ── Number with decimals ──
  static String number(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  // ── Phone (Peruvian format) ──
  static String phone(String number) {
    final cleaned = number.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 9) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }
    return number;
  }
}
