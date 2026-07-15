import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class KpiSummaryCard extends StatelessWidget {
  const KpiSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen de Campaña',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Icon(
                Icons.trending_up,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // KPI Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildKpiItem(
                context,
                label: 'Total Inversión',
                value: 'S/ 4,520.00',
                color: AppColors.error,
                bgColor: AppColors.surfaceContainerLow,
                borderColor: AppColors.surfaceVariant,
                icon: null,
              ),
              _buildKpiItem(
                context,
                label: 'Total Recaudado',
                value: 'S/ 6,980.00',
                color: AppColors.primary,
                bgColor: AppColors.surfaceContainerLow,
                borderColor: AppColors.surfaceVariant,
                icon: null,
              ),
              _buildKpiItem(
                context,
                label: 'Margen Neto',
                value: 'S/ 2,460.00',
                color: AppColors.onPrimaryContainer,
                bgColor: AppColors.primaryContainer,
                borderColor: AppColors.primaryFixedDim,
                icon: Icons.arrow_upward,
              ),
              _buildKpiItem(
                context,
                label: 'Por Cobrar',
                value: 'S/ 1,150.00',
                color: AppColors.onSecondaryContainer,
                bgColor: AppColors.secondaryContainer,
                borderColor: AppColors.secondaryFixedDim,
                icon: Icons.pending_actions,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontSize: 20,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null)
                Icon(icon, size: 16, color: color),
            ],
          ),
        ],
      ),
    );
  }
}
