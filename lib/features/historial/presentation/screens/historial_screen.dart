import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';

class HistorialScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const HistorialScreen({super.key, required this.campaignId});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _feedFilter = 'todos';

  bool get _isToday =>
      _selectedDate.year == DateTime.now().year &&
      _selectedDate.month == DateTime.now().month &&
      _selectedDate.day == DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    final campanaId = int.tryParse(widget.campaignId) ?? 0;
    final dateParam = (campanaId, _selectedDate);
    final entriesAsync = ref.watch(historialDayProvider(dateParam));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactCalendar(context),
          const SizedBox(height: 16),
          _buildDateLabel(context),
          const SizedBox(height: 12),
          _buildFilterChips(context),
          const SizedBox(height: 16),
          _buildTimelineSection(context, entriesAsync),
        ],
      ),
    );
  }

  // ── Compact Calendar ──

  Widget _buildCompactCalendar(BuildContext context) {
    final now = DateTime.now();
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final monthName = DateFormat('MMMM yyyy', 'es').format(_currentMonth);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;
    final leadingBlanks = (firstWeekday - 1) % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _currentMonth = DateTime(year, month - 1)),
                icon: const Icon(Icons.chevron_left, size: 22),
                color: AppColors.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Text(monthName[0].toUpperCase() + monthName.substring(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: month == now.month && year == now.year
                    ? null
                    : () => setState(() => _currentMonth = DateTime(year, month + 1)),
                icon: const Icon(Icons.chevron_right, size: 22),
                color: month == now.month && year == now.year ? AppColors.outlineVariant : AppColors.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(d, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          for (var row = 0; row < rows; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final dayNum = cellIndex - leadingBlanks + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) return const Expanded(child: SizedBox(height: 36));

                  final cellDate = DateTime(year, month, dayNum);
                  final isToday = cellDate.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
                  final isSelected = cellDate.isAtSameMomentAs(selected);
                  final isFuture = cellDate.isAfter(DateTime(now.year, now.month, now.day));

                  return Expanded(
                    child: GestureDetector(
                      onTap: isFuture ? null : () => setState(() => _selectedDate = cellDate),
                      child: Container(
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : isToday ? AppColors.primaryContainer.withValues(alpha: 0.25) : null,
                          borderRadius: BorderRadius.circular(18),
                          border: isToday && !isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNum',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isSelected ? AppColors.onPrimary : isFuture ? AppColors.outlineVariant : isToday ? AppColors.primary : AppColors.onSurface,
                                  fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                                ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // ── Date Label ──

  Widget _buildDateLabel(BuildContext context) {
    final dateLabel = DateFormat('EEEE d \'de\' MMMM', 'es').format(_selectedDate);
    final formatted = dateLabel[0].toUpperCase() + dateLabel.substring(1);

    return Row(
      children: [
        Text(formatted, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
        if (!_isToday) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() {
              _selectedDate = DateTime.now();
              _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
            }),
            child: Text('Hoy', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  // ── Filter Chips ──

  Widget _buildFilterChips(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('Todos', isSelected: _feedFilter == 'todos', onTap: () => setState(() => _feedFilter = 'todos')),
          _chip('Gastos', icon: Icons.payments, isSelected: _feedFilter == 'gasto', onTap: () => setState(() => _feedFilter = 'gasto')),
          _chip('Labores', icon: Icons.agriculture, isSelected: _feedFilter == 'actividad', onTap: () => setState(() => _feedFilter = 'actividad')),
          _chip('Cosechas', icon: Icons.local_shipping, isSelected: _feedFilter == 'cosecha', onTap: () => setState(() => _feedFilter = 'cosecha')),
        ],
      ),
    );
  }

  Widget _chip(String label, {IconData? icon, required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant),
                const SizedBox(width: 5),
              ],
              Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Timeline Section ──

  Widget _buildTimelineSection(BuildContext context, AsyncValue<List<HistorialEntry>> entriesAsync) {
    return entriesAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Error: $e'))),
      data: (entries) {
        final filtered = _feedFilter == 'todos'
            ? entries
            : entries.where((e) => e.tipo == _feedFilter).toList();

        if (filtered.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(children: [
              Icon(Icons.event_available, size: 48, color: AppColors.outlineVariant),
              const SizedBox(height: 12),
              Text('Sin registros este día', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('Selecciona otro día o registra desde el cuaderno', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.outlineVariant), textAlign: TextAlign.center),
            ]),
          );
        }

        return Column(
          children: filtered.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            final isLast = idx == filtered.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
              child: _buildTimelineCard(context, e, !isLast),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTimelineCard(BuildContext context, HistorialEntry e, bool showLine) {
    final (Color dotColor, Color dotIconColor, IconData dotIcon) = switch (e.tipo) {
      'actividad' => (AppColors.primaryContainer, AppColors.onPrimaryContainer, Icons.science),
      'gasto' => (AppColors.secondaryContainer, AppColors.onSecondaryContainer, Icons.payments),
      'ingreso' => (AppColors.primaryContainer, AppColors.onPrimaryContainer, Icons.trending_up),
      'cosecha' => (AppColors.secondaryContainer, AppColors.warning, Icons.local_shipping),
      _ => (AppColors.surfaceContainerHigh, AppColors.onSurfaceVariant, Icons.circle),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, border: Border.all(color: AppColors.surfaceContainerLowest, width: 2)),
                  child: Icon(dotIcon, size: 13, color: dotIconColor),
                ),
                if (showLine)
                  Expanded(child: Container(width: 2, color: AppColors.surfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceVariant),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 3, offset: const Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.titulo, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(e.descripcion, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (e.hora != '--:--')
                        Text(e.hora, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (e.monto != null && e.monto! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: e.tipo == 'gasto' ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            e.tipo == 'gasto' ? '- S/${e.monto!.toStringAsFixed(2)}' : 'S/${e.monto!.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: e.tipo == 'gasto' ? AppColors.error : AppColors.primary,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: e.isSynced ? AppColors.primary.withValues(alpha: 0.1) : AppColors.statusPending.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(e.isSynced ? Icons.cloud_done : Icons.cloud_off, size: 12, color: e.isSynced ? AppColors.primary : AppColors.secondary),
                            const SizedBox(width: 3),
                            Text(e.isSynced ? 'Sync' : 'Pend.', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, color: e.isSynced ? AppColors.primary : AppColors.secondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
