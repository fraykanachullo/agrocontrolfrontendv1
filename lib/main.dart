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
      // Sin interpolar: los colores de AppColors cambian de golpe y el tema de
      // Material debe cambiar con ellos, si no se ven mezclados un instante.
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      builder: (context, child) {
        final palette = Theme.of(context).brightness == Brightness.dark
            ? AgroPalette.dark
            : AgroPalette.light;
        AppColors.use(palette);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (palette.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: palette.background,
          ),
          child: _PaletteScope(palette: palette, child: child!),
        );
      },
    );
  }
}

/// Al cambiar de paleta redibuja todas las pantallas (incluidas las que están
/// ocultas o en caché del router) sin desmontarlas: conservan su estado y
/// toman los nuevos colores de [AppColors] en el mismo cuadro.
class _PaletteScope extends StatefulWidget {
  final AgroPalette palette;
  final Widget child;

  const _PaletteScope({required this.palette, required this.child});

  @override
  State<_PaletteScope> createState() => _PaletteScopeState();
}

class _PaletteScopeState extends State<_PaletteScope> {
  @override
  void didUpdateWidget(_PaletteScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.palette != widget.palette) {
      void marcar(Element e) {
        e.markNeedsBuild();
        e.visitChildren(marcar);
      }

      (context as Element).visitChildren(marcar);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
