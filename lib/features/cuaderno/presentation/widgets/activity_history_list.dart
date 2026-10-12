import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';

class ActivityHistoryList extends ConsumerWidget {
  final int campanaId;

  const ActivityHistoryList({super.key, required this.campanaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuaderno = ref.watch(cuadernoProvider);

    if (cuaderno.isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ));
    }

    final allItems = <_HistoryItem>[];

    for (final a in cuaderno.actividades) {
      allItems.add(_HistoryItem(
        icon: Icons.agriculture,
        iconBg: AppColors.primaryContainer.withValues(alpha: 0.2),
        iconColor: AppColors.primary,
        title: a.descripcion,
        subtitle: _formatDate(a.fecha),
        trailing: Text(
          'Actividad',
          style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ));
    }

    for (final t in cuaderno.transaccionesGasto) {
      allItems.add(_HistoryItem(
        icon: Icons.attach_money,
        iconBg: AppColors.errorContainer.withValues(alpha: 0.5),
        iconColor: AppColors.onErrorContainer,
        title: 'Gasto: ${t.descripcion}',
        subtitle: '${_formatDate(t.fecha)} - ${t.categoria}',
        trailing: Text(
          'S/${t.monto.toStringAsFixed(2)}',
          style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ));
    }

    for (final t in cuaderno.transaccionesIngreso) {
      allItems.add(_HistoryItem(
        icon: Icons.trending_up,
        iconBg: AppColors.primaryContainer.withValues(alpha: 0.3),
        iconColor: AppColors.primary,
        title: 'Ingreso: ${t.descripcion}',
        subtitle: '${_formatDate(t.fecha)} - ${t.categoria}',
        trailing: Text(
          'S/${t.monto.toStringAsFixed(2)}',
          style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ));
    }

    if (allItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.note_add_outlined, size: 48, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'Sin registros hoy',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Últimos registros',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
            children: allItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isLast = idx == allItems.length - 1;
              return _buildHistoryItem(context, item, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? fecha) {
    if (fecha == null || fecha.isEmpty) return '--';
    try {
      final dt = DateTime.parse(fecha);
      return DateFormat('dd/MM HH:mm').format(dt);
    } catch (_) {
      return fecha.substring(0, fecha.length > 16 ? 16 : fecha.length);
    }
  }

  Widget _buildHistoryItem(BuildContext context, _HistoryItem item, bool isLast) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHigh)),
            ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: item.iconBg, shape: BoxShape.circle),
            child: Icon(item.icon, size: 20, color: item.iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          item.trailing,
        ],
      ),
    );
  }
}

class _HistoryItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _HistoryItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
}
