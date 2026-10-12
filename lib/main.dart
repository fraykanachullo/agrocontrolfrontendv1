import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/agro_palette.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  runApp(const ProviderScope(child: AgroControlApp()));
}

class AgroControlApp extends ConsumerWidget {
  const AgroControlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'AgroControl',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      builder: (context, child) {
        final palette = Theme.of(context).brightness == Brightness.dark
            ? AgroPalette.dark
            : AgroPalette.light;
        AppColors.use(palette);

        // La clave fuerza a redibujar todas las pantallas con la nueva paleta.
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (palette.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: palette.background,
          ),
          child: KeyedSubtree(key: ValueKey(palette.brightness), child: child!),
        );
      },
    );
  }
}
