import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/agro_control_app_bar.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _darkMode = false;
  String _unidad = 'Hectáreas (ha)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AgroControlAppBar(
        showBackButton: true,
        title: 'Configuración',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            _buildUserInfoCard(context),
            const SizedBox(height: 24),

            // Campaña Section
            _buildSectionHeader(context, 'Campaña'),
            _buildMenuCard(context, [
              _MenuTile(
                icon: Icons.agriculture,
                iconBg: AppColors.primaryContainer.withValues(alpha: 0.2),
                iconColor: AppColors.primary,
                title: 'Mis Campañas',
                onTap: () => context.go('/campanas'),
              ),
              _MenuTile(
                icon: Icons.add_circle,
                iconBg: AppColors.surfaceContainer,
                iconColor: AppColors.onSurfaceVariant,
                title: 'Nueva Campaña',
                onTap: () => context.push('/nueva-campana'),
              ),
            ]),
            const SizedBox(height: 24),

            // Premium Section
            _buildSectionHeader(context, 'Premium'),
            _buildMenuCard(context, [
              _MenuTile(
                icon: Icons.cloud_sync,
                iconBg: AppColors.secondaryContainer.withValues(alpha: 0.2),
                iconColor: AppColors.secondary,
                title: 'Sincronizar Ahora',
                onTap: () => _showSnackBar('Sincronizando datos...'),
              ),
              _MenuTile(
                icon: Icons.ios_share,
                iconBg: AppColors.surfaceContainer,
                iconColor: AppColors.onSurfaceVariant,
                title: 'Exportar Reportes',
                onTap: () => _showSnackBar('Preparando exportación...'),
              ),
              _MenuTile(
                icon: Icons.group_add,
                iconBg: AppColors.surfaceContainer,
                iconColor: AppColors.onSurfaceVariant,
                title: 'Invitar Colaboradores',
                onTap: () => _showSnackBar('Función próximamente'),
              ),
            ]),
            const SizedBox(height: 24),

            // Configuración Section
            _buildSectionHeader(context, 'Configuración'),
            _buildMenuCard(context, [
              _MenuTile(
                icon: Icons.straighten,
                iconBg: AppColors.surfaceContainer,
                iconColor: AppColors.onSurfaceVariant,
                title: 'Cambiar Unidad',
                trailing: Text(
                  _unidad,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                onTap: () => _showUnitDialog(),
              ),
              _MenuTile(
                icon: Icons.dark_mode,
                iconBg: AppColors.surfaceContainer,
                iconColor: AppColors.onSurfaceVariant,
                title: 'Tema Oscuro',
                trailing: Switch(
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
                  activeThumbColor: AppColors.primary,
                ),
                onTap: () => setState(() => _darkMode = !_darkMode),
              ),
              _MenuTile(
                icon: Icons.help,
                iconBg: AppColors.surfaceContainer,
                iconColor: AppColors.onSurfaceVariant,
                title: 'Ayuda y Soporte',
                onTap: () => _showSnackBar('Soporte: soporte@agrocontrol.com'),
              ),
            ]),
            const SizedBox(height: 32),

            // Logout Button
            _buildLogoutButton(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryContainer,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agricultor Test',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 20,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'agricultor@test.com',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: AppColors.onSecondaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        'Plan: Premium',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.onSecondaryContainer,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
            ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<_MenuTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: List.generate(tiles.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Divider(
              height: 1,
              indent: 68,
              color: AppColors.surfaceDim,
            );
          }
          return tiles[index ~/ 2];
        }),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.go('/login'),
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: Text(
          'Cerrar Sesión',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.error,
              ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: AppColors.error.withValues(alpha: 0.2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unidad de medida'),
        content: RadioGroup<String>(
          groupValue: _unidad,
          onChanged: (v) {
            setState(() => _unidad = v!);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Hectáreas (ha)', 'Topos', 'm²'].map((u) {
              return RadioListTile<String>(
                title: Text(u),
                value: u,
                activeColor: AppColors.primary,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (trailing != null) ...[trailing!],
            if (trailing == null)
              const Icon(Icons.chevron_right,
                  color: AppColors.outlineVariant),
          ],
        ),
      ),
    );
  }
}
