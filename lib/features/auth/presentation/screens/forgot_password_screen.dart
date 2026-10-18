import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/glass.dart';
import '../widgets/auth_field.dart';

/// Recuperar contraseña en dos pasos: pedir el código al correo y
/// escribirlo junto con la nueva contraseña. Necesita internet.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _codigoEnviado = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_emailCtrl, _codigoCtrl, _passwordCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _error(String fallback) {
    final error = ref.read(authProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? fallback)));
    ref.read(authProvider.notifier).clearError();
  }

  Future<void> _enviarCodigo() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final ok = await ref.read(authProvider.notifier).forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _codigoEnviado = ok;
    });
    if (!ok) _error('No se pudo enviar el código. Revisa tu conexión.');
  }

  Future<void> _restablecer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final ok = await ref.read(authProvider.notifier).resetPassword(
          email: _emailCtrl.text.trim(),
          token: _codigoCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña cambiada. Ingresa con la nueva.')),
      );
      context.go('/login');
    } else {
      _error('No se pudo cambiar la contraseña. Revisa el código.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AgroBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  GlassCircleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Volver',
                    onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
                  ),
                  const SizedBox(width: 12),
                  Text('Recuperar contraseña', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 22),
              _Pasos(paso: _codigoEnviado ? 2 : 1),
              const SizedBox(height: 16),
              GlassCard(
                highlight: true,
                radius: 28,
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_codigoEnviado ? 'Crea tu nueva contraseña' : '¿Olvidaste tu contraseña?', style: text.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        _codigoEnviado
                            ? 'Te enviamos un código a ${_emailCtrl.text.trim()}. Escríbelo aquí.'
                            : 'Escribe tu correo y te enviaremos un código para cambiarla.',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Correo electrónico',
                        icon: Icons.mail_outline_rounded,
                        controller: _emailCtrl,
                        hint: 'tu@correo.com',
                        keyboard: TextInputType.emailAddress,
                        action: _codigoEnviado ? TextInputAction.next : TextInputAction.done,
                        onSubmitted: _codigoEnviado ? null : (_) => _enviarCodigo(),
                        validator: AppValidators.email,
                      ),
                      if (_codigoEnviado) ...[
                        const SizedBox(height: 14),
                        AuthField(
                          label: 'Código del correo',
                          icon: Icons.pin_outlined,
                          controller: _codigoCtrl,
                          hint: 'Copia el código que te llegó',
                          action: TextInputAction.next,
                          validator: AppValidators.required('El código'),
                        ),
                        const SizedBox(height: 14),
                        AuthField(
                          label: 'Nueva contraseña',
                          icon: Icons.lock_outline_rounded,
                          controller: _passwordCtrl,
                          hint: 'Mínimo 8 caracteres',
                          obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          action: TextInputAction.next,
                          validator: AppValidators.password,
                        ),
                        const SizedBox(height: 14),
                        AuthField(
                          label: 'Repite la contraseña',
                          icon: Icons.lock_reset_rounded,
                          controller: _confirmCtrl,
                          hint: 'La misma contraseña',
                          obscure: _obscure,
                          action: TextInputAction.done,
                          onSubmitted: (_) => _restablecer(),
                          validator: (v) => v != _passwordCtrl.text ? 'Las contraseñas no coinciden' : null,
                        ),
                      ],
                      const SizedBox(height: 20),
                      AgroActionButton(
                        label: _loading
                            ? (_codigoEnviado ? 'Cambiando…' : 'Enviando…')
                            : (_codigoEnviado ? 'Cambiar contraseña' : 'Enviar código'),
                        icon: _codigoEnviado ? Icons.check_rounded : Icons.send_rounded,
                        primary: true,
                        height: 56,
                        onPressed: _loading ? () {} : (_codigoEnviado ? _restablecer : _enviarCodigo),
                      ),
                      if (_codigoEnviado)
                        TextButton(
                          onPressed: _loading ? null : _enviarCodigo,
                          child: const Text('No me llegó: enviar otro código'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.wifi_rounded, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Este paso necesita internet. Revisa también tu carpeta de spam.', style: text.bodySmall),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador de los dos pasos: pedir código y cambiar contraseña.
class _Pasos extends StatelessWidget {
  final int paso;

  const _Pasos({required this.paso});

  @override
  Widget build(BuildContext context) {
    Widget punto(int n, String label) {
      final activo = n <= paso;
      return Expanded(
        child: Column(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: activo ? AppColors.progressGradient : null,
                color: activo ? null : AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: n == paso ? AppColors.accent : AppColors.textSubtle,
                    fontWeight: n == paso ? FontWeight.w800 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        punto(1, '1. Pedir código'),
        const SizedBox(width: 8),
        punto(2, '2. Nueva contraseña'),
      ],
    );
  }
}
