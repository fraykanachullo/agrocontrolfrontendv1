/// Un tramo del gráfico de tendencia: lo cobrado y lo gastado en ese periodo.
class PuntoTendencia {
  final DateTime inicio;
  final double ingresos;
  final double gastos;

  const PuntoTendencia({required this.inicio, required this.ingresos, required this.gastos});

  double get ganancia => ingresos - gastos;
}

/// Movimiento con fecha y monto (un ingreso cobrado o un gasto).
typedef Movimiento = ({DateTime fecha, double monto});

/// Tendencia día a día, corrida de [desde] a [hasta] (de la creación de la
/// campaña a su cierre, o a hoy si sigue activa). Si hay movimientos con fecha
/// fuera de ese rango, el rango se estira para no perderlos.
List<PuntoTendencia> tendenciaDiaria({
  required DateTime desde,
  required DateTime hasta,
  required List<Movimiento> ingresos,
  required List<Movimiento> gastos,
}) {
  DateTime dia(DateTime d) => DateTime(d.year, d.month, d.day);
  final fechas = [desde, hasta, ...ingresos.map((m) => m.fecha), ...gastos.map((m) => m.fecha)].map(dia);
  final primero = fechas.reduce((a, b) => a.isBefore(b) ? a : b);
  final ultimo = fechas.reduce((a, b) => a.isAfter(b) ? a : b);

  final ing = <DateTime, double>{}, gas = <DateTime, double>{};
  for (final m in ingresos) {
    ing.update(dia(m.fecha), (v) => v + m.monto, ifAbsent: () => m.monto);
  }
  for (final m in gastos) {
    gas.update(dia(m.fecha), (v) => v + m.monto, ifAbsent: () => m.monto);
  }
  return [
    for (var d = primero; !d.isAfter(ultimo); d = DateTime(d.year, d.month, d.day + 1))
      PuntoTendencia(inicio: d, ingresos: ing[d] ?? 0, gastos: gas[d] ?? 0),
  ];
}

/// Los 12 meses de [anio] (enero a diciembre) con lo cobrado y lo gastado
/// en cada uno. Para comparar campañas en el calendario.
List<PuntoTendencia> mesesDelAnio(int anio, {required List<Movimiento> ingresos, required List<Movimiento> gastos}) {
  final ing = List.filled(12, 0.0), gas = List.filled(12, 0.0);
  for (final m in ingresos.where((m) => m.fecha.year == anio)) {
    ing[m.fecha.month - 1] += m.monto;
  }
  for (final m in gastos.where((m) => m.fecha.year == anio)) {
    gas[m.fecha.month - 1] += m.monto;
  }
  return [for (var i = 0; i < 12; i++) PuntoTendencia(inicio: DateTime(anio, i + 1), ingresos: ing[i], gastos: gas[i])];
}

/// Agrupa los días por semana (de lunes a domingo); cada punto empieza el
/// lunes. Para ver toda la campaña sin que los días sueltos hagan una sierra.
List<PuntoTendencia> porSemana(List<PuntoTendencia> dias) {
  final semanas = <DateTime, ({double ingresos, double gastos})>{};
  for (final d in dias) {
    final lunes = DateTime(d.inicio.year, d.inicio.month, d.inicio.day - (d.inicio.weekday - 1));
    final s = semanas[lunes] ?? (ingresos: 0.0, gastos: 0.0);
    semanas[lunes] = (ingresos: s.ingresos + d.ingresos, gastos: s.gastos + d.gastos);
  }
  return [for (final MapEntry(key: l, value: s) in semanas.entries) PuntoTendencia(inicio: l, ingresos: s.ingresos, gastos: s.gastos)];
}

/// Suma corrida: cada punto lleva lo acumulado hasta ese día (para comparar
/// campañas desde su inicio).
List<PuntoTendencia> acumulado(List<PuntoTendencia> puntos) {
  var i = 0.0, g = 0.0;
  return [
    for (final p in puntos) PuntoTendencia(inicio: p.inicio, ingresos: i += p.ingresos, gastos: g += p.gastos),
  ];
}
