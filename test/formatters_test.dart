import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:agrocontrol/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  group('AppFormatters.currency', () {
    test('formats amounts in Peruvian Soles', () {
      final formatted = AppFormatters.currency(1234567.89);
      expect(formatted, contains('S/'));
      expect(formatted, contains('1.234.567,89'));
    });

    test('formats zero', () {
      expect(AppFormatters.currency(0), contains('0,00'));
    });
  });

  group('AppFormatters.date', () {
    test('formats dd/MM/yyyy', () {
      expect(
        AppFormatters.date(DateTime(2024, 5, 3)),
        '03/05/2024',
      );
    });

    test('formats dd/MM/yyyy HH:mm', () {
      expect(
        AppFormatters.dateTime(DateTime(2024, 5, 3, 14, 30)),
        '03/05/2024 14:30',
      );
    });
  });

  group('AppFormatters.monthYear', () {
    test('formats month and year in Spanish', () {
      final formatted = AppFormatters.monthYear(DateTime(2024, 5, 3));
      expect(formatted.toLowerCase(), contains('mayo'));
      expect(formatted, contains('2024'));
    });
  });

  group('AppFormatters.dayMonth', () {
    test('formats day and month abbreviation', () {
      final formatted = AppFormatters.dayMonth(DateTime(2024, 5, 3));
      expect(formatted.contains('03'), isTrue);
      expect(formatted.toLowerCase(), contains('may'));
    });
  });

  group('AppFormatters.relative', () {
    test('under a minute shows "Ahora mismo"', () {
      final date = DateTime.now().subtract(const Duration(seconds: 30));
      expect(AppFormatters.relative(date), 'Ahora mismo');
    });

    test('minutes', () {
      final date = DateTime.now().subtract(const Duration(minutes: 5));
      expect(AppFormatters.relative(date), 'Hace 5 min');
    });

    test('hours', () {
      final date = DateTime.now().subtract(const Duration(hours: 3));
      expect(AppFormatters.relative(date), 'Hace 3h');
    });

    test('days', () {
      final date = DateTime.now().subtract(const Duration(days: 3));
      expect(AppFormatters.relative(date), 'Hace 3d');
    });

    test('weeks', () {
      final date = DateTime.now().subtract(const Duration(days: 14));
      expect(AppFormatters.relative(date), 'Hace 2 sem');
    });

    test('months', () {
      final date = DateTime.now().subtract(const Duration(days: 60));
      expect(AppFormatters.relative(date), 'Hace 2 mes');
    });

    test('years', () {
      final date = DateTime.now().subtract(const Duration(days: 730));
      expect(AppFormatters.relative(date), 'Hace 2 año');
    });
  });

  group('AppFormatters.area', () {
    test('formats hectares', () {
      expect(AppFormatters.area(1.5, 'ha'), '1.50 ha');
    });

    test('formats topos', () {
      expect(AppFormatters.area(3.25, 'topos'), '3.25 topos');
    });

    test('formats square meters with superscript', () {
      expect(AppFormatters.area(150.0, 'm2'), '150.00 m²');
    });

    test('falls back to raw unit', () {
      expect(AppFormatters.area(2, 'custom'), '2.00 custom');
    });
  });

  group('AppFormatters.percentage', () {
    test('formats one decimal', () {
      expect(AppFormatters.percentage(12.346), '12.3%');
    });
  });

  group('AppFormatters.number', () {
    test('formats with default decimals', () {
      expect(AppFormatters.number(3.14159), '3.14');
    });

    test('respects decimals argument', () {
      expect(AppFormatters.number(3.14159, decimals: 3), '3.142');
    });
  });

  group('AppFormatters.phone', () {
    test('formats Peruvian 9-digit numbers', () {
      expect(AppFormatters.phone('987654321'), '987 654 321');
    });

    test('returns input unchanged when not 9 digits', () {
      expect(AppFormatters.phone('123'), '123');
    });
  });
}