import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../../cuaderno/presentation/screens/cuaderno_screen.dart' show HistorialTimelineItem, historialFilters;

/// Periodos rápidos del historial.
enum _Periodo { hoy, semana, mes, campana, elegido }

/// Historial de la campaña por rango de fechas (RF-12): resumen del
/// periodo y registros agrupados por día. Funciona sin conexión.
class HistorialScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const HistorialScreen({super.key, required this.campaignId});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  _Periodo _periodo = _Periodo.semana;
  DateTimeRange? _elegido;
  String? _filtro;

  int get _campanaId => int.tryParse(widget.campaignId) ?? 0;

  DateTime get _hoy => DateUtils.dateOnly(DateTime.now());

  DateTimeRange _rango() {
    final campana = ref.read(activeCampanaProvider);
    final inicio = campana?.fechaInicio ?? campana?.createdAt ?? _hoy;
    final fin = campana?.isClosed == true && campana?.fechaCierre != null ? campana!.fechaCierre! : _hoy;
    return switch (_periodo) {
      _Periodo.hoy => DateTimeRange(start: _hoy, end: _hoy),
      _Periodo.semana => DateTimeRange(start: _hoy.subtract(const Duration(days: 6)), end: _hoy),
      _Periodo.mes => DateTimeRange(start: DateTime(_hoy.year, _hoy.month), end: _hoy),
      _Periodo.campana => DateTimeRange(start: DateUtils.dateOnly(inicio), end: DateUtils.dateOnly(fin)),
      _Periodo.elegido => _elegido ?? DateTimeRange(start: _hoy, end: _hoy),
    };
  }

  Future<void> _elegirFechas() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: _hoy,
      initialDateRange: _elegido ?? _rango(),
      helpText: 'Elige el periodo',
      saveText: 'Ver',
    );
    if (picked != null) {
      setState(() {
        _elegido = picked;
        _periodo = _Periodo.elegido;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    ref.watch(activeCampanaProvider);
    final rango = _rango();
    final async = ref.watch(historialRangoProvider((_campanaId, rango.start, rango.end)));
    final todos = async.value ?? const <HistorialEntry>[];
    final lista = _filtro == null ? todos : todos.where((e) => e.tipo == _filtro).toList();

    // Agrupar por día, del más reciente al más antiguo.
    final dias = <DateTime, List<HistorialEntry>>{};
    for (final e in lista) {
      dias.putIfAbsent(DateUtils.dateOnly(e.fecha ?? _hoy), () => []).add(e);
    }

    Widget periodo(_Periodo p, String label) => MiniChip(
          label: label,
          large: true,
          selected: _periodo == p,
          onTap: () => setState(() => _periodo = p),
        );

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            periodo(_Periodo.hoy, 'Hoy'),
            periodo(_Periodo.semana, '7 días'),
            periodo(_Periodo.mes, 'Este mes'),
            periodo(_Periodo.campana, 'Toda la campaña'),
          ],
        ),
        const SizedBox(height: 10),
        GlassCard(
          radius: 18,
          onTap: _elegirFechas,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.date_range_rounded, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_periodo == _Periodo.elegido ? 'Periodo elegido' : 'Periodo', style: text.labelSmall),
                    Text(_textoRango(rango), style: text.titleSmall),
                  ],
                ),
              ),
              Text('Elegir fechas', style: text.labelMedium?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ResumenPeriodo(entries: todos),
        const SizedBox(height: 18),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: historialFilters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => MiniChip(
              label: historialFilters[i].$2,
              selected: _filtro == historialFilters[i].$1,
              onTap: () => setState(() => _filtro = historialFilters[i].$1),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (async.isLoading && todos.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else if (lista.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.event_busy_rounded, color: AppColors.textSubtle, size: 32),
                const SizedBox(height: 8),
                Text(todos.isEmpty ? 'Nada registrado en este periodo' : 'Sin registros de este tipo', style: text.bodyMedium),
                const SizedBox(height: 2),
                Text('Prueba con otras fechas', style: text.bodySmall),
              ],
            ),
          )
        else
          for (final MapEntry(key: dia, value: registros) in dias.entries) ...[
            _CabeceraDia(dia: dia, registros: registros),
            for (final (i, e) in registros.indexed) HistorialTimelineItem(entry: e, isLast: i == registros.length - 1),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  String _textoRango(DateTimeRange r) {
    final f = DateFormat("d MMM y", 'es');
    if (DateUtils.isSameDay(r.start, r.end)) return DateFormat("EEEE d 'de' MMMM", 'es').format(r.start);
    final dias = r.end.difference(r.start).inDays + 1;
    return '${f.format(r.start)} – ${f.format(r.end)} · $dias días';
  }
}

/// Totales del periodo: lo gastado, lo ingresado y cuántas labores e incidencias.
class _ResumenPeriodo extends StatelessWidget {
  final List<HistorialEntry> entries;

  const _ResumenPeriodo({required this.entries});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    double suma(String tipo) => entries.where((e) => e.tipo == tipo).fold(0, (s, e) => s + (e.monto ?? 0));
    int cuenta(String tipo) => entries.where((e) => e.tipo == tipo).length;
    final ventas = entries.where((e) => e.tipo == 'cosecha').fold<double>(0, (s, e) => s + (e.monto ?? 0));

    Widget cifra(String label, String valor, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelSmall),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valor, style: AppTheme.display(fontSize: 17, color: color)),
              ),
            ],
          ),
        );

    return GlassCard(
      highlight: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              cifra('Gastado', formatSoles(suma('gasto')), AppColors.expense),
              cifra('Ingresos y ventas', formatSoles(suma('ingreso') + ventas), AppColors.positive),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              cifra('Labores', '${cuenta('actividad')}', AppColors.text),
              cifra('Incidencias', '${cuenta('incidencia')}', cuenta('incidencia') > 0 ? AppColors.error : AppColors.text),
              cifra('Registros', '${entries.length}', AppColors.text),
            ],
          ),
        ],
      ),
    );
  }
}

class _CabeceraDia extends StatelessWidget {
  final DateTime dia;
  final List<HistorialEntry> registros;

  const _CabeceraDia({required this.dia, required this.registros});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hoy = DateUtils.dateOnly(DateTime.now());
    final etiqueta = DateUtils.isSameDay(dia, hoy)
        ? 'Hoy'
        : DateUtils.isSameDay(dia, hoy.subtract(const Duration(days: 1)))
            ? 'Ayer'
            : DateFormat("EEEE d 'de' MMMM", 'es').format(dia);
    final gastado = registros.where((e) => e.tipo == 'gasto').fold<double>(0, (s, e) => s + (e.monto ?? 0));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta[0].toUpperCase() + etiqueta.substring(1),
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            [
              '${registros.length} registro${registros.length == 1 ? '' : 's'}',
              if (gastado > 0) '-${formatSoles(gastado)}',
            ].join(' · '),
            style: text.labelSmall,
          ),
        ],
      ),
    );
  }
}
