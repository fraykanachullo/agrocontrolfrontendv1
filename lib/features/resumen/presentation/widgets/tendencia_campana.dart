import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../../campanas/domain/entities/campana.dart';
import '../../domain/tendencia.dart';

final _compacto = NumberFormat.compact(locale: 'es');
final _entero = NumberFormat('#,##0', 'es_419');

String _mayuscula(String s) => s[0].toUpperCase() + s.substring(1);

/// "sept." → "Sep" (siempre tres letras para que entren en el eje).
String _mesCorto(DateTime d) => _mayuscula(DateFormat('MMM', 'es').format(d).replaceAll('.', '')).substring(0, 3);
String _mesAnio(DateTime d) => _mayuscula(DateFormat('MMMM y', 'es').format(d));
String _diaMes(DateTime d) => '${d.day} ${_mesCorto(d)}';
String _diaLargo(DateTime d) => DateFormat("EEEE d 'de' MMMM", 'es').format(d);

String _soles(double v) => '${v < 0 ? '-' : ''}${formatSoles(v.abs())}';
String _diaCorto(DateTime d) => DateFormat("d 'de' MMMM", 'es').format(d);

PuntoTendencia _maxPor(List<PuntoTendencia> p, double Function(PuntoTendencia) f) => p.reduce((a, b) => f(b) > f(a) ? b : a);
PuntoTendencia _minPor(List<PuntoTendencia> p, double Function(PuntoTendencia) f) => p.reduce((a, b) => f(b) < f(a) ? b : a);

const _guiaCero = 'Arriba de 0 ganaste · abajo, perdiste';

const _ayudaCampana = 'Cada punto es una semana (o un día, si eliges Acumulado o Por mes).\n\n'
    '• Verde: lo que cobraste.\n'
    '• Naranja: lo que gastaste.\n'
    '• Morado punteado: lo que te quedó (cobrado − gastado).\n\n'
    'Si el morado está arriba de 0, esa semana ganaste; si está abajo, gastaste más de lo que cobraste. '
    'Es normal estar abajo al inicio: es la etapa de inversión.\n\n'
    'Solo cuenta lo que ya te pagaron. Lo que te deben aparece cuando marcas que te pagaron.\n\n'
    'Toca el gráfico para ver los montos de cada punto.';

const _ayudaComparar = 'Cada línea es una campaña y cada punto es un mes del año.\n\n'
    'Con "Ganancia": si el punto está arriba de 0, ese mes la campaña ganó; si está abajo, gastó más de lo que cobró.\n\n'
    'Con "Ingresos" o "Gastos" ves cuánto cobró o gastó cada campaña cada mes.\n\n'
    'Debajo está el total del año de cada campaña, de mayor a menor. Toca una campaña para resaltarla.';

typedef _Movimientos = ({List<Movimiento> ingresos, List<Movimiento> gastos});

/// Movimientos de una campaña (o de todas, con null) para la tendencia, en
/// total y separados por campaña.
final _movimientosProvider = FutureProvider.family<({List<Movimiento> ingresos, List<Movimiento> gastos, Map<int, _Movimientos> porCampana}), int?>((
  ref,
  campanaId,
) async {
  ref.watch(dashboardRefreshTrigger);
  ref.watch(campanaListProvider);
  final filas = await ref.watch(campanaLocalDatasourceProvider).movimientosTendencia(campanaId: campanaId);
  final ingresos = <Movimiento>[], gastos = <Movimiento>[];
  final porCampana = <int, _Movimientos>{};
  for (final f in filas) {
    final fecha = DateTime.tryParse(f['fecha'] as String? ?? '');
    if (fecha == null) continue;
    final m = (fecha: fecha, monto: (f['monto'] as num).toDouble());
    final esGasto = f['tipo'] == 'gasto';
    (esGasto ? gastos : ingresos).add(m);
    final c = porCampana.putIfAbsent(f['campana_id'] as int, () => (ingresos: <Movimiento>[], gastos: <Movimiento>[]));
    (esGasto ? c.gastos : c.ingresos).add(m);
  }
  return (ingresos: ingresos, gastos: gastos, porCampana: porCampana);
});

/// Una forma de recorrer el tiempo en la tarjeta (toda la campaña, por mes…).
class _Modo {
  final String nombre;

  /// Periodos que se recorren con las flechas; vacío = sin flechas.
  final List<DateTime> periodos;
  final String Function(DateTime)? nombrePeriodo;
  final List<PuntoTendencia> Function(DateTime? periodo) puntos;

