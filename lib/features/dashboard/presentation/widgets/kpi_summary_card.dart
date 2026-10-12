import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class KpiSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? data;

  const KpiSummaryCard({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final totalGastos = data?['total_gastos'] as double? ?? 0;
    final totalIngresos = data?['total_ingresos'] as double? ?? 0;
    final balance = data?['balance'] as double? ?? 0;
    final totalActividades = data?['total_actividades'] as int? ?? 0;

    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/', decimalDigits: 2);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen de Campaña',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Icon(
                totalIngresos > totalGastos ? Icons.trending_up : Icons.trending_down,
                color: totalIngresos > totalGastos ? AppColors.primary : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                label: 'Total Gastos',
                value: currencyFormat.format(totalGastos),
                color: AppColors.error,
                bgColor: AppColors.surfaceContainerLow,
                borderColor: AppColors.surfaceVariant,
              ),
              _buildKpiItem(
                context,
                label: 'Total Ingresos',
                value: currencyFormat.format(totalIngresos),
                color: AppColors.primary,
                bgColor: AppColors.surfaceContainerLow,
                borderColor: AppColors.surfaceVariant,
              ),
              _buildKpiItem(
                context,
                label: 'Balance',
                value: currencyFormat.format(balance),
                color: balance >= 0 ? AppColors.onPrimaryContainer : AppColors.error,
                bgColor: balance >= 0 ? AppColors.primaryContainer : AppColors.errorContainer,
                borderColor: balance >= 0 ? AppColors.primaryFixedDim : AppColors.error,
                icon: balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              ),
              _buildKpiItem(
                context,
                label: 'Actividades',
                value: '$totalActividades',
                color: AppColors.onSecondaryContainer,
                bgColor: AppColors.secondaryContainer,
                borderColor: AppColors.secondaryFixedDim,
                icon: Icons.agriculture,
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
                        fontSize: 18,
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
