import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../widgets/campaign_card.dart';

class CampaignSelectorScreen extends ConsumerStatefulWidget {
  const CampaignSelectorScreen({super.key});

  @override
  ConsumerState<CampaignSelectorScreen> createState() =>
      _CampaignSelectorScreenState();
}

class _CampaignSelectorScreenState extends ConsumerState<CampaignSelectorScreen> {
  @override
  void initState() {
    super.initState();
    // Load campaigns on first render
    final state = ref.read(campanaListProvider);
    if (state.campanas.isEmpty && !state.isLoading) {
      Future.microtask(() => ref.read(campanaListProvider.notifier).loadCampanas());
    }
  }

  @override
  Widget build(BuildContext context) {
    final campanaState = ref.watch(campanaListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seleccionar Campaña',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 26,
                          height: 32 / 26,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elige la campaña activa para gestionar datos\no consulta el historial cerrado.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Campaign list
            Expanded(
              child: _buildCampaignList(campanaState),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/nueva-campana'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text(
          'Nueva Campaña',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onPrimary,
              ),
        ),
      ),
    );
  }

  Widget _buildCampaignList(CampanaListState state) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(campanaListProvider.notifier).loadCampanas(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.campanas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.agriculture, size: 64, color: AppColors.outlineVariant),
              const SizedBox(height: 16),
              Text(
                'No hay campañas registradas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea tu primera campaña para comenzar\na registrar actividades y cosechas.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final activeCampanas = state.campanas.where((c) => c.isActive).toList();
    final closedCampanas = state.campanas.where((c) => c.isClosed).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(campanaListProvider.notifier).loadCampanas(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (activeCampanas.isNotEmpty) ...[
            for (final campana in activeCampanas) ...[
              CampaignCard(
                title: campana.nombre,
                subtitle: campana.cultivo,
                startDate: campana.fechaInicio != null
                    ? 'Inicio: ${DateFormat('dd MMM yyyy', 'es').format(campana.fechaInicio!)}'
                    : 'Sin fecha',
                extension: campana.extensionDisplay,
                isActive: true,
                onTap: () => _selectCampaign(campana.id),
              ),
              const SizedBox(height: 12),
            ],
          ],

          if (closedCampanas.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                height: 1,
                color: AppColors.surfaceVariant,
              ),
            ),
            for (final campana in closedCampanas) ...[
              CampaignCard(
                title: campana.nombre,
                subtitle: campana.cultivo,
                startDate: campana.fechaCierre != null
                    ? 'Fin: ${DateFormat('dd MMM yyyy', 'es').format(campana.fechaCierre!)}'
                    : 'Cerrada',
                extension: campana.extensionDisplay,
                isActive: false,
                onTap: () {},
              ),
              const SizedBox(height: 12),
            ],
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _selectCampaign(int campaignId) {
    ref.read(activeCampanaIdProvider.notifier).state = campaignId;
    context.go('/c/$campaignId/inicio');
  }
}
