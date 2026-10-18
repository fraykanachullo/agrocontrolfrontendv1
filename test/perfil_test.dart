import 'package:agrocontrol/features/perfil/presentation/screens/perfil_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ahora = DateTime(2026, 10, 18, 18, 0);

  test('haceCuanto describe la última sincronización', () {
    expect(haceCuanto(ahora.subtract(const Duration(seconds: 20)), ahora), 'hace un momento');
    expect(haceCuanto(ahora.subtract(const Duration(minutes: 5)), ahora), 'hace 5 min');
    expect(haceCuanto(ahora.subtract(const Duration(hours: 3)), ahora), 'hace 3 h');
    expect(haceCuanto(ahora.subtract(const Duration(hours: 30)), ahora), 'ayer');
    expect(haceCuanto(DateTime(2026, 10, 12, 9), ahora), 'el 12/10');
  });
}
