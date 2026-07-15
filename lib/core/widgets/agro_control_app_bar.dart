import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class AgroControlAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final String? title;

  const AgroControlAppBar({
    super.key,
    this.showBackButton = false,
    this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : IconButton(
              icon: const Icon(Icons.wifi),
              onPressed: () {},
            ),
      title: Text(
        title ?? 'AgroControl',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 24,
              height: 32 / 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
      ),
      centerTitle: true,
      actions: [
        if (!showBackButton) ...[
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.push('/perfil'),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'AT',
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
