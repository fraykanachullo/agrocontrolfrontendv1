import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/agro_control_app_bar.dart';
import '../widgets/bottom_nav_bar.dart';

class CampaignShellScreen extends ConsumerWidget {
  final Widget child;
  final String campaignId;

  const CampaignShellScreen({
    super.key,
    required this.child,
    required this.campaignId,
  });

  int _getSelectedIndex(String location) {
    if (location.contains('/inicio')) return 0;
    if (location.contains('/cuaderno')) return 1;
    if (location.contains('/cosechas')) return 2;
    if (location.contains('/resumen')) return 3;
    return 0;
  }

  bool _showBottomNav(String location) {
    return !location.contains('/historial');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _getSelectedIndex(location);
    final campana = ref.watch(activeCampanaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AgroControlAppBar(
        campaignName: location.contains('/historial') ? 'Historial' : campana?.nombre,
        campaignId: campaignId,
        showBackButton: location.contains('/historial'),
      ),
      body: child,
      bottomNavigationBar: _showBottomNav(location)
          ? BottomNavBar(
              selectedIndex: selectedIndex,
              campaignId: campaignId,
            )
          : null,
    );
  }
}
