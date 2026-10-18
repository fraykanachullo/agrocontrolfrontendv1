import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/despacho_aviso_provider.dart';
import '../../../../core/providers/topo_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';

/// Perfil: datos de la cuenta, sincronización, preferencias y salida.
/// Solo muestra lo que la app de verdad hace.
class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _syncing = false;

  Future<void> _sincronizar() async {
    if (_syncing) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _syncing = true);
    try {
      final manager = ref.read(syncManagerProvider);
      await manager.syncPending();
      await manager.pullRemoteChanges();
      await manager.refreshPendingCount();
      final pendientes = ref.read(syncPendingCountProvider).value ?? 0;
      messenger.showSnackBar(SnackBar(
        content: Text(pendientes == 0 ? 'Todo está subido' : 'Sin conexión con el servidor: se subirá luego'),
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Sin conexión: se sincronizará luego')));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final pendientes = ref.read(syncPendingCountProvider).value ?? 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: Text(
          pendientes == 0
              ? '¿Salir de tu cuenta en este teléfono?'
              : 'Tienes $pendientes cambio${pendientes == 1 ? '' : 's'} sin subir al servidor. '
                  'Se quedan guardados en el teléfono. ¿Salir igual?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  Future<void> _elegirDiasAviso() async {
    final actual = ref.read(diasAvisoDespachoProvider);
    final elegido = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Avisar si un despacho no llega al mercado en…', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in opcionesDiasAviso)
                    MiniChip(label: '$d días', large: true, selected: d == actual, onTap: () => Navigator.of(ctx).pop(d)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (elegido != null) await ref.read(diasAvisoDespachoProvider.notifier).set(elegido);
  }

  Future<void> _editarTopo() async {
    final texto = await showTextInputDialog(
      context,
      title: 'Tamaño del topo en tu zona',
      initial: ref.read(m2PorTopoProvider).toStringAsFixed(0),
      suffix: 'm²',
      help: 'Sirve para comparar terrenos medidos en topos y en hectáreas.',
      confirmLabel: 'Guardar',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    final valor = double.tryParse((texto ?? '').replaceAll(',', '.'));
    if (valor != null && valor > 0) await ref.read(m2PorTopoProvider.notifier).set(valor);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final user = ref.watch(authProvider).user;
    final pendientes = ref.watch(syncPendingCountProvider).value ?? 0;
    final campanas = ref.watch(campanaListProvider).campanas;
    final activas = campanas.where((c) => !c.isClosed).length;
    final terrenos = ref.watch(terrenosProvider).value?.length ?? 0;
    final modo = ref.watch(themeModeProvider);

    return AgroBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GlassCircleButton(icon: Icons.arrow_back_rounded, tooltip: 'Volver', onPressed: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 12),
                  Text('Perfil', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            GlassCard(
              highlight: true,
              radius: 24,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(gradient: AppColors.ctaGradient, shape: BoxShape.circle),
                    child: Text(user?.initials ?? '?', style: text.titleLarge?.copyWith(color: AppColors.onAccent, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.nombreCompleto ?? 'Agricultor', style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(user?.email ?? '', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        _Pill(
                          icon: (user?.isPremium ?? false) ? Icons.workspace_premium_rounded : Icons.eco_outlined,
                          label: (user?.isPremium ?? false) ? 'Plan Premium' : 'Plan Gratuito',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Tu campo'),
            _Group(children: [
              _Tile(
                icon: Icons.eco_rounded,
                title: 'Mis campañas',
                subtitle: '$activas activa${activas == 1 ? '' : 's'} · ${campanas.length} en total',
                onTap: () => context.go('/campanas'),
              ),
              _Tile(
                icon: Icons.landscape_rounded,
                title: 'Mis terrenos',
                subtitle: terrenos == 0 ? 'Aún no hay terrenos' : '$terrenos terreno${terrenos == 1 ? '' : 's'}',
                onTap: () => context.push('/terrenos'),
              ),
              _Tile(
                icon: Icons.grid_on_rounded,
                title: 'Plantillas de cultivo',
                subtitle: 'Calidades, filas y envase de la hoja',
                onTap: () => context.push('/plantillas'),
              ),
              _Tile(
                icon: Icons.add_circle_outline_rounded,
                title: 'Nueva campaña',
                onTap: () => context.push('/nueva-campana'),
              ),
            ]),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Sincronización'),
            _Group(children: [
              _Tile(
                icon: pendientes == 0 ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
                iconColor: pendientes == 0 ? AppColors.accent : AppColors.warning,
                title: pendientes == 0 ? 'Todo está subido' : '$pendientes cambio${pendientes == 1 ? '' : 's'} por subir',
                subtitle: 'Todo se guarda primero en el teléfono',
                trailing: _syncing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Sincronizar', style: text.labelMedium?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
                onTap: _sincronizar,
              ),
            ]),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Preferencias'),
            _Group(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apariencia', style: text.titleSmall),
                    const SizedBox(height: 10),
                    OptionTiles<ThemeMode>(
                      options: const [
                        (ThemeMode.light, 'Claro', Icons.light_mode_rounded),
                        (ThemeMode.dark, 'Oscuro', Icons.dark_mode_rounded),
                        (ThemeMode.system, 'Del teléfono', Icons.phone_android_rounded),
                      ],
                      selected: modo,
                      onSelected: (m) => ref.read(themeModeProvider.notifier).set(m),
                    ),
                  ],
                ),
              ),
              _Tile(
                icon: Icons.local_shipping_outlined,
                title: 'Avisar despacho demorado',
                subtitle: 'Si no llega al mercado en ${ref.watch(diasAvisoDespachoProvider)} días',
                onTap: _elegirDiasAviso,
              ),
              _Tile(
                icon: Icons.square_foot_rounded,
                title: 'Tamaño del topo',
                subtitle: '1 topo = ${ref.watch(m2PorTopoProvider).toStringAsFixed(0)} m² en tu zona',
                onTap: _editarTopo,
              ),
            ]),
            const SizedBox(height: 28),
            AgroActionButton(label: 'Cerrar sesión', icon: Icons.logout_rounded, onPressed: _cerrarSesion),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Grupo de filas dentro de una tarjeta, separadas por una línea.
class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.cardBorder),
            c,
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.title, required this.onTap, this.subtitle, this.trailing, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: iconColor ?? AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall),
                  if (subtitle != null) Text(subtitle!, style: text.bodySmall),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }
}
