import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/despacho_aviso_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../../cosechas/domain/entities/cosecha.dart';
import '../../../cuaderno/presentation/widgets/expense_sheet.dart';
import '../../../cuaderno/presentation/widgets/record_sheets.dart';
import '../../domain/entities/campana.dart';
import '../campaign_actions.dart';
import '../campaign_display.dart';
import '../widgets/campaign_tile.dart';

// es_419: miles con coma y decimales con punto (S/ 48,320.20), como se usa en Perú.
final _amount = NumberFormat('#,##0.00', 'es_419');
final _count = NumberFormat('#,##0', 'es_419');

/// Atajos de registro rápido: las categorías de gasto más frecuentes en campo.
const _quickExpenses = <(IconData, String, String)>[
  (Icons.groups_rounded, 'Cuadrilla', 'Mano de obra'),
  (Icons.pest_control_rounded, 'Fumigación', 'Fitosanitarios'),
  (Icons.grass_rounded, 'Abonos', 'Fertilizantes'),
  (Icons.water_drop_rounded, 'Riego', 'Riego'),
  (Icons.agriculture_rounded, 'Maquinaria', 'Maquinaria'),
  (Icons.inventory_2_rounded, 'Envases', 'Envases'),
  (Icons.spa_rounded, 'Semilla', 'Semilla / plantín'),
  (Icons.more_horiz_rounded, 'Otro', 'Otros'),
];

/// Formatea un monto con signo: "+S/ 1,200.00" / "-S/ 1,200.00".
String signedAmount(double value) => '${value < 0 ? '-' : '+'}S/ ${_amount.format(value.abs())}';

class InicioScreen extends ConsumerStatefulWidget {
  const InicioScreen({super.key});

  @override
  ConsumerState<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends ConsumerState<InicioScreen> {
  @override
  void initState() {
    super.initState();
    final state = ref.read(campanaListProvider);
    if (state.campanas.isEmpty && !state.isLoading) {
      Future.microtask(() => ref.read(campanaListProvider.notifier).loadCampanas());
    }
    final campanaId = ref.read(activeCampanaIdProvider);
    if (campanaId != null) {
      Future.microtask(() => ref.read(cosechasProvider.notifier).loadData(campanaId));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cargar cosechas de la campaña activa (etapa, despachos por liquidar).
    ref.listen(activeCampanaIdProvider, (_, id) {
      if (id != null) ref.read(cosechasProvider.notifier).loadData(id);
    });

    final campana = ref.watch(activeCampanaProvider);
    if (campana == null) return _NoCampaignView(state: ref.watch(campanaListProvider));

    final data = ref.watch(dashboardDataProvider).value;
    final cosechas = ref.watch(cosechasProvider);
    final stage = CampaignStage.of(
      campana,
      hasHarvests: cosechas.pendientes.isNotEmpty || cosechas.entregadas.isNotEmpty,
    );

    return ListView(
      // El contenido pasa por detrás de la barra flotante sin quedar tapado al final.
      padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        _Greeting(campana: campana),
        const SizedBox(height: 14),
        _CampaignChip(campana: campana, stage: stage, onTap: () => _showCampaignSwitcher(campana)),
        const SizedBox(height: 16),
        _BalanceCard(data: data, campana: campana, stage: stage, soldUnits: _soldUnits(cosechas.entregadas)),
        const SizedBox(height: 24),
        SectionHeader(title: 'Acciones rápidas', actionLabel: 'Más', onAction: () => _showMoreActions(campana)),
        if (campana.isClosed)
          ClosedCampaignNotice(campana: campana)
        else ...[
          AgroActionButton(
            label: 'Registrar gasto o jornal',
            icon: Icons.add_circle_rounded,
            primary: true,
            height: 56,
            onPressed: () => _openForm(campana, 'Gasto'),
          ),
          const SizedBox(height: 10),
          AgroActionButton(
            label: 'Registrar despacho o venta',
            icon: Icons.local_shipping_rounded,
            height: 54,
            onPressed: () => context.go('/c/${campana.id}/cosechas'),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Registro rápido de gastos'),
          _QuickExpenseGrid(onSelected: (categoria) => _openForm(campana, 'Gasto', categoria: categoria)),
        ],
        const SizedBox(height: 24),
        _PendingShipments(
          campanaId: campana.id,
          pendientes: cosechas.pendientes,
          diasAviso: ref.watch(diasAvisoDespachoProvider),
        ),
        _TodayMovements(campanaId: campana.id),
      ],
    );
  }

  static int _soldUnits(List<Cosecha> entregadas) =>
      entregadas.fold<int>(0, (sum, c) => sum + c.cantidadUnidades);

  // ── Acciones ──

  void _openForm(Campana campana, String type, {String? categoria}) {
    final (id, nombre) = (campana.id, campana.nombre);
    switch (type) {
      case 'Gasto':
        showExpenseSheet(context, campanaId: id, campanaNombre: nombre, categoria: categoria);
      case 'Ingreso':
        showIncomeSheet(context, campanaId: id, campanaNombre: nombre);
      default:
        showLaborSheet(context, campanaId: id, campanaNombre: nombre);
    }
  }

  void _showCampaignSwitcher(Campana current) {
    final campanas = ref.read(campanaListProvider).campanas;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true, // encima de la barra inferior de las pestañas
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('Cambiar campaña', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 14),
          for (final c in campanas)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                highlight: c.id == current.id,
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.read(activeCampanaIdProvider.notifier).state = c.id;
                  context.go('/c/${c.id}/inicio');
                },
                child: Row(
                  children: [
                    Text(cropEmoji(c.cultivo), style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.nombre, style: Theme.of(ctx).textTheme.titleSmall),
                          Text('${c.cultivo} · ${c.extensionDisplay}', style: Theme.of(ctx).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (c.id == current.id) Icon(Icons.check_circle_rounded, color: AppColors.accent),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/nueva-campana');
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nueva campaña'),
          ),
        ],
      ),
    );
  }

