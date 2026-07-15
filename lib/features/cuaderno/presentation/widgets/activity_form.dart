import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ActivityForm extends StatelessWidget {
  final String type;

  const ActivityForm({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
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
          // Header
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceContainerHigh),
              ),
            ),
            child: Text(
              'Nueva $type',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // Date field
          _buildDateField(context),
          const SizedBox(height: 16),

          // Description field
          _buildDescriptionField(context),
          const SizedBox(height: 16),

          // Photo button
          _buildPhotoButton(context),
          const SizedBox(height: 12),

          // Submit button
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        TextFormField(
          readOnly: true,
          initialValue: '2026-07-15',
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_today, size: 20),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        TextFormField(
          maxLines: 3,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: const InputDecoration(
            hintText: 'Detalle de la actividad...',
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.photo_camera, size: 20),
        label: const Text('Tomar Foto'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSecondaryContainer,
          backgroundColor: AppColors.secondaryContainer,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'REGISTRAR',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
