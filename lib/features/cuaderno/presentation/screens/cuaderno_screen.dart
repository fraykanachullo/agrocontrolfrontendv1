import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../campanas/presentation/campaign_display.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../widgets/expense_sheet.dart';
import '../widgets/record_sheets.dart';

/// Tipos de registro del cuaderno: (tipo, nombre, icono, color).
(String, IconData, Color) entryStyle(String tipo) => switch (tipo) {
      'gasto' => ('Gasto', Icons.payments_outlined, AppColors.expense),
      'ingreso' => ('Ingreso', Icons.savings_outlined, AppColors.positive),
      'cosecha' => ('Cosecha', Icons.local_shipping_outlined, AppColors.warning),
      'incidencia' => ('Incidencia', Icons.report_outlined, AppColors.error),
      _ => ('Labor', Icons.agriculture_outlined, AppColors.info),
    };

/// Filtros por tipo de registro (cuaderno e historial).
const historialFilters = [
  (null, 'Todos'),
  ('gasto', 'Gastos'),
  ('ingreso', 'Ingresos'),
  ('actividad', 'Labores'),
  ('incidencia', 'Incidencias'),
  ('cosecha', 'Cosechas'),
];

class CuadernoScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const CuadernoScreen({super.key, required this.campaignId});

  @override
  ConsumerState<CuadernoScreen> createState() => _CuadernoScreenState();
}

class _CuadernoScreenState extends ConsumerState<CuadernoScreen> {
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  String? _filter;

  int get _campanaId => int.tryParse(widget.campaignId) ?? 0;
  bool get _isToday => DateUtils.isSameDay(_day, DateTime.now());

