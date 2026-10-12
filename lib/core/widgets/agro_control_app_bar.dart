import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/theme_mode_provider.dart';
import 'glass.dart';

/// Barra superior común: marca + sección actual, estado de sincronización,
/// cambio de modo claro/oscuro y acceso al perfil.
class AgroControlAppBar extends ConsumerWidget implements PreferredSizeWidget {
  /// Nombre de la sección (Inicio, Cuaderno…) que se muestra bajo la marca.
  final String section;
  final bool showBackButton;
  final bool showProfile;

  const AgroControlAppBar({
    super.key,
    required this.section,
    this.showBackButton = false,
    this.showProfile = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final initials = ref.watch(authProvider).user?.initials ?? 'AC';
    final palette = AppColors.palette;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: preferredSize.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (showBackButton)
                GlassCircleButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Volver',
                  onPressed: () => context.canPop() ? context.pop() : Navigator.of(context).maybePop(),
                )
              else
                const BrandMark(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AgroControl', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(section, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const _SyncPill(),
              const SizedBox(width: 6),
              GlassCircleButton(
                icon: palette.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                tooltip: palette.isDark ? 'Modo claro' : 'Modo oscuro',
                onPressed: () => ref.read(themeModeProvider.notifier).toggle(palette.brightness),
              ),
              if (showProfile) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => context.push('/perfil'),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(gradient: AppColors.ctaGradient, shape: BoxShape.circle),
                    child: Text(
                      initials,
                      style: text.labelSmall?.copyWith(color: AppColors.onAccent, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo: hoja dentro de un cuadrado con borde degradado.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.2)],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Icon(Icons.eco_rounded, color: AppColors.accent, size: size * 0.5),
      ),
    );
  }
}

/// Píldora de estado de sincronización. Al tocarla, sincroniza.
class _SyncPill extends ConsumerStatefulWidget {
  const _SyncPill();

  @override
  ConsumerState<_SyncPill> createState() => _SyncPillState();
}

class _SyncPillState extends ConsumerState<_SyncPill> {
  bool _syncing = false;

  Future<void> _sync() async {
    if (_syncing) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _syncing = true);
    try {
      final manager = ref.read(syncManagerProvider);
      await manager.syncPending();
      await manager.pullRemoteChanges();
      messenger.showSnackBar(const SnackBar(content: Text('Sincronización completada')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Sin conexión: se sincronizará luego')));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(syncPendingCountProvider).value ?? 0;
    final color = pending == 0 ? AppColors.accent : AppColors.warning;

    return Tooltip(
      message: 'Sincronizar ahora',
      child: Material(
        color: color.withValues(alpha: 0.12),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: _sync,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_syncing)
                  SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.6, color: color))
                else
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  pending == 0 ? 'Al día' : '$pending',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                if (pending > 0) ...[
                  const SizedBox(width: 2),
                  Icon(Icons.cloud_upload_outlined, size: 13, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