  /// Texto del eje X, del tooltip y de la tabla para un tramo.
  final String Function(DateTime) eje;
  final String Function(DateTime) tooltip;
  final String Function(DateTime) fila;

  /// Qué tramos llevan etiqueta en el eje (para que no se encimen).
  final bool Function(List<PuntoTendencia> puntos, int i) conEtiqueta;
  final String porTramo;

  /// Los puntos ya vienen sumados: el total es el último, no la suma de todos.
  final bool acumulado;

  /// La conclusión en palabras simples, para no tener que leer el gráfico.
  final String Function(List<PuntoTendencia> puntos)? lectura;

  const _Modo({
    required this.nombre,
    this.periodos = const [],
    this.nombrePeriodo,
    required this.puntos,
    required this.eje,
    required this.tooltip,
    required this.fila,
    required this.conEtiqueta,
    required this.porTramo,
    this.acumulado = false,
    this.lectura,
  });
}

/// Etiquetas del eje donde empieza un mes (y en el primer punto, si el
/// siguiente cambio de mes no queda tan cerca que se encimen).
bool _cambioDeMes(List<PuntoTendencia> p, int i) {
  bool cambia(int k) => k > 0 && p[k].inicio.month != p[k - 1].inicio.month;
  if (i > 0) return cambia(i);
  final siguiente = List.generate(p.length, (k) => k).firstWhere(cambia, orElse: () => p.length);
  return siguiente >= (p.length / 6).ceil();
}

bool _cadaCincoDias(List<PuntoTendencia> p, int i) => i == 0 || (i + 1) % 5 == 0;

List<DateTime> _mesesEntre(DateTime desde, DateTime hasta) => [
      for (var m = DateTime(desde.year, desde.month); !m.isAfter(DateTime(hasta.year, hasta.month)); m = DateTime(m.year, m.month + 1)) m,
    ];

/// Tendencia de UNA campaña: corrida día a día desde que se creó hasta que se
/// cierra (o hasta hoy), o los días de un mes de la campaña.
class TendenciaCampana extends ConsumerWidget {
  final Campana campana;

  const TendenciaCampana({super.key, required this.campana});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(_movimientosProvider(campana.id)).value;
    if (datos == null) return const SizedBox.shrink();
    final hoy = DateTime.now();
    final puntos = tendenciaDiaria(
      desde: campana.fechaInicio ?? campana.createdAt ?? hoy,
      hasta: campana.fechaCierre ?? hoy,
      ingresos: datos.ingresos,
      gastos: datos.gastos,
    );
    final meses = _mesesEntre(puntos.first.inicio, puntos.last.inicio);
    final semanas = porSemana(puntos);
    final acumulados = acumulado(puntos);
    final teDeben = ref.watch(campanaResumenesProvider).value?[campana.id]?.porCobrar ?? 0;

