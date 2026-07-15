import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CampaignCard extends StatelessWidget {
  final String title;
  final String startDate;
  final bool isActive;
  final IconData icon;
  final VoidCallback onTap;

  const CampaignCard({
    super.key,
    required this.title,
    required this.startDate,
    required this.isActive,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? AppColors.surfaceContainerLowest
          : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      elevation: isActive ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.surfaceContainer
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isActive ? AppColors.primary : AppColors.statusClosed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 28 / 20,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          startDate,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(context),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.statusActive.withValues(alpha: 0.1)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? AppColors.statusActive.withValues(alpha: 0.3)
              : AppColors.surfaceContainerHighest,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.statusActive : AppColors.statusClosed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Activa' : 'Cerrada',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color:
                      isActive ? AppColors.statusActive : AppColors.statusClosed,
                ),
          ),
        ],
      ),
    );
  }
}
