import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/agro_control_app_bar.dart';
import '../../../../core/widgets/glass.dart';
import '../widgets/bottom_nav_bar.dart';

/// Nombres de las pestañas, en el orden de las ramas del router.
const _tabs = ['Inicio', 'Cuaderno', 'Cosechas', 'Resumen'];

/// Marco de la campaña: barra superior, fondo y barra inferior flotante.
/// El contenido de cada pestaña pasa por detrás de la barra flotante y
/// reserva el espacio final con `MediaQuery.paddingOf`.
class CampaignShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final String campaignId;

  const CampaignShellScreen({
    super.key,
    required this.navigationShell,
    required this.campaignId,
  });

  @override
  Widget build(BuildContext context) {
    final tabIndex = navigationShell.currentIndex;

    return AgroBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AgroControlAppBar(section: _tabs[tabIndex]),
        body: SafeArea(top: false, bottom: false, child: navigationShell),
        bottomNavigationBar: BottomNavBar(selectedIndex: tabIndex, campaignId: campaignId),
      ),
    );
  }
}