    return _TarjetaTendencia(
      titulo: 'Tendencia de la campaña',
      subtitulo: campana.isClosed
          ? 'Del ${_diaMes(puntos.first.inicio)} al cierre, ${_diaMes(puntos.last.inicio)}'
          : 'Desde el ${_diaMes(puntos.first.inicio)} hasta hoy',
      vacio: datos.ingresos.isEmpty && datos.gastos.isEmpty,
      ayuda: _ayudaCampana,
      nota: teDeben > 0 ? 'Además te deben ${formatSoles(teDeben)}: sumará cuando te paguen.' : null,
      modos: [
        _Modo(
          nombre: 'Por semana',
          lectura: (p) {
            final mejor = _maxPor(p, (e) => e.ganancia), peor = _minPor(p, (e) => e.ganancia);
            final inicio = mejor.ganancia > 0
                ? 'Tu mejor semana fue la del ${_diaCorto(mejor.inicio)}: te quedaron ${formatSoles(mejor.ganancia)}.'
                : 'Aún no hay una semana con ganancia: estás en la etapa de inversión.';
            return peor.ganancia < 0
                ? '$inicio La más dura, la del ${_diaCorto(peor.inicio)}: gastaste ${formatSoles(-peor.ganancia)} más de lo que cobraste.'
                : inicio;
          },
          puntos: (_) => semanas,
          eje: _diaMes,
          tooltip: (d) => 'Semana del ${DateFormat("d 'de' MMMM", 'es').format(d)}',
          fila: (d) => 'Sem. ${_diaMes(d)}',
          conEtiqueta: _cambioDeMes,
          porTramo: 'por semana',
        ),
        _Modo(
          nombre: 'Acumulado',
          puntos: (_) => acumulados,
          eje: _diaMes,
          tooltip: (d) => 'Hasta el ${_diaLargo(d)}',
          fila: _diaMes,
          conEtiqueta: _cambioDeMes,
          porTramo: 'por día',
          acumulado: true,
          lectura: (p) {
            final hoy = p.last, bajo = _minPor(p, (e) => e.ganancia);
            final estado = hoy.ganancia >= 0 ? 'vas ganando ${formatSoles(hoy.ganancia)}' : 'vas perdiendo ${formatSoles(-hoy.ganancia)}';
            final base = 'Hasta hoy cobraste ${formatSoles(hoy.ingresos)} y gastaste ${formatSoles(hoy.gastos)}: $estado.';
            final recuperado = hoy.ganancia - bajo.ganancia;
            return bajo.ganancia < 0 && recuperado > 0 && !identical(bajo, hoy)
                ? '$base Tu punto más bajo fue el ${_diaCorto(bajo.inicio)} (${_soles(bajo.ganancia)}); desde ahí recuperaste ${formatSoles(recuperado)}.'
                : base;
          },
        ),
        _Modo(
          nombre: 'Por mes',
          periodos: meses,
          nombrePeriodo: _mesAnio,
          puntos: (m) => puntos.where((p) => p.inicio.year == m!.year && p.inicio.month == m.month).toList(),
          eje: (d) => '${d.day}',
          tooltip: _diaLargo,
          fila: _diaMes,
          conEtiqueta: _cadaCincoDias,
          porTramo: 'por día',
          lectura: (p) {
            final cobrado = p.fold<double>(0, (s, e) => s + e.ingresos), gastado = p.fold<double>(0, (s, e) => s + e.gastos);
            final mes = DateFormat('MMMM', 'es').format(p.first.inicio);
            final base = 'En $mes cobraste ${formatSoles(cobrado)} y gastaste ${formatSoles(gastado)}.';
            final mejor = _maxPor(p, (e) => e.ingresos);
            return mejor.ingresos > 0 ? '$base El mejor día fue el ${mejor.inicio.day}: cobraste ${formatSoles(mejor.ingresos)}.' : base;
          },
        ),
      ],
    );
  }
}

enum _Metrica {
  ganancia('Ganancia'),
  ingresos('Ingresos'),
  gastos('Gastos');

  final String nombre;
  const _Metrica(this.nombre);

  double de(PuntoTendencia p) => switch (this) {
        _Metrica.ganancia => p.ganancia,
        _Metrica.ingresos => p.ingresos,
        _Metrica.gastos => p.gastos,
      };
}

/// Una campaña en el año elegido: sus 12 meses y los meses en que estuvo en
/// marcha (fuera de ellos no se dibuja línea).
class _Curva {
  final Campana campana;
  final Color color;
  final List<PuntoTendencia> meses;
  final int desde;
  final int hasta;

  const _Curva(this.campana, this.color, this.meses, this.desde, this.hasta);

  Iterable<PuntoTendencia> get activos => meses.sublist(desde, hasta + 1);
  double total(_Metrica m) => activos.fold(0, (s, p) => s + m.de(p));
}

/// "¿Cuál campaña va mejor?": los meses de un año (enero a diciembre) con una
/// línea por campaña. Muestra cuánto ganó, cobró o gastó cada una cada mes.
/// Toca una campaña para resaltarla.
class TendenciaGeneral extends ConsumerStatefulWidget {
  const TendenciaGeneral({super.key});

  @override
  ConsumerState<TendenciaGeneral> createState() => _TendenciaGeneralState();
}

class _TendenciaGeneralState extends ConsumerState<TendenciaGeneral> {
  _Metrica _metrica = _Metrica.ganancia;
  int? _anio;
  int? _resaltada;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final datos = ref.watch(_movimientosProvider(null)).value;
    if (datos == null) return const SizedBox.shrink();
    final serie = AppColors.palette.chartSeries;
    final hoy = DateTime.now();

    List<Widget> cabecera([String? lectura]) => [
          _Cabecera(
            titulo: '¿Cuál campaña va mejor?',
            subtitulo: '${_metrica.nombre} de cada campaña, mes a mes',
            ayuda: _ayudaComparar,
            lectura: lectura,
          ),
        ];

