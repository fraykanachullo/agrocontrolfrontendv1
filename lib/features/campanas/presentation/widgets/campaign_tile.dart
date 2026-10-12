import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/campana.dart';
import '../campaign_display.dart';

/// Tarjeta de campaña para listados: cultivo, etapa, área, días y su resultado
/// (utilidad si ya hay ventas, inversión si todavía no).
class CampaignTile extends StatelessWidget {
  final Campana campana;
  final CampanaResumen? resumen;
  final VoidCallback onTap;

  const CampaignTile({super.key, required this.campana, required this.resumen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = resumen;
    final stage = CampaignStage.of(
      campana,
      hasHarvests: (r?.cosechas ?? 0) > 0,
      hasRecords: (r?.gastos ?? 0) > 0,
    );
    final dias = campana.fechaInicio == null ? null : DateTime.now().difference(campana.fechaInicio!).inDays;
    final conVentas = (r?.ingresos ?? 0) > 0;

    return Opacity(
      opacity: campana.isClosed ? 0.92 : 1,
      child: GlassCard(
        radius: 22,
        highlight: campana.isActive && stage == CampaignStage.cosecha,
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(16)),
                  child: Text(cropEmoji(campana.cultivo), style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(campana.nombre, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(campana.cultivo, style: text.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StagePill(campana: campana, stage: stage),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.straighten_rounded, size: 16, color: AppColors.textSubtle),
                const SizedBox(width: 5),
                Text(campana.extensionDisplay, style: text.bodySmall),
                const Spacer(),
                Icon(campana.isClosed ? Icons.event_available_rounded : Icons.calendar_month_rounded, size: 16, color: AppColors.accent),
                const SizedBox(width: 5),
                Text(
                  campana.isClosed
                      ? (campana.fechaCierre == null ? 'Cerrada' : 'Cerrada ${DateFormat('MMM yyyy', 'es').format(campana.fechaCierre!)}')
                      : (dias == null ? 'Sin fecha de inicio' : '$dias días de campaña'),
                  style: text.bodySmall?.copyWith(color: AppColors.text),
                ),
              ],
            ),
            const Divider(height: 26),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            campana.isClosed ? 'Utilidad final' : (conVentas ? 'Utilidad actual' : 'Inversión acumulada'),
                            style: text.labelMedium,
                          ),
                          if (conVentas && r?.rentabilidad != null) ...[
                            const SizedBox(width: 6),
                            _Badge(rate: r!.rentabilidad!),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r == null
                            ? '—'
                            : conVentas
                                ? '${r.utilidad < 0 ? '-' : '+'}${formatSoles(r.utilidad.abs())}'
                                : '-${formatSoles(r.gastos)}',
                        style: AppTheme.display(
                          fontSize: 22,
                          color: conVentas
                              ? (r!.utilidad < 0 ? AppColors.expense : AppColors.positive)
                              : AppColors.expense,
                        ),
                      ),
                      if ((r?.porLiquidar ?? 0) > 0)
                        Text(
                          '${r!.porLiquidar} despacho${r.porLiquidar == 1 ? '' : 's'} por liquidar',
                          style: text.labelSmall?.copyWith(color: AppColors.warning),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: campana.isActive ? AppColors.ctaGradient : null,
                    color: campana.isActive ? null : AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: campana.isActive
                        ? [BoxShadow(color: AppColors.palette.ctaGlow, blurRadius: 16, spreadRadius: -4)]
                        : null,
                  ),
                  child: Icon(
                    campana.isActive ? Icons.arrow_forward_rounded : Icons.receipt_long_rounded,
                    color: campana.isActive ? AppColors.onAccent : AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  final Campana campana;
  final CampaignStage stage;

  const _StagePill({required this.campana, required this.stage});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (stage) {
      CampaignStage.cierre => ('Cerrada', AppColors.textMuted),
      CampaignStage.cosecha => ('En cosecha', AppColors.accent),
      CampaignStage.crecimiento => ('En desarrollo', AppColors.info),
      CampaignStage.inicio => ('Por empezar', AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stage == CampaignStage.cierre ? Icons.lock_outline_rounded : stage.icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final double rate;

  const _Badge({required this.rate});

  @override
  Widget build(BuildContext context) {
    final color = rate >= 0 ? AppColors.positive : AppColors.expense;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6)),
      child: Text(
        '${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(1)}%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
