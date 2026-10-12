import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarWidget({super.key, required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final year = selectedDate.year;
    final month = selectedDate.month;
    final monthName = DateFormat('MMMM yyyy', 'es').format(selectedDate);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;

    final days = <int>[];
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(i);
    }

    final leadingBlanks = (firstWeekday - 1) % 7;
    final paddedDays = List<int>.filled(leadingBlanks, 0) + days;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onDateSelected(DateTime(year, month - 1, selectedDate.day)),
                color: AppColors.onSurfaceVariant,
              ),
              Text(
                '${monthName[0].toUpperCase()}${monthName.substring(1)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onDateSelected(DateTime(year, month + 1, selectedDate.day)),
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']
                .map((day) => Expanded(
                      child: Text(day, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          ...List.generate((paddedDays.length / 7).ceil(), (weekIdx) {
            final start = weekIdx * 7;
            final end = (start + 7).clamp(0, paddedDays.length);
            final weekDays = paddedDays.sublist(start, end);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: weekDays.map((day) {
                  if (day == 0) return const Expanded(child: SizedBox());
                  final isToday = day == DateTime.now().day && month == DateTime.now().month && year == DateTime.now().year;
                  final isSelected = day == selectedDate.day;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDateSelected(DateTime(year, month, day)),
                      child: Container(
                        width: 36, height: 36,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : isToday ? AppColors.primaryContainer : null,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isSelected ? AppColors.onPrimary : isToday ? AppColors.onPrimaryContainer : AppColors.onSurface,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
