import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// Barra de navegación flotante de vidrio. Todas las pestañas muestran
/// icono y nombre; la activa se resalta con el color de acento.
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final String campaignId;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.campaignId,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio', () => context.go('/c/$campaignId/inicio')),
      _NavItem(Icons.menu_book_outlined, Icons.menu_book, 'Cuaderno', () => context.go('/c/$campaignId/cuaderno')),
      _NavItem(Icons.local_shipping_outlined, Icons.local_shipping, 'Cosechas', () => context.go('/c/$campaignId/cosechas')),
      _NavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Resumen', () => context.go('/c/$campaignId/resumen')),
      _NavItem(Icons.manage_accounts_outlined, Icons.manage_accounts, 'Perfil', () => context.push('/perfil')),
    ];
    final palette = AppColors.palette;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: palette.highlightShadow,
              blurRadius: 40,
              spreadRadius: -8,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              decoration: BoxDecoration(
                color: palette.navBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(child: _NavButton(item: items[i], selected: i == selectedIndex)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  const _NavItem(this.icon, this.activeIcon, this.label, this.onTap);
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;

  const _NavButton({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textMuted;

    return Semantics(
      label: item.label,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: selected ? null : item.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? item.activeIcon : item.icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
