import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../widgets/campaign_card.dart';

class InicioScreen extends ConsumerStatefulWidget {
  const InicioScreen({super.key});

  @override
  ConsumerState<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends ConsumerState<InicioScreen> {
  String _feedFilter = 'todos';

  @override
  void initState() {
    super.initState();
    final state = ref.read(campanaListProvider);
    if (state.campanas.isEmpty && !state.isLoading) {
      Future.microtask(() => ref.read(campanaListProvider.notifier).loadCampanas());
    }
  }

  @override
  Widget build(BuildContext context) {
    final campana = ref.watch(activeCampanaProvider);
    final campanaState = ref.watch(campanaListProvider);

    if (campana == null) {
      return _buildNoCampaignView(context, campanaState);
    }

    return _buildDashboard(context, campana, campanaState);
  }

  // ═══════════════════════════════════════════════
  //  NO CAMPAIGN VIEW
  // ═══════════════════════════════════════════════

  Widget _buildNoCampaignView(BuildContext context, CampanaListState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selecciona una campaña', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Elige una campaña para ver su resumen', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/nueva-campana'),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Nueva Campaña'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 20),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.campanas.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  Icon(Icons.agriculture, size: 64, color: AppColors.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No hay campañas', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Crea tu primera campaña para empezar', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                ]),
              ),
            )
          else
            ...state.campanas.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CampaignCard(
                    title: c.nombre,
                    subtitle: c.cultivo,
                    startDate: c.fechaInicio != null ? 'Inicio: ${DateFormat('dd MMM yyyy', 'es').format(c.fechaInicio!)}' : 'Sin fecha',
                    extension: c.extensionDisplay,
                    isActive: c.isActive,
                    onTap: () => ref.read(activeCampanaIdProvider.notifier).state = c.id,
                  ),
                )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  MAIN DASHBOARD
  // ═══════════════════════════════════════════════

  Widget _buildDashboard(BuildContext context, dynamic campana, CampanaListState campanaState) {
    final dashboardData = ref.watch(dashboardDataProvider);
    final now = DateTime.now();
    final diasTranscurridos = campana.fechaInicio != null ? now.difference(campana.fechaInicio!).inDays : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCampaignCard(context, campana, diasTranscurridos),
          const SizedBox(height: 16),
          _buildFinancialSummary(context, dashboardData.value),
          const SizedBox(height: 20),
          _buildActivityFeedSection(context, campana),
          const SizedBox(height: 24),
          _buildDiscreetSecondaryActions(context, campana),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  1. HERO CAMPAIGN CARD with SWAP button
  // ─────────────────────────────────────────────

  Widget _buildHeroCampaignCard(BuildContext context, dynamic campana, int diasTranscurridos) {
    final cropEmoji = _getCropEmoji(campana.cultivo);
    final fechaInicio = campana.fechaInicio != null ? DateFormat('dd MMM yyyy', 'es').format(campana.fechaInicio!) : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.primaryContainer.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                child: Text('CAMPAÑA ACTIVA', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              ),
              GestureDetector(
                onTap: () => _showCampaignSwitcher(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.swap_horiz, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(cropEmoji, style: const TextStyle(fontSize: 32))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campana.nombre, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${campana.extensionDisplay} • Inicio: $fechaInicio', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInfoBox(context, label: 'Días Transcurridos', value: '$diasTranscurridos Días')),
              const SizedBox(width: 10),
              Expanded(child: _buildInfoBox(context, label: 'Estado', value: campana.isActive ? 'Activa' : 'Cerrada')),
            ],
          ),
        ],
      ),
    );
  }

  void _showCampaignSwitcher(BuildContext context) {
    final campanas = ref.read(campanaListProvider).campanas;
    final currentId = ref.read(activeCampanaIdProvider);

    if (campanas.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo tienes una campaña activa')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Cambiar campaña', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Selecciona la campaña que deseas administrar', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            ...campanas.map((c) {
              final isActive = c.id == currentId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isActive ? AppColors.primary : AppColors.surfaceVariant, width: isActive ? 2 : 1),
                  ),
                  tileColor: isActive ? AppColors.primaryContainer.withValues(alpha: 0.12) : null,
                  leading: Text(_getCropEmoji(c.cultivo), style: const TextStyle(fontSize: 28)),
                  title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(c.extensionDisplay),
                  trailing: isActive
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref.read(activeCampanaIdProvider.notifier).state = c.id;
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, {required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  2. FINANCIAL SUMMARY
  // ─────────────────────────────────────────────

  Widget _buildFinancialSummary(BuildContext context, Map<String, dynamic>? data) {
    final invertido = data?['total_gastos'] as double? ?? 0;
    final recaudado = data?['total_ingresos'] as double? ?? 0;

    return Row(
      children: [
        Expanded(child: _buildFinanceCard(context, label: 'Invertido', value: 'S/${invertido.toStringAsFixed(0)}', color: AppColors.error, bgColor: const Color(0xFFFEE2E2), icon: Icons.trending_down)),
        const SizedBox(width: 10),
        Expanded(child: _buildFinanceCard(context, label: 'Recaudado', value: 'S/${recaudado.toStringAsFixed(0)}', color: AppColors.statusActive, bgColor: const Color(0xFFDCFCE7), icon: Icons.trending_up)),
      ],
    );
  }

  Widget _buildFinanceCard(BuildContext context, {required String label, required String value, required Color color, required Color bgColor, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  3. ACTIVITY FEED SECTION
  // ─────────────────────────────────────────────

  Widget _buildActivityFeedSection(BuildContext context, dynamic campana) {
    final now = DateTime.now();
    final todayParam = (campana.id as int, now);
    final entriesAsync = ref.watch(historialDayProvider(todayParam));
    final cosechasState = ref.watch(cosechasProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        entriesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
          data: (entries) {
            final labores = entries.where((e) => e.tipo == 'actividad').length;
            final gastos = entries.where((e) => e.tipo == 'gasto').fold<double>(0, (sum, e) => sum + (e.monto ?? 0));
            final parts = <String>[];
            if (labores > 0) parts.add('$labores labor${labores > 1 ? 'es' : ''}');
            if (gastos > 0) parts.add('S/ ${gastos.toStringAsFixed(0)} en gastos');
            final summary = parts.isEmpty ? 'Sin actividad hoy' : 'Hoy: ${parts.join(' y ')}';
            return Text(summary, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w600));
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Todos', isSelected: _feedFilter == 'todos', onTap: () => setState(() => _feedFilter = 'todos')),
              _buildFilterChip('Gastos', icon: Icons.payments, isSelected: _feedFilter == 'gasto', onTap: () => setState(() => _feedFilter = 'gasto')),
              _buildFilterChip('Labores', icon: Icons.agriculture, isSelected: _feedFilter == 'actividad', onTap: () => setState(() => _feedFilter = 'actividad')),
              _buildFilterChip('Cosechas', icon: Icons.local_shipping, isSelected: _feedFilter == 'cosecha', onTap: () => setState(() => _feedFilter = 'cosecha')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_feedFilter == 'todos' || _feedFilter == 'cosecha')
          ...cosechasState.pendientes.take(3).map((cosecha) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildCosechaItem(context, cosecha),
              )),
        entriesAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (entries) {
            final filtered = _feedFilter == 'todos' ? entries : entries.where((e) => e.tipo == _feedFilter).toList();
            if (filtered.isEmpty && cosechasState.pendientes.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.surfaceVariant)),
                child: Column(children: [
                  Icon(Icons.event_available, size: 40, color: AppColors.outlineVariant),
                  const SizedBox(height: 8),
                  Text('Sin registros hoy', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('Registra desde el cuaderno', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.outlineVariant)),
                ]),
              );
            }
            return Column(
              children: [
                ...filtered.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _buildFeedItem(context, e))),
                if (entries.isNotEmpty)
                  GestureDetector(
                    onTap: () => context.go('/c/${campana.id}/historial'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Center(
                        child: Text(
                          'Ver historial completo de esta campaña',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, {IconData? icon, required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
              Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCosechaItem(BuildContext context, dynamic cosecha) {
    final isKilo = cosecha.tipoVenta != 'javas';
    final unitLabel = isKilo ? 'sacos' : 'javas';
    final isPendiente = cosecha.estado == 'pendiente';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.local_shipping, color: Color(0xFFE65100), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Envío: ${cosecha.cantidadUnidades} $unitLabel', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('${cosecha.mercadoDestino}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isPendiente)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.statusPending.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pending, size: 14, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text('Pendiente', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSecondaryContainer, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
          if (isPendiente) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => context.go('/c/${cosecha.campanaId}/cosechas'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('LIQUIDAR AHORA', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedItem(BuildContext context, dynamic e) {
    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (e.tipo) {
      case 'actividad':
        icon = Icons.agriculture;
        iconBg = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF1565C0);
        break;
      case 'gasto':
        icon = Icons.payments;
        iconBg = const Color(0xFFFEE2E2);
        iconColor = AppColors.error;
        break;
      case 'ingreso':
        icon = Icons.attach_money;
        iconBg = const Color(0xFFE8F5E9);
        iconColor = AppColors.primary;
        break;
      case 'cosecha':
        icon = Icons.local_shipping;
        iconBg = const Color(0xFFFFF3E0);
        iconColor = const Color(0xFFE65100);
        break;
      default:
        icon = Icons.circle;
        iconBg = AppColors.surfaceContainerHigh;
        iconColor = AppColors.onSurfaceVariant;
    }

    final timeStr = e.hora != '--:--' ? e.hora : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.titulo, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (timeStr.isNotEmpty) ...[
                      Text(timeStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(e.descripcion, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (e.monto != null && e.monto! > 0) ...[
            const SizedBox(width: 8),
            Text('S/${e.monto!.toStringAsFixed(0)}', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: e.tipo == 'gasto' ? AppColors.error : AppColors.primary)),
          ],
          const SizedBox(width: 8),
          Icon(e.isSynced ? Icons.cloud_done : Icons.cloud_off, size: 14, color: e.isSynced ? AppColors.primary : AppColors.secondary),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  4. DISCREET SECONDARY ACTIONS (footer links)
  // ─────────────────────────────────────────────

  Widget _buildDiscreetSecondaryActions(BuildContext context, dynamic campana) {
    return Column(
      children: [
        Container(height: 1, color: AppColors.surfaceVariant.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => context.push('/nueva-campana'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, size: 14, color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text('Nueva campaña', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(width: 1, height: 12, color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            GestureDetector(
              onTap: () => _showCloseCampaignDialog(context, campana),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel_outlined, size: 14, color: AppColors.error.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text('Cerrar campaña', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCloseCampaignDialog(BuildContext context, dynamic campana) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar campaña'),
        content: Text('¿Estás seguro de que deseas cerrar "${campana.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _closeCampana(campana);
            },
            child: Text('Cerrar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _closeCampana(dynamic campana) async {
    try {
      final localDs = ref.read(campanaLocalDatasourceProvider);
      await localDs.updateCampana(campana.id, {'estado': 'cerrada', 'fecha_cierre': DateTime.now().toIso8601String()});
      await ref.read(campanaListProvider.notifier).loadCampanas();
      ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${campana.nombre} cerrada')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _getCropEmoji(String cultivo) {
    final c = cultivo.toLowerCase();
    if (c.contains('tomate')) return '🍅';
    if (c.contains('cebolla')) return '🧅';
    if (c.contains('ajo')) return '🧄';
    if (c.contains('vainita')) return '🫛';
    if (c.contains('papa')) return '🥔';
    if (c.contains('maíz') || c.contains('maiz')) return '🌽';
    if (c.contains('palto') || c.contains('aguacate')) return '🥑';
    if (c.contains('uva')) return '🍇';
    if (c.contains('manzana')) return '🍎';
    if (c.contains('naranja')) return '🍊';
    return '🌱';
  }
}
