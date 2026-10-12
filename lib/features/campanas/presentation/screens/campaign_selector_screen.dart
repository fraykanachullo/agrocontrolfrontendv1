import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/agro_control_app_bar.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/campana.dart';
import '../widgets/campaign_tile.dart';

/// Tus campañas (S03): balance consolidado, activas / cerradas y nueva campaña.
class CampaignSelectorScreen extends ConsumerStatefulWidget {
  const CampaignSelectorScreen({super.key});

  @override
  ConsumerState<CampaignSelectorScreen> createState() => _CampaignSelectorScreenState();
}

class _CampaignSelectorScreenState extends ConsumerState<CampaignSelectorScreen> {
  bool _showActive = true;

  @override
  void initState() {
    super.initState();
    final state = ref.read(campanaListProvider);
    if (state.campanas.isEmpty && !state.isLoading) {
      Future.microtask(() => ref.read(campanaListProvider.notifier).loadCampanas());
    }
  }

  /// Activa: abre su inicio. Cerrada: abre su resumen final.
  void _open(Campana c) {
    ref.read(activeCampanaIdProvider.notifier).state = c.id;
    context.go(c.isActive ? '/c/${c.id}/inicio' : '/c/${c.id}/resumen');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final state = ref.watch(campanaListProvider);
    final resumenes = ref.watch(campanaResumenesProvider).value ?? const {};
    final activas = state.campanas.where((c) => !c.isClosed).toList();
    final cerradas = state.campanas.where((c) => c.isClosed).toList();
    final lista = _showActive ? activas : cerradas;

    return AgroBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const AgroControlAppBar(section: 'Tus campañas'),
        body: RefreshIndicator(
          onRefresh: () => ref.read(campanaListProvider.notifier).loadCampanas(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Text('Tus campañas', style: text.headlineMedium),
              const SizedBox(height: 4),
              Text('Elige una campaña para ver su cuaderno y su balance.', style: text.bodySmall),
              const SizedBox(height: 16),
              if (state.campanas.isNotEmpty) ...[
                _ConsolidatedCard(
                  resumenes: resumenes,
                  activas: activas.length,
                  cerradas: cerradas.length,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _Tab(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Activas',
                        count: activas.length,
                        selected: _showActive,
                        onTap: () => setState(() => _showActive = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Tab(
                        icon: Icons.inventory_2_outlined,
                        label: 'Cerradas',
                        count: cerradas.length,
                        selected: !_showActive,
                        onTap: () => setState(() => _showActive = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (state.isLoading && state.campanas.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
              else if (state.error != null && state.campanas.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 32),
                      const SizedBox(height: 8),
                      Text(state.error!, textAlign: TextAlign.center, style: text.bodySmall),
                      TextButton(
                        onPressed: () => ref.read(campanaListProvider.notifier).loadCampanas(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              else if (lista.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const Text('🌱', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 10),
                      Text(
                        state.campanas.isEmpty
                            ? 'Aún no tienes campañas'
                            : (_showActive ? 'No hay campañas activas' : 'Aún no cierras ninguna campaña'),
                        style: text.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.campanas.isEmpty ? 'Crea la primera para empezar a registrar' : 'Las campañas cerradas guardan su resultado final',
                        style: text.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                for (final c in lista)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CampaignTile(campana: c, resumen: resumenes[c.id], onTap: () => _open(c)),
                  ),
              const SizedBox(height: 10),
              AgroActionButton(
                label: 'Nueva campaña',
                icon: Icons.add_circle_rounded,
                primary: true,
                height: 56,
                onPressed: () => context.push('/nueva-campana'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Balance sumado de todas las campañas.
class _ConsolidatedCard extends StatelessWidget {
  final Map<int, CampanaResumen> resumenes;
  final int activas;
  final int cerradas;

  const _ConsolidatedCard({required this.resumenes, required this.activas, required this.cerradas});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = resumenes.values.fold<double>(0, (s, r) => s + r.utilidad);
    final positivo = total >= 0;

    Widget dato(Color color, String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelSmall),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(value, style: text.titleSmall),
                ],
              ),
            ],
          ),
        );

    return GlassCard(
      highlight: true,
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('BALANCE CONSOLIDADO', style: text.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
              ),
              Text('${activas + cerradas} campaña${activas + cerradas == 1 ? '' : 's'}', style: text.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${positivo ? '' : '-'}${formatSoles(total.abs())}',
              style: AppTheme.display(fontSize: 30, color: positivo ? AppColors.positive : AppColors.expense),
            ),
          ),
          Text('Utilidad sumada de todas tus campañas', style: text.bodySmall),
          const Divider(height: 26),
          Row(
            children: [
              dato(AppColors.accent, 'En ejecución', '$activas activa${activas == 1 ? '' : 's'}'),
              dato(AppColors.textSubtle, 'Histórico', '$cerradas cerrada${cerradas == 1 ? '' : 's'}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.icon, required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.14) : AppColors.accentSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.accent : AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
              child: Text('$count', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
