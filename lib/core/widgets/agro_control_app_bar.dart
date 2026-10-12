import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../providers/app_providers.dart';
import 'sync_indicator.dart';

class AgroControlAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final String? title;
  final String? campaignName;
  final String? campaignId;

  const AgroControlAppBar({
    super.key,
    this.showBackButton = false,
    this.title,
    this.campaignName,
    this.campaignId,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final initials = user?.initials ?? 'AT';

    return AppBar(
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : IconButton(
              icon: const Icon(Icons.eco),
              onPressed: () {},
            ),
      title: Text(
        title ?? campaignName ?? 'AgroControl',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: campaignName != null ? 18 : 24,
              height: campaignName != null ? 24 / 18 : 32 / 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
      ),
      centerTitle: true,
      actions: [
        if (!showBackButton) ...[
          const SyncIndicator(),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar',
            onPressed: () async {
              final manager = ref.read(syncManagerProvider);
              await manager.syncPending();
              await manager.pullRemoteChanges();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sincronización completada')),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.push('/perfil'),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
