import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/campanas/presentation/screens/campaign_selector_screen.dart';
import '../../features/campanas/presentation/screens/campaign_shell_screen.dart';
import '../../features/campanas/presentation/screens/nueva_campana_screen.dart';
import '../../features/campanas/presentation/screens/inicio_screen.dart';
import '../../features/cuaderno/presentation/screens/cuaderno_screen.dart';
import '../../features/cosechas/presentation/screens/cosechas_screen.dart';
import '../../features/resumen/presentation/screens/resumen_screen.dart';
import '../../features/historial/presentation/screens/historial_screen.dart';
import '../../features/perfil/presentation/screens/perfil_screen.dart';

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
    ShellRoute(
      builder: (context, state, child) {
        final campaignId = state.pathParameters['id']!;
        return CampaignShellScreen(
          campaignId: campaignId,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/c/:id/inicio',
          builder: (context, state) => const InicioScreen(),
        ),
        GoRoute(
          path: '/c/:id/cuaderno',
          builder: (context, state) => CuadernoScreen(
            campaignId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/c/:id/cosechas',
          builder: (context, state) => CosechasScreen(
            campaignId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/c/:id/resumen',
          builder: (context, state) => ResumenScreen(
            campaignId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/c/:id/historial',
          builder: (context, state) => HistorialScreen(
            campaignId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
  ],
);
