import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';

class TimelineWidget extends ConsumerWidget {
  final String campaignId;
  final DateTime selectedDate;

  const TimelineWidget({super.key, required this.campaignId, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campanaId = int.tryParse(campaignId) ?? 0;
    final dateParam = (campanaId, selectedDate);
    final entriesAsync = ref.watch(historialDayProvider(dateParam));
    final dateLabel = DateFormat('d \'de\' MMMM, yyyy', 'es').format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 16),

        entriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (entries) {
            if (entries.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_available, size: 48, color: AppColors.outlineVariant),
                    const SizedBox(height: 12),
                    Text(
                      'Sin registros este día',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    child: Column(
                      children: entries.asMap().entries.map((entry) {
                        final isLast = entry.key == entries.length - 1;
                        return [
                          _buildTimelineDot(context, entry.value.tipo),
                          if (!isLast) _buildTimelineLine(),
                        ];
                      }).expand((e) => e).toList(),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: entries.asMap().entries.map((entry) {
                        final e = entry.value;
                        final isLast = entry.key == entries.length - 1;
                        return Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                          child: _buildTimelineItem(context, e),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineDot(BuildContext context, String tipo) {
    IconData icon;
    Color color;
    Color iconColor;

    switch (tipo) {
      case 'actividad':
        icon = Icons.science;
        color = AppColors.primaryContainer;
        iconColor = AppColors.onPrimaryContainer;
        break;
      case 'gasto':
        icon = Icons.payments;
        color = AppColors.errorContainer;
        iconColor = AppColors.onErrorContainer;
        break;
      case 'ingreso':
        icon = Icons.trending_up;
        color = AppColors.primaryContainer;
        iconColor = AppColors.onPrimaryContainer;
        break;
      case 'cosecha':
        icon = Icons.local_shipping;
        color = AppColors.secondaryContainer;
        iconColor = AppColors.onSecondaryContainer;
        break;
      default:
        icon = Icons.circle;
        color = AppColors.surfaceContainerHigh;
        iconColor = AppColors.onSurfaceVariant;
    }

    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: AppColors.surfaceContainerLowest, width: 2)),
      child: Icon(icon, size: 14, color: iconColor),
    );
  }

  Widget _buildTimelineLine() {
    return Expanded(child: Container(width: 2, color: AppColors.surfaceVariant));
  }

  Widget _buildTimelineItem(BuildContext context, HistorialEntry e) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(e.hora, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceVariant),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.titulo, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text(e.descripcion, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (e.monto != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'S/${e.monto!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: e.tipo == 'gasto' ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: e.isSynced ? AppColors.primary.withValues(alpha: 0.1) : AppColors.statusPending.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.isSynced ? Icons.cloud_done : Icons.cloud_off, size: 14, color: e.isSynced ? AppColors.primary : AppColors.secondary),
                      const SizedBox(width: 6),
                      Text(
                        e.isSynced ? 'Sincronizado' : 'Offline',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: e.isSynced ? AppColors.primary : AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
