import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/agro_control_app_bar.dart';
import '../../../../core/widgets/glass.dart';
import '../widgets/bottom_nav_bar.dart';

/// Pestañas de la campaña: (segmento de ruta, nombre de la sección).
const _tabs = [
  ('/inicio', 'Inicio'),
  ('/cuaderno', 'Cuaderno'),
  ('/cosechas', 'Cosechas'),
  ('/resumen', 'Resumen'),
];

/// Pantallas ya rediseñadas: su contenido pasa por detrás de la barra
/// flotante y reservan el espacio final con `MediaQuery.paddingOf`.
const _extendsBehindDock = {'/inicio', '/cuaderno', '/cosechas', '/resumen'};

class CampaignShellScreen extends StatelessWidget {
  final Widget child;
  final String campaignId;

  const CampaignShellScreen({
    super.key,
    required this.child,
    required this.campaignId,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isHistorial = location.endsWith('/historial');
    final tabIndex = _tabs.indexWhere((t) => location.endsWith(t.$1));
    final extendBody = _extendsBehindDock.any(location.endsWith);

    return AgroBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: extendBody,
        appBar: AgroControlAppBar(
          section: isHistorial ? 'Historial' : _tabs[tabIndex < 0 ? 0 : tabIndex].$2,
          showBackButton: isHistorial,
        ),
        body: SafeArea(top: false, bottom: !extendBody, child: child),
        bottomNavigationBar: isHistorial
            ? null
            : BottomNavBar(selectedIndex: tabIndex < 0 ? 0 : tabIndex, campaignId: campaignId),
      ),
    );
  }
}
