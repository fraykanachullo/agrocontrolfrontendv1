import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DispatchForm extends StatelessWidget {
  const DispatchForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.local_shipping, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Nuevo Despacho',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Form card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceContainer),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Cantidad + Fecha
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      context,
                      label: 'Cantidad (Javas)',
                      hint: 'Ej. 100',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Conductor
              _buildTextField(
                context,
                label: 'Conductor / Transportista',
                hint: 'Nombre del conductor',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),

              // Mercado destino
              _buildDropdownField(context),
              const SizedBox(height: 20),

              // Submit
              _buildSubmitButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        TextFormField(
          keyboardType: keyboardType,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, size: 20)
                : null,
            prefixIconConstraints: icon != null
                ? const BoxConstraints(minWidth: 48, minHeight: 48)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha Programada',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        TextFormField(
          readOnly: true,
          initialValue: '2026-07-15',
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }

  Widget _buildDropdownField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mercado Destino',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: 'lima_mayorista',
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.storefront, size: 20),
            prefixIconConstraints: BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          items: const [
            DropdownMenuItem(
              value: 'lima_mayorista',
              child: Text('Lima Mayorista'),
            ),
            DropdownMenuItem(
              value: 'mercado_central',
              child: Text('Mercado Central'),
            ),
            DropdownMenuItem(
              value: 'exportacion',
              child: Text('Planta de Exportación'),
            ),
          ],
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.check_circle, size: 20),
        label: const Text('REGISTRAR DESPACHO'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
