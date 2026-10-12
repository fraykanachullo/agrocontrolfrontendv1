import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../widgets/activity_form.dart';
import '../../../historial/presentation/widgets/timeline_widget.dart';

class CuadernoScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const CuadernoScreen({super.key, required this.campaignId});

  @override
  ConsumerState<CuadernoScreen> createState() => _CuadernoScreenState();
}

class _CuadernoScreenState extends ConsumerState<CuadernoScreen> {
  String? _activeForm;
  DateTime _selectedDate = DateTime.now();

  bool get _isToday =>
      _selectedDate.year == DateTime.now().year &&
      _selectedDate.month == DateTime.now().month &&
      _selectedDate.day == DateTime.now().day;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final campanaId = int.tryParse(widget.campaignId);
      if (campanaId != null) {
        ref.read(cuadernoProvider.notifier).loadData(campanaId);
      }
    });
  }

  void _toggleForm(String type) {
    setState(() => _activeForm = _activeForm == type ? null : type);
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _activeForm = null;
    });
  }

  void _nextDay() {
    final now = DateTime.now();
    final next = _selectedDate.add(const Duration(days: 1));
    if (!next.isAfter(DateTime(now.year, now.month, now.day))) {
      setState(() {
        _selectedDate = next;
        _activeForm = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _activeForm = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final campanaId = int.tryParse(widget.campaignId) ?? 0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateNavigator(context),
                const SizedBox(height: 16),
                _buildActionGrid(context),
                const SizedBox(height: 16),

                if (_activeForm != null) ...[
                  ActivityForm(type: _activeForm!, campanaId: campanaId),
                  const SizedBox(height: 16),
                ],

                _buildSectionHeader(context),
                const SizedBox(height: 10),

                TimelineWidget(
                  campaignId: widget.campaignId,
                  selectedDate: _selectedDate,
                ),
              ],
            ),
          ),
        ),
        _buildDailySummaryFooter(context),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  1. COMPACT DATE NAVIGATOR
  // ═══════════════════════════════════════════

  Widget _buildDateNavigator(BuildContext context) {
    final dateLabel = _isToday
        ? 'Hoy, ${DateFormat('EEEE d MMM', 'es').format(_selectedDate)}'
        : DateFormat('EEEE d \'de\' MMMM', 'es').format(_selectedDate);
    final formatted = dateLabel[0].toUpperCase() + dateLabel.substring(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousDay,
            icon: const Icon(Icons.chevron_left, size: 22),
            color: AppColors.onSurfaceVariant,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  formatted,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                if (!_isToday)
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedDate = DateTime.now();
                      _activeForm = null;
                    }),
                    child: Text('Ir a hoy', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _nextDay,
            icon: const Icon(Icons.chevron_right, size: 22),
            color: _isToday ? AppColors.outlineVariant : AppColors.onSurfaceVariant,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  2. ACTION GRID — 2×2 large touch buttons
  // ═══════════════════════════════════════════

  Widget _buildActionGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGridButton(
                context,
                emoji: '🛠️',
                label: 'Registrar',
                sublabel: 'Labor / Actividad',
                color: AppColors.primaryContainer,
                isActive: _activeForm == 'Actividad',
                onTap: () => _toggleForm('Actividad'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGridButton(
                context,
                emoji: '💸',
                label: 'Registrar',
                sublabel: 'Gasto / Egreso',
                color: AppColors.errorContainer,
                isActive: _activeForm == 'Gasto',
                onTap: () => _toggleForm('Gasto'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildGridButton(
                context,
                emoji: '💰',
                label: 'Ingreso',
                sublabel: 'Directo',
                color: const Color(0xFFE8F5E9),
                isActive: _activeForm == 'Ingreso',
                onTap: () => _toggleForm('Ingreso'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGridButton(
                context,
                emoji: '📸',
                label: 'Adjuntar',
                sublabel: 'Foto / Boleta',
                color: AppColors.surfaceContainerHigh,
                isActive: false,
                onTap: () => _toggleForm('Actividad'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridButton(
    BuildContext context, {
    required String emoji,
    required String label,
    required String sublabel,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? color : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.surfaceVariant,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 3, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isActive ? AppColors.primary : AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
                  Text(sublabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  3. SECTION HEADER
  // ═══════════════════════════════════════════

  Widget _buildSectionHeader(BuildContext context) {
    final campanaId = int.tryParse(widget.campaignId) ?? 0;
    final entriesAsync = ref.watch(historialDayProvider((campanaId, _selectedDate)));

    return entriesAsync.when(
      loading: () => Row(
        children: [
          Text('Movimientos del día', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
      error: (_, __) => Row(
        children: [
          Text('Movimientos del día', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
      data: (entries) {
        final dayLabel = DateFormat('d MMM', 'es').format(_selectedDate);
        return Row(
          children: [
            Text('Movimientos del día', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text('($dayLabel)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
            const Spacer(),
            Text('${entries.length} registro${entries.length != 1 ? 's' : ''}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  //  4. DAILY SUMMARY FOOTER
  // ═══════════════════════════════════════════

  Widget _buildDailySummaryFooter(BuildContext context) {
    final campanaId = int.tryParse(widget.campaignId) ?? 0;
    final entriesAsync = ref.watch(historialDayProvider((campanaId, _selectedDate)));

    return entriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();

        final gastos = entries.where((e) => e.tipo == 'gasto').fold<double>(0, (sum, e) => sum + (e.monto ?? 0));
        final ingresos = entries.where((e) => e.tipo == 'ingreso').fold<double>(0, (sum, e) => sum + (e.monto ?? 0));

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(top: BorderSide(color: AppColors.surfaceVariant.withValues(alpha: 0.5))),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, -2))],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (gastos > 0) ...[
                  Icon(Icons.trending_down, size: 16, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text('Gastos: ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                  Text('S/ ${gastos.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.error)),
                ],
                if (gastos > 0 && ingresos > 0) ...[
                  const SizedBox(width: 16),
                  Container(width: 1, height: 14, color: AppColors.outlineVariant),
                  const SizedBox(width: 16),
                ],
                if (ingresos > 0) ...[
                  Icon(Icons.trending_up, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Ingresos: ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                  Text('S/ ${ingresos.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
                if (gastos == 0 && ingresos == 0)
                  Text('Sin movimientos hoy', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        );
      },
    );
  }
}