  void _showMoreActions(Campana campana) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true, // encima de la barra inferior de las pestañas
      builder: (ctx) {
        Widget action(IconData icon, String label, VoidCallback onTap, {Color? color}) => ListTile(
              leading: Icon(icon, color: color ?? AppColors.accent),
              title: Text(label, style: TextStyle(color: color ?? AppColors.text, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(ctx).pop();
                onTap();
              },
            );

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!campana.isClosed) ...[
                action(Icons.north_east_rounded, 'Registrar ingreso directo', () => _openForm(campana, 'Ingreso')),
                action(Icons.agriculture_rounded, 'Registrar labor', () => _openForm(campana, 'Actividad')),
              ],
              action(Icons.calendar_month_rounded, 'Ver historial', () => context.push('/c/${campana.id}/historial')),
              action(Icons.add_circle_outline_rounded, 'Nueva campaña', () => context.push('/nueva-campana')),
              if (campana.isActive)
                action(Icons.lock_outline_rounded, 'Cerrar campaña', () => closeCampanaFlow(context, ref, campana),
                    color: AppColors.error),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
//  Secciones
// ═══════════════════════════════════════════════

class _Greeting extends ConsumerWidget {
  final Campana campana;

  const _Greeting({required this.campana});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final name = ref.watch(authProvider).user?.nombreCompleto ?? 'Agricultor';
    final dias = campana.fechaInicio == null ? null : DateTime.now().difference(campana.fechaInicio!).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wb_sunny_outlined, size: 15, color: AppColors.accent),
            const SizedBox(width: 5),
            Text(_greeting, style: text.bodySmall),
          ],
        ),
        const SizedBox(height: 2),
        Text(name, style: text.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(
          [campana.extensionDisplay, if (dias != null) '$dias días de campaña'].join(' · '),
          style: text.bodySmall?.copyWith(color: AppColors.textSubtle),
        ),
      ],
    );
  }
}

class _CampaignChip extends StatelessWidget {
  final Campana campana;
  final CampaignStage stage;
  final VoidCallback onTap;