    // Años con movimientos; por defecto, el más reciente.
    final anios = {for (final m in [...datos.ingresos, ...datos.gastos]) m.fecha.year}.toList()..sort();
    if (anios.isEmpty) {
      return _marcoGeneral(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...cabecera(),
          const SizedBox(height: 14),
          Text('Registra gastos y ventas en tus campañas para compararlas.', style: text.bodyMedium),
        ],
      ));
    }
    final anio = anios.contains(_anio) ? _anio! : anios.last;
    final i = anios.indexOf(anio);

    // Un color fijo por campaña, según su orden de creación (máximo 8).
    final todas = ref.watch(campanaListProvider).campanas.where((c) => datos.porCampana.containsKey(c.id)).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final conColor = todas.length > serie.length ? todas.sublist(todas.length - serie.length) : todas;
    final curvas = <_Curva>[];
    for (final (k, c) in conColor.indexed) {
      final mov = datos.porCampana[c.id]!;
      final fechas = [c.fechaInicio ?? c.createdAt ?? hoy, c.fechaCierre ?? hoy, ...mov.ingresos.map((m) => m.fecha), ...mov.gastos.map((m) => m.fecha)];
      final primero = fechas.reduce((a, b) => a.isBefore(b) ? a : b);
      final ultimo = fechas.reduce((a, b) => a.isAfter(b) ? a : b);
      if (primero.year > anio || ultimo.year < anio) continue; // no estuvo en marcha ese año
      curvas.add(_Curva(
        c,
        serie[k],
        mesesDelAnio(anio, ingresos: mov.ingresos, gastos: mov.gastos),
        primero.year < anio ? 0 : primero.month - 1,
        ultimo.year > anio ? 11 : ultimo.month - 1,
      ));
    }
    final resaltada = curvas.any((c) => c.campana.id == _resaltada) ? _resaltada : null;
    final ranking = [...curvas]..sort((a, b) => b.total(_metrica).compareTo(a.total(_metrica)));
    void alternar(int id) => setState(() => _resaltada = resaltada == id ? null : id);

    return _marcoGeneral(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...cabecera(ranking.isEmpty ? null : _conclusion(anio, ranking)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            for (final m in _Metrica.values)
              MiniChip(label: m.nombre, selected: m == _metrica, onTap: () => setState(() => _metrica = m)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _Flecha(icon: Icons.chevron_left_rounded, onTap: i > 0 ? () => setState(() => _anio = anios[i - 1]) : null),
            Expanded(
              child: Text('$anio', textAlign: TextAlign.center, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            _Flecha(icon: Icons.chevron_right_rounded, onTap: i < anios.length - 1 ? () => setState(() => _anio = anios[i + 1]) : null),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final c in curvas)
              GestureDetector(
                onTap: () => alternar(c.campana.id),
                child: Opacity(
                  opacity: resaltada == null || resaltada == c.campana.id ? 1 : 0.4,
                  child: _Leyenda(color: c.color, label: _corto(c.campana.nombre)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(height: 250, child: _GraficoCampanas(curvas: curvas, metrica: _metrica, resaltada: resaltada)),
        if (_metrica == _Metrica.ganancia) ...[
          const SizedBox(height: 6),
          Text(_guiaCero, style: text.labelSmall),
        ],
        const SizedBox(height: 12),
        Text('${_metrica.nombre} en $anio', style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        for (final (k, c) in ranking.indexed)
          _FilaRanking(
            puesto: k + 1,
            curva: c,
            valor: c.total(_metrica),
            atenuada: resaltada != null && resaltada != c.campana.id,
            onTap: () => alternar(c.campana.id),
          ),
        const SizedBox(height: 6),
      ],
    ));
  }

  /// La conclusión del año en una o dos frases.
  String _conclusion(int anio, List<_Curva> ranking) {
    final primera = ranking.first, ultima = ranking.last;
    final a = _corto(primera.campana.nombre), b = _corto(ultima.campana.nombre);
    final (va, vb) = (primera.total(_metrica), ultima.total(_metrica));
    return switch (_metrica) {
      _Metrica.ganancia when ranking.length == 1 =>
        va >= 0 ? 'En $anio, $a lleva ganados ${formatSoles(va)}.' : 'En $anio, $a va perdiendo ${formatSoles(-va)}.',
      _Metrica.ganancia => 'En $anio, la que más ganó es $a (${_soles(va)}). '
          '${vb < 0 ? '$b va perdiendo ${formatSoles(-vb)}.' : 'La que menos ganó es $b (${formatSoles(vb)}).'}',
      _Metrica.ingresos => 'En $anio, la que más cobró es $a (${formatSoles(va)})'
          '${ranking.length > 1 ? '; la que menos, $b (${formatSoles(vb)}).' : '.'}',
      _Metrica.gastos => 'En $anio, la que más gastó es $a (${formatSoles(va)})'
          '${ranking.length > 1 ? '; la que menos, $b (${formatSoles(vb)}).' : '.'}',
    };
  }

  /// "Campaña de Tomate - Primavera 2026" → "Tomate - Primavera 2026".
  static String _corto(String nombre) => nombre.replaceFirst(RegExp(r'^Campaña de\s+', caseSensitive: false), '');

  Widget _marcoGeneral(Widget child) => GlassCard(highlight: true, radius: 24, padding: const EdgeInsets.fromLTRB(16, 18, 16, 10), child: child);
}

class _GraficoCampanas extends StatelessWidget {
  final List<_Curva> curvas;
  final _Metrica metrica;
  final int? resaltada;

  const _GraficoCampanas({required this.curvas, required this.metrica, required this.resaltada});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final valores = [0.0, for (final c in curvas) ...c.activos.map(metrica.de)];
    var minY = valores.reduce(math.min);
    var maxY = valores.reduce(math.max);
    if (maxY == minY) maxY = minY + 100;
    final intervalo = _Grafico._intervaloLimpio((maxY - minY) / 5);
    minY = (minY / intervalo).floor() * intervalo;
    maxY = (maxY / intervalo).ceil() * intervalo;
    final borde = AppColors.palette.cardTop;
    bool apagada(_Curva c) => resaltada != null && resaltada != c.campana.id;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 11,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        lineBarsData: [
          for (final c in curvas)
            LineChartBarData(
              // Solo los meses en que la campaña estuvo en marcha.
              spots: [for (var m = c.desde; m <= c.hasta; m++) FlSpot(m.toDouble(), metrica.de(c.meses[m]))],
              color: apagada(c) ? c.color.withValues(alpha: 0.25) : c.color,
              barWidth: apagada(c) ? 1.5 : 3,
              isStrokeCapRound: true,
              isStrokeJoinRound: true,
              dotData: FlDotData(
                show: !apagada(c),
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(radius: 3.5, color: c.color, strokeWidth: 2, strokeColor: borde),
              ),
            ),
        ],
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: intervalo,
          getDrawingHorizontalLine: (y) => FlLine(
            color: y == 0 ? AppColors.textSubtle.withValues(alpha: 0.7) : AppColors.outlineVariant,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: intervalo,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(v == 0 ? '0' : _compacto.format(v), style: text.labelSmall, maxLines: 1, softWrap: false),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final m = v.round();
                // Un mes sí y otro no, para que entren: Ene, Mar, May…
                if (m != v || m.isOdd || m > 11) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
                    child: Text(_mesCorto(DateTime(2000, m + 1)), style: text.labelSmall?.copyWith(fontSize: 10)),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (bar, indexes) => [
            for (final _ in indexes)
              TouchedSpotIndicatorData(
                FlLine(color: AppColors.textSubtle, strokeWidth: 1),
                FlDotData(
                  getDotPainter: (_, _, b, _) => FlDotCirclePainter(radius: 4, color: b.color ?? AppColors.accent, strokeWidth: 2, strokeColor: borde),
                ),
              ),
          ],
          touchTooltipData: LineTouchTooltipData(
            tooltipBorderRadius: BorderRadius.circular(12),
            tooltipBorder: BorderSide(color: AppColors.cardBorderStrong),
            getTooltipColor: (_) => AppColors.palette.sheet,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            maxContentWidth: 210,
            getTooltipItems: (spots) => [
              for (final (k, s) in spots.indexed)
                LineTooltipItem(
                  k == 0 ? '${_mesAnio(curvas[s.barIndex].meses[s.x.round()].inicio)}\n' : '',
                  text.labelSmall!.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.left,
                  children: [
                    TextSpan(text: '— ', style: TextStyle(color: curvas[s.barIndex].color, fontWeight: FontWeight.w900)),
                    TextSpan(
                      text: '${s.y < 0 ? '-' : ''}${formatSoles(s.y.abs())}',
                      style: AppTheme.display(fontSize: 13, color: AppColors.text),
                    ),
                    TextSpan(
                      text: '  ${curvas[s.barIndex].campana.cultivo}',
                      style: text.labelSmall!.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}

/// Puesto de una campaña en el año según la métrica elegida (también es la
/// vista en texto del gráfico).
class _FilaRanking extends StatelessWidget {
  final int puesto;
  final _Curva curva;
  final double valor;
  final bool atenuada;
  final VoidCallback onTap;

  const _FilaRanking({required this.puesto, required this.curva, required this.valor, required this.atenuada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = curva.campana;
    final meses = '${_mesCorto(curva.meses[curva.desde].inicio)}–${_mesCorto(curva.meses[curva.hasta].inicio)}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: atenuada ? 0.45 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              SizedBox(width: 20, child: Text('$puesto', style: text.labelMedium?.copyWith(fontWeight: FontWeight.w800))),
              Container(width: 14, height: 3, decoration: BoxDecoration(color: curva.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.nombre, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${c.isClosed ? 'Cerrada' : 'En curso'} · $meses', style: text.labelSmall),
                  ],
                ),
              ),
              Icon(valor >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: AppColors.textMuted),
              Text(
                '${valor < 0 ? '-' : ''}${formatSoles(valor.abs())}',
                style: AppTheme.display(fontSize: 14, color: AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta exclusiva del gráfico: título, modos, flechas de periodo, leyenda,
/// líneas de ingresos, gastos y ganancia, totales y tabla de datos.
class _TarjetaTendencia extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final bool vacio;
  final List<_Modo> modos;

  /// Explicación del botón "¿Cómo leer?".
  final String ayuda;

  /// Dato extra bajo la conclusión (por ejemplo, lo que te deben).
  final String? nota;

  const _TarjetaTendencia({
    required this.titulo,
    required this.subtitulo,
    required this.vacio,
    required this.modos,
    required this.ayuda,
    this.nota,
  });

  @override
  State<_TarjetaTendencia> createState() => _TarjetaTendenciaState();
}

class _TarjetaTendenciaState extends State<_TarjetaTendencia> {
  int _modo = 0;

  /// Periodo elegido con las flechas; null = el más reciente.
  DateTime? _periodo;
  bool _verTabla = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    List<Widget> cabecera([String? lectura]) =>
        [_Cabecera(titulo: widget.titulo, subtitulo: widget.subtitulo, ayuda: widget.ayuda, lectura: lectura, nota: widget.nota)];
    if (widget.vacio) {
      return _marco(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...cabecera(),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: AppColors.textSubtle),
              const SizedBox(width: 12),
              Expanded(child: Text('Registra gastos y ventas para ver la tendencia.', style: text.bodyMedium)),
            ],
          ),
        ],
      ));
    }

    final modo = widget.modos[_modo];
    final opciones = modo.periodos;
    final periodo = opciones.isEmpty ? null : (opciones.contains(_periodo) ? _periodo! : opciones.last);
    final i = periodo == null ? -1 : opciones.indexOf(periodo);
    final puntos = modo.puntos(periodo);
    final totalIngresos = modo.acumulado ? puntos.last.ingresos : puntos.fold<double>(0, (s, p) => s + p.ingresos);
    final totalGastos = modo.acumulado ? puntos.last.gastos : puntos.fold<double>(0, (s, p) => s + p.gastos);

    return _marco(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...cabecera(modo.lectura?.call(puntos)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (k, m) in widget.modos.indexed)
              MiniChip(
                label: m.nombre,
                selected: k == _modo,
                onTap: () => setState(() {
                  _modo = k;
                  _periodo = null;
                }),
              ),
          ],
        ),
        if (periodo != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              _Flecha(icon: Icons.chevron_left_rounded, onTap: i > 0 ? () => setState(() => _periodo = opciones[i - 1]) : null),
              Expanded(
                child: Text(
                  modo.nombrePeriodo!(periodo),
                  textAlign: TextAlign.center,
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _Flecha(
                icon: Icons.chevron_right_rounded,
                onTap: i < opciones.length - 1 ? () => setState(() => _periodo = opciones[i + 1]) : null,
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _Leyenda(color: AppColors.chartIngreso, label: 'Ingresos'),
            _Leyenda(color: AppColors.chartGasto, label: 'Gastos'),
            _Leyenda(color: AppColors.chartGanancia, label: 'Ganancia', punteada: true),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(height: 250, child: _Grafico(puntos: puntos, modo: modo)),
        const SizedBox(height: 6),
        Text(_guiaCero, style: text.labelSmall),
        const SizedBox(height: 14),
        Row(
          children: [
            _Total(color: AppColors.chartIngreso, label: 'Ingresos', valor: totalIngresos),
            _Total(color: AppColors.chartGasto, label: 'Gastos', valor: totalGastos),
            _Total(color: AppColors.chartGanancia, label: 'Ganancia', valor: totalIngresos - totalGastos),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _verTabla = !_verTabla),
            icon: Icon(_verTabla ? Icons.expand_less_rounded : Icons.table_rows_outlined, size: 18),
            label: Text(_verTabla ? 'Ocultar datos' : 'Ver datos ${modo.porTramo}'),
          ),
        ),
        if (_verTabla) _Tabla(puntos: puntos, etiqueta: modo.fila, acumulado: modo.acumulado),
      ],
    ));
  }

  Widget _marco(Widget child) => GlassCard(highlight: true, radius: 24, padding: const EdgeInsets.fromLTRB(16, 18, 16, 10), child: child);
}

/// Título y subtítulo de una tarjeta de gráfico, con un ícono que abre la
/// conclusión en palabras simples y cómo leer el gráfico.
class _Cabecera extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String ayuda;
  final String? lectura;
  final String? nota;

  const _Cabecera({required this.titulo, required this.subtitulo, required this.ayuda, this.lectura, this.nota});

  void _abrir(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final text = Theme.of(ctx).textTheme;
        return AlertDialog(
          title: Text(titulo),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lectura != null) ...[
                  Text('Lo que dice el gráfico', style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(lectura!, style: text.bodyMedium?.copyWith(color: AppColors.text)),
                  if (nota != null) ...[
                    const SizedBox(height: 6),
                    Text(nota!, style: text.bodySmall?.copyWith(color: AppColors.warning)),
                  ],
                  const SizedBox(height: 16),
                ],
                Text('Cómo leerlo', style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(ayuda, style: text.bodySmall),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Entendido'))],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(subtitulo, style: text.bodySmall),
            ],
          ),
        ),
        GlassCircleButton(
          icon: Icons.info_outline_rounded,
          tooltip: 'Qué dice este gráfico',
          size: 36,
          onPressed: () => _abrir(context),
        ),
      ],
    );
  }
}

class _Flecha extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _Flecha({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
        icon: Icon(icon),
        color: AppColors.text,
        disabledColor: AppColors.textSubtle.withValues(alpha: 0.4),
      );
}

class _Grafico extends StatelessWidget {
  final List<PuntoTendencia> puntos;
  final _Modo modo;

  const _Grafico({required this.puntos, required this.modo});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colores = [AppColors.chartIngreso, AppColors.chartGasto, AppColors.chartGanancia];
    final nombres = ['ingresos', 'gastos', 'ganancia'];
    final series = [
      [for (final (i, p) in puntos.indexed) FlSpot(i.toDouble(), p.ingresos)],
      [for (final (i, p) in puntos.indexed) FlSpot(i.toDouble(), p.gastos)],
      [for (final (i, p) in puntos.indexed) FlSpot(i.toDouble(), p.ganancia)],
    ];

    final valores = series.expand((s) => s.map((e) => e.y));
    var minY = math.min(0.0, valores.reduce(math.min));
    var maxY = math.max(0.0, valores.reduce(math.max));
    if (maxY == minY) maxY = minY + 100;
    final intervalo = _intervaloLimpio((maxY - minY) / 5);
    minY = (minY / intervalo).floor() * intervalo;
    maxY = (maxY / intervalo).ceil() * intervalo;
    final borde = AppColors.palette.cardTop;
    // Con muchos días la línea se adelgaza un poco para que no se empaste.
    final grosor = puntos.length > 45 ? 2.0 : 3.0;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, puntos.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        lineBarsData: [
          for (final (i, s) in series.indexed)
            LineChartBarData(
              spots: s,
              color: colores[i],
              barWidth: grosor,
              // Ganancia punteada: si casi no hay gastos coincide con ingresos
              // y así se ven las dos líneas.
              dashArray: i == 2 ? const [6, 4] : null,
              isStrokeCapRound: true,
              isStrokeJoinRound: true,
              dotData: const FlDotData(show: false),
            ),
        ],
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: intervalo,
          getDrawingHorizontalLine: (y) => FlLine(
            color: y == 0 ? AppColors.textSubtle.withValues(alpha: 0.7) : AppColors.outlineVariant,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: intervalo,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(v == 0 ? '0' : _compacto.format(v), style: text.labelSmall, maxLines: 1, softWrap: false),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i != v || i < 0 || i >= puntos.length || !modo.conEtiqueta(puntos, i)) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
                    child: Text(modo.eje(puntos[i].inicio), style: text.labelSmall?.copyWith(fontSize: 10)),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (bar, indexes) => [
            for (final _ in indexes)
              TouchedSpotIndicatorData(
                FlLine(color: AppColors.textSubtle, strokeWidth: 1),
                FlDotData(
                  getDotPainter: (_, _, b, _) => FlDotCirclePainter(radius: 4, color: b.color ?? colores.first, strokeWidth: 2, strokeColor: borde),
                ),
              ),
          ],
          touchTooltipData: LineTouchTooltipData(
            tooltipBorderRadius: BorderRadius.circular(12),
            tooltipBorder: BorderSide(color: AppColors.cardBorderStrong),
            getTooltipColor: (_) => AppColors.palette.sheet,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            maxContentWidth: 190,
            getTooltipItems: (spots) => [
              for (final (i, s) in spots.indexed)
                LineTooltipItem(
                  i == 0 ? '${modo.tooltip(puntos[s.x.round()].inicio)}\n' : '',
                  text.labelSmall!.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.left,
                  children: [
                    TextSpan(text: '— ', style: TextStyle(color: colores[s.barIndex], fontWeight: FontWeight.w900)),
                    TextSpan(
                      text: '${s.y < 0 ? '-' : ''}${formatSoles(s.y.abs())}',
                      style: AppTheme.display(fontSize: 13, color: AppColors.text),
                    ),
                    TextSpan(text: '  ${nombres[s.barIndex]}', style: text.labelSmall!.copyWith(color: AppColors.textMuted)),
                  ],
                ),
            ],
          ),
        ),
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  /// Paso del eje en 1, 2 o 5 por potencia de diez (100, 200, 500…).
  static double _intervaloLimpio(double bruto) {
    if (bruto <= 0) return 1;
    final base = math.pow(10, (math.log(bruto) / math.ln10).floor()).toDouble();
    for (final m in [1, 2, 5, 10]) {
      if (bruto <= base * m) return base * m;
    }
    return base * 10;
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String label;
  final bool punteada;

  const _Leyenda({required this.color, required this.label, this.punteada = false});

  @override
  Widget build(BuildContext context) {
    Widget trazo(double w) => Container(width: w, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (punteada) ...[trazo(6), const SizedBox(width: 3), trazo(6)] else trazo(16),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// Total del periodo que se está viendo.
class _Total extends StatelessWidget {
  final Color color;
  final String label;
  final double valor;

  const _Total({required this.color, required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 5),
              Text(label, style: text.labelSmall),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${valor < 0 ? '-' : ''}${formatSoles(valor.abs())}',
              style: AppTheme.display(fontSize: 16, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Los mismos datos en filas (solo los tramos con movimiento).
class _Tabla extends StatelessWidget {
  final List<PuntoTendencia> puntos;
  final String Function(DateTime) etiqueta;
  final bool acumulado;

  const _Tabla({required this.puntos, required this.etiqueta, this.acumulado = false});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cifra = text.labelMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    // En el acumulado, solo los días en que cambió algo.
    final conDatos = [
      for (final (i, p) in puntos.indexed)
        if (acumulado
            ? (i == 0 ? p.ingresos != 0 || p.gastos != 0 : p.ingresos != puntos[i - 1].ingresos || p.gastos != puntos[i - 1].gastos)
            : p.ingresos != 0 || p.gastos != 0)
          p,
    ];
    Widget fila(String a, List<String> v, {TextStyle? estilo}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text(a, style: estilo ?? text.labelMedium)),
              for (final x in v) Expanded(flex: 3, child: Text(x, textAlign: TextAlign.right, style: estilo ?? cifra)),
            ],
          ),
        );
    String soles(double v) => v == 0 ? '—' : '${v < 0 ? '-' : ''}${_entero.format(v.abs())}';

    return Column(
      children: [
        fila('S/', ['Ingresos', 'Gastos', 'Ganancia'], estilo: text.labelSmall),
        Divider(height: 1, color: AppColors.cardBorder),
        for (final p in conDatos) fila(etiqueta(p.inicio), [soles(p.ingresos), soles(p.gastos), soles(p.ganancia)]),
      ],
    );
  }
}
