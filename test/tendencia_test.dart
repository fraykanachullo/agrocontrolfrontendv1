import 'package:agrocontrol/features/resumen/domain/tendencia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('día a día de la creación al cierre, estirando si hay movimientos fuera', () {
    final p = tendenciaDiaria(
      desde: DateTime(2026, 7, 10, 15, 30),
      hasta: DateTime(2026, 7, 14),
      gastos: [(fecha: DateTime(2026, 7, 8), monto: 20)],
      ingresos: [(fecha: DateTime(2026, 7, 12, 9), monto: 300)],
    );
    expect(p.first.inicio, DateTime(2026, 7, 8));
    expect(p.last.inicio, DateTime(2026, 7, 14));
    expect(p.length, 7);
    expect(p[0].gastos, 20);
    expect(p[4].ingresos, 300);
  });

  test('acumulado suma día a día', () {
    final dias = tendenciaDiaria(
      desde: DateTime(2026, 7, 1),
      hasta: DateTime(2026, 7, 4),
      gastos: [(fecha: DateTime(2026, 7, 1), monto: 100), (fecha: DateTime(2026, 7, 3), monto: 50)],
      ingresos: [(fecha: DateTime(2026, 7, 4), monto: 500)],
    );
    final a = acumulado(dias);
    expect(a.map((p) => p.gastos), [100, 100, 150, 150]);
    expect(a.map((p) => p.ganancia), [-100, -100, -150, 350]);
  });

  test('por semana suma de lunes a domingo', () {
    final dias = tendenciaDiaria(
      desde: DateTime(2026, 10, 1), // jueves
      hasta: DateTime(2026, 10, 13),
      gastos: [(fecha: DateTime(2026, 10, 2), monto: 100), (fecha: DateTime(2026, 10, 4), monto: 50)],
      ingresos: [(fecha: DateTime(2026, 10, 13), monto: 400)],
    );
    final s = porSemana(dias);
    expect(s.map((p) => p.inicio), [DateTime(2026, 9, 28), DateTime(2026, 10, 5), DateTime(2026, 10, 12)]);
    expect(s.map((p) => p.gastos), [150, 0, 0]);
    expect(s.map((p) => p.ingresos), [0, 0, 400]);
  });

  test('meses del año: enero a diciembre, solo ese año', () {
    final m = mesesDelAnio(2026,
        gastos: [(fecha: DateTime(2026, 3, 5), monto: 100), (fecha: DateTime(2025, 3, 5), monto: 999)],
        ingresos: [(fecha: DateTime(2026, 10, 2), monto: 400)]);
    expect(m.length, 12);
    expect(m[2].gastos, 100);
    expect(m[9].ganancia, 400);
    expect(m.fold<double>(0, (s, p) => s + p.gastos), 100);
  });
}