  const _CampaignChip({required this.campana, required this.stage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final year = campana.fechaInicio?.year;

    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          Text(cropEmoji(campana.cultivo), style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(campana.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
                Text(
                  '${campana.cultivo}${year != null ? ' · Campaña $year' : ''}',
                  style: text.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StagePill(stage: stage),
          const SizedBox(width: 4),
          Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.textSubtle),
        ],
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  final CampaignStage stage;

  const _StagePill({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stage.icon, size: 13, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            stage.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta principal: balance, rentabilidad, etapa y desglose ingresos/gastos.
class _BalanceCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Campana campana;
  final CampaignStage stage;
  final int soldUnits;

  const _BalanceCard({required this.data, required this.campana, required this.stage, required this.soldUnits});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final balance = (data?['balance'] as double?) ?? 0;
    final gastos = (data?['total_gastos'] as double?) ?? 0;
    final ingresos = (data?['total_ingresos'] as double?) ?? 0;
    final positive = balance >= 0;

    // "S/ 48,320.20" → parte entera destacada y decimales atenuados.
    final formatted = _amount.format(balance.abs());
    final dot = formatted.lastIndexOf('.');

    return GlassCard(
      highlight: true,
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'BALANCE DE CAMPAÑA',
                  style: text.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700),
                ),
              ),
              GlassCircleButton(
                icon: Icons.info_outline_rounded,
                tooltip: 'Cómo se calcula',
                size: 32,
                onPressed: () => _explain(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${positive ? '' : '-'}S/ ',
                  style: AppTheme.display(fontSize: 20, color: AppColors.textMuted),
                ),
                TextSpan(text: formatted.substring(0, dot)),
                TextSpan(
                  text: formatted.substring(dot),
                  style: AppTheme.display(fontSize: 20, color: AppColors.textMuted),
                ),
              ],
            ),
            style: AppTheme.display(fontSize: 34, color: positive ? AppColors.text : AppColors.expense),
          ),
          if (gastos > 0) ...[
            const SizedBox(height: 8),
            _ProfitBadge(rate: balance / gastos * 100),
          ],
          const SizedBox(height: 14),
          _StageProgress(stage: stage, campana: campana),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.south_west_rounded,
                  label: 'Ingresos',
                  value: 'S/ ${_amount.format(ingresos)}',
                  color: AppColors.positive,
                  caption: soldUnits > 0 ? '${_count.format(soldUnits)} bultos vendidos' : 'Ventas y cobros',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  icon: Icons.north_east_rounded,
                  label: 'Gastos',
                  value: 'S/ ${_amount.format(gastos)}',
                  color: AppColors.expense,
                  caption: 'Inversión total',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _explain(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cómo se calcula?'),
        content: const Text(
          'Balance = ingresos − gastos.\n\n'
          'Ingresos: ventas en campo, ingresos directos y despachos ya liquidados (neto, después de comisión y flete).\n\n'
          'Rentabilidad = balance ÷ gastos. Indica cuánto ganaste por cada sol invertido.',
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Entendido'))],
      ),
    );
  }
}

class _ProfitBadge extends StatelessWidget {
  final double rate;

  const _ProfitBadge({required this.rate});

