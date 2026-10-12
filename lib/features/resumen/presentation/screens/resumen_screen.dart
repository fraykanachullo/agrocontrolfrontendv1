import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../dashboard/presentation/widgets/balance_widget.dart';

class ResumenScreen extends ConsumerWidget {
  final String campaignId;

  const ResumenScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);
    final gastosData = ref.watch(gastosPorCategoriaProvider);
    final campanaId = int.tryParse(campaignId) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen Financiero',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),

          // ── 4 KPI Cards ──
          _buildKpiGrid(context, dashboardData.value),
          const SizedBox(height: 24),

          // ── Gastos por Categoría ──
          _buildGastosPorCategoria(context, gastosData.value),
          const SizedBox(height: 24),

          // ── Balance y Cerrar Campaña ──
          BalanceWidget(campanaId: campanaId),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, Map<String, dynamic>? data) {
    final inversion = data?['total_gastos'] as double? ?? 0;
    final recaudado = data?['total_ingresos'] as double? ?? 0;
    final ganancia = data?['balance'] as double? ?? 0;
    final pendientes = data?['cosechas_pendientes'] as int? ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildKpiCard(
          context,
          label: 'Total Inversión',
          value: 'S/${inversion.toStringAsFixed(0)}',
          icon: Icons.trending_down,
          color: AppColors.error,
        ),
        _buildKpiCard(
          context,
          label: 'Total Recaudado',
          value: 'S/${recaudado.toStringAsFixed(0)}',
          icon: Icons.trending_up,
          color: AppColors.primary,
        ),
        _buildKpiCard(
          context,
          label: 'Ganancia Neta',
          value: 'S/${ganancia.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet,
          color: ganancia >= 0 ? AppColors.statusActive : AppColors.error,
        ),
        _buildKpiCard(
          context,
          label: 'Pendientes Cobro',
          value: '$pendientes envíos',
          icon: Icons.pending_actions,
          color: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  static const _coloresCategoria = <String, Color>{
    'semilla': Color(0xFF4CAF50),
    'fertilizante': Color(0xFF2196F3),
    'mano_obra': Color(0xFFFF9800),
    'maquinaria': Color(0xFF9C27B0),
    'transporte': Color(0xFFE91E63),
    'general': Color(0xFF607D8B),
    'riego': Color(0xFF00BCD4),
    'plaguicida': Color(0xFFFF5722),
    'comision_bancaria': Color(0xFF795548),
    'alimentacion': Color(0xFFCDDC39),
  };

  Color _colorForCategoria(String cat) {
    return _coloresCategoria[cat.toLowerCase()] ??
        _coloresCategoria[cat.replaceAll(' ', '_')] ??
        AppColors.onSurfaceVariant;
  }

  Widget _buildGastosPorCategoria(BuildContext context, List<Map<String, dynamic>>? data) {
    final totalGastos = data?.fold<double>(0, (sum, e) => sum + (e['total'] as num).toDouble()) ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gastos por categoría',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          if (data == null || data.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Registra gastos en el cuaderno para ver\nel desglose por categoría aquí.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
            ...data.map((entry) {
              final categoria = (entry['categoria'] as String?) ?? 'general';
              final monto = (entry['total'] as num).toDouble();
              final cantidad = entry['cantidad'] as int? ?? 0;
              final porcentaje = totalGastos > 0 ? (monto / totalGastos * 100) : 0.0;
              final color = _colorForCategoria(categoria);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            categoria[0].toUpperCase() + categoria.substring(1).replaceAll('_', ' '),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        Text(
                          'S/${monto.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 20),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: porcentaje / 100,
                              backgroundColor: color.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${porcentaje.toStringAsFixed(0)}%  ($cantidad)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
