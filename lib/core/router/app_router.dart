import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/campanas/presentation/screens/campaign_selector_screen.dart';
import '../../features/campanas/presentation/screens/campaign_shell_screen.dart';
import '../../features/campanas/presentation/widgets/fade_indexed_stack.dart';
import '../../features/campanas/presentation/screens/nueva_campana_screen.dart';
import '../../features/campanas/presentation/screens/inicio_screen.dart';
import '../../features/cuaderno/presentation/screens/cuaderno_screen.dart';
import '../../features/cosechas/presentation/screens/cosechas_screen.dart';
import '../../features/resumen/presentation/screens/resumen_screen.dart';
import '../../features/historial/presentation/screens/historial_screen.dart';
import '../../features/perfil/presentation/screens/perfil_screen.dart';
import '../../features/planillas/presentation/screens/plantillas_screen.dart';
import '../../features/terrenos/presentation/screens/terrenos_screen.dart';

/// go_router exige que cada rama tenga una ubicación inicial sin parámetros.
/// Solo la usaría `goBranch()`, que no se llama: la barra inferior siempre
/// navega con la ruta completa de la campaña activa.
String _ramaSinId(String pestana) => '/c/0/$pestana';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const AuthScreen(startOnRegister: true),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/campanas',
      builder: (context, state) => const CampaignSelectorScreen(),
    ),
    GoRoute(
      path: '/nueva-campana',
      builder: (context, state) => const NuevaCampanaScreen(),
    ),
    GoRoute(
      path: '/perfil',
      builder: (context, state) => const PerfilScreen(),
    ),
    GoRoute(
      path: '/terrenos',
      builder: (context, state) => const TerrenosScreen(),
    ),
    GoRoute(
      path: '/plantillas',
      builder: (context, state) => const PlantillasScreen(),
    ),
    GoRoute(
      path: '/c/:id/historial',
      builder: (context, state) => HistorialScreen(
        campaignId: state.pathParameters['id']!,
      ),
    ),
    // Las pestañas no se apilan: cada una vive en su rama (conserva su scroll
    // y su estado) y al cambiar solo aparece con un fundido corto.
    StatefulShellRoute(
      builder: (context, state, navigationShell) => CampaignShellScreen(
        campaignId: state.pathParameters['id']!,
        navigationShell: navigationShell,
      ),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          FadeIndexedStack(index: navigationShell.currentIndex, children: children),
      branches: [
        StatefulShellBranch(initialLocation: _ramaSinId('inicio'), routes: [
          GoRoute(
            path: '/c/:id/inicio',
            builder: (context, state) => const InicioScreen(),
          ),
        ]),
        StatefulShellBranch(initialLocation: _ramaSinId('cuaderno'), routes: [
          GoRoute(
            path: '/c/:id/cuaderno',
            builder: (context, state) => CuadernoScreen(
              campaignId: state.pathParameters['id']!,
            ),
          ),
        ]),
        StatefulShellBranch(initialLocation: _ramaSinId('cosechas'), routes: [
          GoRoute(
            path: '/c/:id/cosechas',
            builder: (context, state) => CosechasScreen(
              campaignId: state.pathParameters['id']!,
            ),
          ),
        ]),
        StatefulShellBranch(initialLocation: _ramaSinId('resumen'), routes: [
          GoRoute(
            path: '/c/:id/resumen',
            builder: (context, state) => ResumenScreen(
              campaignId: state.pathParameters['id']!,
            ),
          ),
        ]),
      ],
    ),
  ],
);
