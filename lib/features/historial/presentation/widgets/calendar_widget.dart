import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CalendarWidget extends StatelessWidget {
  const CalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {},
                color: AppColors.onSurfaceVariant,
              ),
              Text(
                'Julio 2026',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {},
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Day labels
          Row(
            children: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']
                .map((day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid (simplified - one week)
          _buildWeekRow(context, [14, 15, 16, 17, 18, 19, 20], 16),
        ],
      ),
    );
  }

  Widget _buildWeekRow(
      BuildContext context, List<int> days, int selectedDay) {
    return Row(
      children: days.map((day) {
        final isSelected = day == selectedDay;
        final isWeekend = day == 19 || day == 20;

        return Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : null,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppColors.onPrimary
                          : isWeekend
                              ? AppColors.onSurfaceVariant.withValues(alpha: 0.5)
                              : AppColors.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
