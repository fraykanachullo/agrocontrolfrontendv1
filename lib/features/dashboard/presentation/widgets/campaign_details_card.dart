import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/campanas/domain/entities/campana.dart';

class CampaignDetailsCard extends StatelessWidget {
  final Campana? campana;

  const CampaignDetailsCard({super.key, this.campana});

  @override
  Widget build(BuildContext context) {
    final isActive = campana?.estado == 'activa';
    final cultivo = campana?.cultivo ?? '---';
    final extension = campana?.extensionDisplay ?? '---';
    final lat = campana?.latitud;
    final lng = campana?.longitud;
    final ubicacion = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}'
        : 'Sin ubicación';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Campaña Actual',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              _buildStatusBadge(context, isActive),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            context,
            icon: Icons.eco,
            iconBg: AppColors.primaryContainer,
            iconColor: AppColors.onPrimaryContainer,
            label: 'Cultivo',
            value: cultivo[0].toUpperCase() + cultivo.substring(1),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            icon: Icons.aspect_ratio,
            iconBg: AppColors.surfaceContainerHigh,
            iconColor: AppColors.onSurfaceVariant,
            label: 'Área Plantada',
            value: extension,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            icon: Icons.location_on,
            iconBg: AppColors.surfaceContainerHigh,
            iconColor: AppColors.onSurfaceVariant,
            label: 'Ubicación',
            value: ubicacion,
            isMono: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.statusActive : AppColors.statusClosed)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppColors.statusActive : AppColors.statusClosed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Activa' : 'Cerrada',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive ? AppColors.statusActive : AppColors.statusClosed,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    bool isMono = false,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: isMono ? 'monospace' : null,
                      fontSize: isMono ? 14 : null,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
