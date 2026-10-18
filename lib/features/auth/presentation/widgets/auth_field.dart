import 'package:flutter/material.dart';

/// Campo con etiqueta arriba e icono a la izquierda.
class AuthField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboard;
  final TextInputAction? action;
  final TextCapitalization capitalization;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.keyboard,
    this.action,
    this.capitalization = TextCapitalization.none,
    this.obscure = false,
    this.onToggleObscure,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          textInputAction: action,
          textCapitalization: capitalization,
          obscureText: obscure,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    tooltip: obscure ? 'Mostrar' : 'Ocultar',
                    onPressed: onToggleObscure,
                    icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
          ),
        ),
      ],
    );
  }
}
