import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ActivityHistoryList extends StatelessWidget {
  const ActivityHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Historial de hoy',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
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
            children: [
              _buildHistoryItem(
                context,
                icon: Icons.agriculture,
                iconBg: AppColors.primaryContainer.withValues(alpha: 0.2),
                iconColor: AppColors.primary,
                title: 'Fumigación norte',
                subtitle: '08:00 AM',
                trailing: IconButton(
                  icon: const Icon(Icons.photo_camera, size: 20),
                  onPressed: () {},
                  color: AppColors.outlineVariant,
                ),
              ),
              _buildHistoryItem(
                context,
                icon: Icons.attach_money,
                iconBg: AppColors.errorContainer.withValues(alpha: 0.5),
                iconColor: AppColors.onErrorContainer,
                title: 'Gasto: Combustible',
                subtitle: '11:30 AM',
                trailing: Text(
                  'S/450.00',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceContainerHigh),
              ),
            ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          // Trailing
          trailing,
        ],
      ),
    );
  }
}
