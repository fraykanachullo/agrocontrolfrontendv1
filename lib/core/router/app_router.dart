import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/campanas/presentation/screens/campaign_selector_screen.dart';
import '../../features/campanas/presentation/screens/nueva_campana_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/cuaderno/presentation/screens/cuaderno_screen.dart';
import '../../features/cosechas/presentation/screens/cosechas_screen.dart';
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
      builder: (context, state) => const LoginScreen(),
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
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/cuaderno',
      builder: (context, state) => const CuadernoScreen(),
    ),
    GoRoute(
      path: '/cosechas',
      builder: (context, state) => const CosechasScreen(),
    ),
    GoRoute(
      path: '/historial',
      builder: (context, state) => const HistorialScreen(),
    ),
    GoRoute(
      path: '/perfil',
      builder: (context, state) => const PerfilScreen(),
    ),
  ],
);