  void _moveDay(int delta) {
    final next = _day.add(Duration(days: delta));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _day = next);
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _day = DateUtils.dateOnly(picked));
  }

  void _open(String tipo) {
    final nombre = ref.read(activeCampanaProvider)?.nombre ?? '';
    switch (tipo) {
      case 'gasto':
        showExpenseSheet(context, campanaId: _campanaId, campanaNombre: nombre, date: _day);
      case 'ingreso':
        showIncomeSheet(context, campanaId: _campanaId, campanaNombre: nombre, date: _day);
      case 'incidencia':
        showIncidentSheet(context, campanaId: _campanaId, campanaNombre: nombre, date: _day);
      default:
        showLaborSheet(context, campanaId: _campanaId, campanaNombre: nombre, date: _day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(historialDayProvider((_campanaId, _day)));
    final list = entries.value ?? const <HistorialEntry>[];
    final filtered = _filter == null ? list : list.where((e) => e.tipo == _filter).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        _DayNavigator(
          day: _day,
          isToday: _isToday,
          campaignName: ref.watch(activeCampanaProvider)?.nombre,
          onPrev: () => _moveDay(-1),
          onNext: _isToday ? null : () => _moveDay(1),
          onPick: _pickDay,
          onToday: () => setState(() => _day = DateUtils.dateOnly(DateTime.now())),
        ),
        const SizedBox(height: 16),
        if (ref.watch(activeCampanaProvider)?.isClosed ?? false)
          ClosedCampaignNotice(campana: ref.watch(activeCampanaProvider)!)
        else
          _ActionGrid(onSelected: _open),
        const SizedBox(height: 16),
        _DaySummary(entries: list, isToday: _isToday),
        const SizedBox(height: 24),
        SectionHeader(title: 'Registros del día (${list.length})'),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: historialFilters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => MiniChip(
              label: historialFilters[i].$2,
              selected: _filter == historialFilters[i].$1,
              onTap: () => setState(() => _filter = historialFilters[i].$1),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (entries.isLoading && list.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else if (filtered.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.menu_book_outlined, color: AppColors.textSubtle, size: 32),
                const SizedBox(height: 8),
                Text(
                  list.isEmpty ? 'Nada registrado este día' : 'Sin registros de este tipo',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text('Usa los botones de arriba para anotar', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          )
        else
          for (final (i, e) in filtered.indexed) HistorialTimelineItem(entry: e, isLast: i == filtered.length - 1),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
//  Secciones
// ═══════════════════════════════════════════════

class _DayNavigator extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final String? campaignName;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPick;
  final VoidCallback onToday;

  const _DayNavigator({
    required this.day,
    required this.isToday,
    required this.campaignName,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
    required this.onToday,
  });

  static int _weekOfYear(DateTime d) {
    final dayOfYear = int.parse(DateFormat('D').format(d));
    return ((dayOfYear - d.weekday + 10) / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = isToday
        ? 'Hoy, ${DateFormat('d MMM yyyy', 'es').format(day)}'
        : toBeginningOfSentenceCase(DateFormat('EEEE d MMM', 'es').format(day));

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          GlassCircleButton(icon: Icons.chevron_left_rounded, tooltip: 'Día anterior', size: 44, onPressed: onPrev),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Flexible(child: Text(label, style: text.titleSmall, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (isToday)
                      Text(
                        'Semana ${_weekOfYear(day)}${campaignName == null ? '' : ' · $campaignName'}',
                        style: text.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      GestureDetector(
                        onTap: onToday,
                        child: Text(
                          'Volver a hoy',
                          style: text.labelSmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Opacity(
            opacity: onNext == null ? 0.35 : 1,
            child: GlassCircleButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Día siguiente',
              size: 44,
              onPressed: onNext ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuatro botones grandes 2×2 para anotar.
class _ActionGrid extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const _ActionGrid({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('actividad', 'Labor', 'Faenas de campo'),
      ('gasto', 'Gasto', 'Jornal e insumo'),
      ('ingreso', 'Ingreso', 'Ventas y otros'),
      ('incidencia', 'Incidencia', 'Plaga o clima'),
    ];
    final text = Theme.of(context).textTheme;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.15,
      children: [
        for (final (tipo, label, caption) in actions)
          Builder(builder: (context) {
            final (_, icon, color) = entryStyle(tipo);
            return GlassCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onTap: () => onSelected(tipo),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                    child: Icon(icon, color: color, size: 23),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        Text(caption, style: text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _DaySummary extends StatelessWidget {
  final List<HistorialEntry> entries;
  final bool isToday;

  const _DaySummary({required this.entries, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    double sum(String tipo) => entries.where((e) => e.tipo == tipo).fold(0, (s, e) => s + (e.monto ?? 0));
    final gastos = sum('gasto');
    final ingresos = sum('ingreso');
    final labores = entries.where((e) => e.tipo == 'actividad').toList();
    final incidencias = entries.where((e) => e.tipo == 'incidencia').length;

    return GlassCard(
      highlight: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isToday ? 'RESUMEN DE HOY' : 'RESUMEN DEL DÍA',
            style: text.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Stat(icon: Icons.trending_down_rounded, label: 'Gastos', value: gastos, color: AppColors.expense)),
              Container(width: 1, height: 40, color: AppColors.outlineVariant),
              const SizedBox(width: 14),
              Expanded(child: _Stat(icon: Icons.trending_up_rounded, label: 'Ingresos', value: ingresos, color: AppColors.positive)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Icons.checklist_rounded, size: 18, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    labores.isEmpty
                        ? 'Sin labores registradas'
                        : '${labores.length} labor${labores.length == 1 ? '' : 'es'}: ${labores.map((e) => e.titulo).toSet().join(', ')}',
                    style: text.bodySmall?.copyWith(color: AppColors.text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (incidencias > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.report_outlined, size: 16, color: AppColors.error),
                  const SizedBox(width: 2),
                  Text('$incidencias', style: text.labelMedium?.copyWith(color: AppColors.error, fontWeight: FontWeight.w800)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  const _Stat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(formatSoles(value), style: AppTheme.display(fontSize: 20, color: value == 0 ? AppColors.textMuted : color)),
        ),
      ],
    );
  }
}

/// Registro en la línea de tiempo: punto + línea a la izquierda, tarjeta a la derecha.
/// Registro en la línea de tiempo (cuaderno e historial).
class HistorialTimelineItem extends StatelessWidget {
  final HistorialEntry entry;
  final bool isLast;

  const HistorialTimelineItem({super.key, required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (tipoLabel, icon, color) = entryStyle(entry.tipo);
    final monto = entry.monto;
    final syncColor = entry.isSynced ? AppColors.accent : AppColors.warning;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
                  ),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: AppColors.outlineVariant)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                radius: 18,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 13, color: color),
                              const SizedBox(width: 4),
                              Text(tipoLabel, style: text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        if (entry.hora != '--:--') ...[
                          const SizedBox(width: 8),
                          Text(entry.hora, style: text.labelSmall),
                        ],
                        const Spacer(),
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: syncColor, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(
                          entry.isSynced ? 'Sincronizado' : 'Pendiente',
                          style: text.labelSmall?.copyWith(fontSize: 10, color: syncColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.titulo, style: text.titleSmall),
                              if (entry.descripcion.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(entry.descripcion, style: text.bodySmall),
                              ],
                            ],
                          ),
                        ),
                        if (monto != null && monto > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${entry.tipo == 'gasto' ? '-' : '+'}${formatSoles(monto)}',
                            style: AppTheme.display(fontSize: 14, color: color),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