  @override
  Widget build(BuildContext context) {
    final positive = rate >= 0;
    final color = positive ? AppColors.positive : AppColors.expense;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            '${positive ? '+' : ''}${rate.toStringAsFixed(1)}% de rentabilidad',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Barra segmentada de la etapa de la campaña.
class _StageProgress extends StatelessWidget {
  final CampaignStage stage;
  final Campana campana;

  const _StageProgress({required this.stage, required this.campana});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final current = stage.index;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.track.withValues(alpha: AppColors.palette.isDark ? 0.25 : 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Etapa: ${stage.label}',
                  style: text.labelMedium?.copyWith(color: AppColors.text, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                switch (campana.diasDesdeSiembra) {
                  _ when campana.isClosed => 'Campaña cerrada',
                  final int dias => 'Día $dias desde la siembra',
                  null => 'Aún sin sembrar',
                },
                style: text.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final s in CampaignStage.values) ...[
                if (s.index > 0) const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      gradient: s.index <= current ? AppColors.progressGradient : null,
                      color: s.index <= current ? null : AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final s in CampaignStage.values)
                Expanded(
                  child: Text(
                    s.label,
                    textAlign: switch (s.index) {
                      0 => TextAlign.start,
                      3 => TextAlign.end,
                      _ => TextAlign.center,
                    },
                    style: text.labelSmall?.copyWith(
                      fontSize: 10,
                      color: s == stage ? AppColors.accent : AppColors.textSubtle,
                      fontWeight: s == stage ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (!campana.isSown && !campana.isClosed) ...[
            const SizedBox(height: 10),
            AgroActionButton(
              label: '¿Ya sembraste? Registrar siembra',
              icon: Icons.spa_rounded,
              height: 44,
              onPressed: () => showLaborSheet(
                context,
                campanaId: campana.id,
                campanaNombre: campana.nombre,
                initialType: kSiembraLabor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(label, style: text.labelMedium),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTheme.display(fontSize: 16, color: color)),
          ),
          const SizedBox(height: 2),
          Text(caption, style: text.labelSmall?.copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _QuickExpenseGrid extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const _QuickExpenseGrid({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        for (final (icon, label, categoria) in _quickExpenses)
          GlassCard(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            onTap: () => onSelected(categoria),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 19, color: AppColors.accent),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.text),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Despachos enviados que aún esperan la liquidación del mercado.
class _PendingShipments extends StatelessWidget {
  final int campanaId;
  final List<Cosecha> pendientes;
  final int diasAviso;

  const _PendingShipments({required this.campanaId, required this.pendientes, required this.diasAviso});

  @override
  Widget build(BuildContext context) {
    if (pendientes.isEmpty) return const SizedBox.shrink();

    final text = Theme.of(context).textTheme;
    final first = pendientes.first;
    final bultos = pendientes.fold<int>(0, (sum, c) => sum + c.cantidadUnidades);
    // El despacho que más tiempo lleva sin llegar al mercado.
    final dias = pendientes.map((c) => c.diasSinNoticias).nonNulls.fold<int?>(null, (m, d) => m == null || d > m ? d : m);
    final demorados = pendientes.where((c) => c.demorado(diasAviso)).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          SectionHeader(
            title: 'Por liquidar',
            actionLabel: 'Ver cosechas',
            onAction: () => context.go('/c/$campanaId/cosechas'),
          ),
          GlassCard(
            highlight: true,
            radius: 24,
            padding: const EdgeInsets.all(16),
            onTap: () => context.go('/c/$campanaId/cosechas'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.storefront_outlined, color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            first.mercadoDestino.isEmpty ? 'Despacho' : 'Despacho a ${first.mercadoDestino}',
                            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            demorados > 0
                                ? '$demorados demorado${demorados == 1 ? '' : 's'}: llama al comisionista'
                                : (pendientes.length == 1
                                    ? 'Esperando liquidación del mercado'
                                    : '${pendientes.length} despachos esperando liquidación'),
                            style: text.bodySmall?.copyWith(color: demorados > 0 ? AppColors.error : null),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSubtle),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _Metric(label: 'Despachos', value: '${pendientes.length}')),
                    Expanded(child: _Metric(label: 'Bultos enviados', value: _count.format(bultos))),
                    Expanded(
                      child: _Metric(
                        label: 'Sin llegar',
                        value: dias == null ? '—' : '$dias día${dias == 1 ? '' : 's'}',
                        highlight: demorados > 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _Metric({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: AppTheme.display(fontSize: 15, color: highlight ? AppColors.warning : AppColors.text)),
      ],
    );
  }
}

class _TodayMovements extends ConsumerWidget {
  final int campanaId;

  const _TodayMovements({required this.campanaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final entries = ref.watch(historialDayProvider((campanaId, DateTime(now.year, now.month, now.day))));

    return Column(
      children: [
        SectionHeader(
          title: 'Movimientos de hoy',
          actionLabel: 'Ver todos',
          onAction: () => context.push('/c/$campanaId/historial'),
        ),
        entries.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e', style: TextStyle(color: AppColors.error)),
          data: (list) => list.isEmpty
              ? GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.event_available_rounded, color: AppColors.textSubtle, size: 32),
                      const SizedBox(height: 8),
                      Text('Sin movimientos hoy', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 2),
                      Text('Registra un gasto o usa un atajo de arriba', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final e in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MovementTile(entry: e),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Fila de movimiento: icono por tipo, título, hora/descripción, estado de
/// sincronización y monto con signo.
class MovementTile extends StatelessWidget {
  final HistorialEntry entry;

  const MovementTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (icon, color) = switch (entry.tipo) {
      'gasto' => (Icons.payments_outlined, AppColors.expense),
      'ingreso' => (Icons.savings_outlined, AppColors.positive),
      'cosecha' => (Icons.local_shipping_outlined, AppColors.warning),
      'incidencia' => (Icons.report_outlined, AppColors.error),
      _ => (Icons.agriculture_outlined, AppColors.info),
    };
    final monto = entry.monto;
    final syncColor = entry.isSynced ? AppColors.accent : AppColors.warning;

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
                Text(
                  [if (entry.hora != '--:--') entry.hora, entry.descripcion].where((s) => s.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: syncColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(
                      entry.isSynced ? 'Sincronizado' : 'Pendiente de subida',
                      style: text.labelSmall?.copyWith(fontSize: 10, color: syncColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (monto != null && monto > 0) ...[
            const SizedBox(width: 8),
            Text(
              signedAmount(entry.tipo == 'ingreso' ? monto : -monto),
              style: AppTheme.display(
                fontSize: 14,
                color: entry.tipo == 'ingreso' ? AppColors.positive : AppColors.expense,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoCampaignView extends ConsumerWidget {
  final CampanaListState state;

  const _NoCampaignView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        Text('Elige una campaña', style: text.headlineSmall),
        const SizedBox(height: 4),
        Text('Selecciona la campaña que quieres administrar', style: text.bodySmall),
        const SizedBox(height: 20),
        AgroActionButton(
          label: 'Nueva campaña',
          icon: Icons.add_rounded,
          primary: true,
          onPressed: () => context.push('/nueva-campana'),
        ),
        const SizedBox(height: 20),
        if (state.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (state.campanas.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Text('🌱', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 12),
                Text('Aún no tienes campañas', style: text.titleMedium),
                const SizedBox(height: 4),
                Text('Crea la primera para empezar a registrar', style: text.bodySmall),
              ],
            ),
          )
        else
          for (final c in state.campanas)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CampaignTile(
                campana: c,
                resumen: ref.watch(campanaResumenesProvider).value?[c.id],
                onTap: () => ref.read(activeCampanaIdProvider.notifier).state = c.id,
              ),
            ),
      ],
    );
  }
}
