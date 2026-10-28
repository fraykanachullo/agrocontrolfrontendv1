import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../campanas/presentation/campaign_display.dart';
import '../../../../core/providers/despacho_aviso_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../../planillas/presentation/planilla_routes.dart';
import '../../../planillas/presentation/screens/planillas_screen.dart';
import '../../domain/entities/cosecha.dart';
import '../widgets/sale_sheets.dart';
import 'despacho_screen.dart';

/// Cosechas y ventas (M4): despachos por liquidar, liquidados y ventas en campo.
class CosechasScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const CosechasScreen({super.key, required this.campaignId});

  @override
  ConsumerState<CosechasScreen> createState() => _CosechasScreenState();
}

class _CosechasScreenState extends ConsumerState<CosechasScreen> {
  bool _showPending = true;

  int get _campanaId => int.tryParse(widget.campaignId) ?? 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_reload);
  }

  void _reload() {
    ref.read(cosechasProvider.notifier).loadData(_campanaId);
    ref.read(planillasProvider.notifier).loadData(_campanaId);
  }

  Future<void> _nuevaVenta() async {
    final mode = await showSaleModePicker(context);
    if (mode == null || !mounted) return;
    final campana = ref.read(activeCampanaProvider);
    final nombre = campana?.nombre ?? '';
    switch (mode) {
      case SaleMode.despachoConHoja:
        await openPlanilla(
          context,
          campanaId: _campanaId,
          cultivo: campana?.cultivo ?? 'Tomate',
          numeroHoja: ref.read(planillasProvider).planillas.length + 1,
        );
      case SaleMode.ventaEnCampo:
        await showFieldSaleSheet(context, campanaId: _campanaId, campanaNombre: nombre);
      case SaleMode.despachoLibre:
        await showFreeDispatchSheet(context, campanaId: _campanaId, campanaNombre: nombre);
    }
    if (mounted) _reload();
  }

  Future<void> _abrir(Cosecha c) async {
    await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => DespachoScreen(cosecha: c)));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final cosechas = ref.watch(cosechasProvider);
    final nHojas = ref.watch(planillasProvider).planillas.length;
    final lista = _showPending ? cosechas.pendientes : cosechas.entregadas;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        _Summary(state: cosechas),
        const SizedBox(height: 14),
        if (ref.watch(activeCampanaProvider) case final campana? when campana.isClosed)
          ClosedCampaignNotice(campana: campana)
        else
          AgroActionButton(
            label: 'Nueva venta o despacho',
            icon: Icons.add_circle_rounded,
            primary: true,
            height: 56,
            onPressed: _nuevaVenta,
          ),
        const SizedBox(height: 10),
        GlassCard(
          radius: 18,
          padding: const EdgeInsets.all(12),
          onTap: () async {
            await Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => PlanillasScreen(
                  campaignId: widget.campaignId,
                  cultivo: ref.read(activeCampanaProvider)?.cultivo ?? 'Tomate',
                ),
              ),
            );
            if (mounted) _reload();
          },
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.grid_on_rounded, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hojas de anotación', style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      nHojas == 0 ? 'Aún no hay hojas' : '$nHojas hoja${nHojas == 1 ? '' : 's'} registrada${nHojas == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textSubtle),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _Segment(
                label: 'Por liquidar',
                count: cosechas.pendientes.length,
                selected: _showPending,
                onTap: () => setState(() => _showPending = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Segment(
                label: 'Liquidados',
                count: cosechas.entregadas.length,
                selected: !_showPending,
                onTap: () => setState(() => _showPending = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (cosechas.isLoading && lista.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else if (lista.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(_showPending ? Icons.local_shipping_outlined : Icons.task_alt_rounded, color: AppColors.textSubtle, size: 32),
                const SizedBox(height: 8),
                Text(
                  _showPending ? 'No hay despachos por liquidar' : 'Aún no hay ventas liquidadas',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text('Usa "Nueva venta o despacho"', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          )
        else
          for (final c in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ShipmentCard(cosecha: c, onTap: () => _abrir(c)),
            ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final CosechasState state;

  const _Summary({required this.state});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bultosPendientes = state.pendientes.fold<int>(0, (s, c) => s + c.cantidadUnidades);
    double neto(Iterable<Cosecha> l) => l.fold(0, (s, c) => s + (c.montoNetoFinal ?? 0));
    final cobrado = neto(state.entregadas.where((c) => c.etapa == EtapaDespacho.cobrado));
    final porCobrar = neto(state.entregadas.where((c) => c.etapa == EtapaDespacho.liquidado));
    final bultosVendidos = state.entregadas.fold<int>(0, (s, c) => s + c.cantidadUnidades);

    Widget stat(String label, String value, String caption, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelSmall?.copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: AppTheme.display(fontSize: 22, color: color)),
              ),
              Text(caption, style: text.labelSmall),
            ],
          ),
        );

    return GlassCard(
      highlight: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          stat(
            'POR LIQUIDAR',
            '${state.pendientes.length}',
            '${NumberFormat('#,##0', 'es_419').format(bultosPendientes)} bultos sin liquidar',
            state.pendientes.isEmpty ? AppColors.text : AppColors.warning,
          ),
          Container(width: 1, height: 52, margin: const EdgeInsets.symmetric(horizontal: 14), color: AppColors.outlineVariant),
          stat(
            'COBRADO',
            formatSoles(cobrado),
            porCobrar > 0
                ? '${formatSoles(porCobrar)} por cobrar'
                : '${NumberFormat('#,##0', 'es_419').format(bultosVendidos)} bultos vendidos',
            AppColors.positive,
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.14) : AppColors.accentSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.accent : AppColors.cardBorder),
        ),
        child: Text(
          '$label ($count)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.accent : AppColors.textMuted,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _ShipmentCard extends ConsumerWidget {
  final Cosecha cosecha;
  final VoidCallback onTap;

  const _ShipmentCard({required this.cosecha, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final c = cosecha;
    final enCampo = c.enCampo;
    final fecha = DateTime.tryParse(c.fechaEnvio ?? '');
    final pendiente = !c.isLiquidado;
    final dias = c.diasSinNoticias;
    final demorado = c.demorado(ref.watch(diasAvisoDespachoProvider));
    final color = enCampo ? AppColors.positive : (pendiente ? AppColors.warning : AppColors.accent);
    final envase = c.unidadEmpaque ?? 'bulto';

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
            child: Icon(enCampo ? Icons.scale_rounded : Icons.local_shipping_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enCampo
                      ? 'Venta en campo${c.conductor.isEmpty ? '' : ' · ${c.conductor}'}'
                      : 'Despacho a ${c.mercadoDestino}',
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (fecha != null) DateFormat('EEE d MMM', 'es').format(fecha),
                    '${c.cantidadUnidades} ${envase}s',
                    if (c.detalles.isNotEmpty) 'con hoja',
                  ].join(' · '),
                  style: text.bodySmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ShipmentStatusPill(cosecha: c),
                    if (dias != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '$dias día${dias == 1 ? '' : 's'} sin llegar',
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(color: demorado ? AppColors.error : AppColors.textSubtle),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!pendiente && c.montoNetoFinal != null)
            Text(
              formatSoles(c.montoNetoFinal!),
              style: AppTheme.display(
                fontSize: 15,
                color: c.etapa == EtapaDespacho.cobrado ? AppColors.positive : AppColors.warning,
              ),
            )
          else
            Icon(Icons.chevron_right_rounded, color: AppColors.textSubtle),
        ],
      ),
    );
  }
}
