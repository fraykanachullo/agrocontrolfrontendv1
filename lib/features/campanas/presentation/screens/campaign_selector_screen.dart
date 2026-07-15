import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/agro_control_app_bar.dart';
import '../widgets/campaign_card.dart';
import '../widgets/bottom_nav_bar.dart';

class CampaignSelectorScreen extends StatelessWidget {
  const CampaignSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AgroControlAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
              const SizedBox(height: 24),

              // Active campaigns
              CampaignCard(
                title: 'Tomate 2025',
                startDate: 'Inicio: 15 Ene 2025',
                isActive: true,
                icon: Icons.agriculture,
                onTap: () => context.go('/dashboard'),
              ),
              const SizedBox(height: 12),
              CampaignCard(
                title: 'Cebolla 2025',
                startDate: 'Inicio: 01 Mar 2025',
                isActive: true,
                icon: Icons.spa,
                onTap: () => context.go('/dashboard'),
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  height: 1,
                  color: AppColors.surfaceVariant,
                ),
              ),

              // Closed campaigns
              CampaignCard(
                title: 'Papa 2024',
                startDate: 'Fin: 20 Dic 2024',
                isActive: false,
                icon: Icons.history,
                onTap: () {},
              ),
            ],
          ),
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
      bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
    );
  }
}
