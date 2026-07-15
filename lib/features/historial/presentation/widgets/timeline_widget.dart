import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TimelineWidget extends StatelessWidget {
  const TimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '16 de Julio, 2026',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 16),

        // Timeline
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line + dots
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    _buildTimelineDot(
                      context,
                      icon: Icons.science,
                      color: AppColors.primaryContainer,
                      iconColor: AppColors.onPrimaryContainer,
                    ),
                    _buildTimelineLine(),
                    _buildTimelineDot(
                      context,
                      icon: Icons.payments,
                      color: AppColors.secondaryContainer,
                      iconColor: AppColors.onSecondaryContainer,
                    ),
                    _buildTimelineLine(),
                    _buildTimelineDot(
                      context,
                      icon: Icons.local_shipping,
                      color: AppColors.errorContainer,
                      iconColor: AppColors.onErrorContainer,
                    ),
                  ],
                ),
              ),

              // Timeline content
              Expanded(
                child: Column(
                  children: [
                    _buildTimelineItem(
                      context,
                      time: '08:00',
                      title: 'Actividad: Fumigación',
                      subtitle: 'Lote Sur - Aplicación foliar',
                      status: 'Sincronizado',
                      statusIcon: Icons.cloud_done,
                      statusColor: AppColors.primary,
                      statusBg: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineItem(
                      context,
                      time: '11:30',
                      title: 'Gasto: S/ 450.00',
                      subtitle: 'Insumos - Fertilizantes NPK',
                      status: 'Pendiente sincronizar',
                      statusIcon: Icons.cloud_sync,
                      statusColor: AppColors.secondary,
                      statusBg: AppColors.statusPending.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineItem(
                      context,
                      time: '15:00',
                      title: 'Envío: 120 javas',
                      subtitle: 'Destino: Lima Mayorista',
                      status: 'Pendiente liquidación',
                      statusIcon: Icons.warning,
                      statusColor: AppColors.error,
                      statusBg: AppColors.error.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDot(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.surfaceContainerLowest,
          width: 2,
        ),
      ),
      child: Icon(icon, size: 14, color: iconColor),
    );
  }

  Widget _buildTimelineLine() {
    return Expanded(
      child: Container(
        width: 2,
        color: AppColors.surfaceVariant,
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required String time,
    required String title,
    required String subtitle,
    required String status,
    required IconData statusIcon,
    required Color statusColor,
    required Color statusBg,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time
        SizedBox(
          width: 48,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              time,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Content card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),

                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                ),
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
