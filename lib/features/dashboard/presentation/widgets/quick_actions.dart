import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PDF Report Button
        _buildActionCard(
          context,
          icon: Icons.picture_as_pdf,
          iconBg: AppColors.surfaceVariant,
          iconColor: AppColors.onSurfaceVariant,
          title: 'Generar Reporte PDF',
          subtitle: 'Resumen financiero y de campo',
          trailing: Icons.chevron_right,
          bgColor: AppColors.surfaceContainerLowest,
          onTap: () {},
        ),
        const SizedBox(height: 12),

        // Premium Sync Button
        _buildActionCard(
          context,
          icon: Icons.cloud_sync,
          iconBg: AppColors.secondaryFixed,
          iconColor: AppColors.onSecondaryFixed,
          title: 'Premium - Activar Sincronización',
          subtitle: 'Respaldo en tiempo real',
          trailing: Icons.workspace_premium,
          bgColor: AppColors.secondaryContainer,
          titleColor: AppColors.onSecondaryContainer,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required IconData trailing,
    required Color bgColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: titleColor,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: titleColor?.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
              // Trailing icon
              Icon(
                trailing,
                color: titleColor ?? AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
