import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/glass.dart';
import '../../../splash/presentation/screens/splash_screen.dart' show AppEmblem;
import '../widgets/auth_field.dart';

/// Ingresar y registrarse (S02) en una sola pantalla con pestañas.
class AuthScreen extends ConsumerStatefulWidget {
  final bool startOnRegister;

  const AuthScreen({super.key, this.startOnRegister = false});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _register = widget.startOnRegister;
  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _emailCtrl, _passwordCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _switch(bool register) {
    if (register == _register) return;
    FocusScope.of(context).unfocus();
    setState(() => _register = register);
  }

  void _login() {
    if (!(_loginKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passwordCtrl.text);
  }

  Future<void> _createAccount() async {
    if (!(_registerKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).register(
          nombre: _nombreCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final loading = ref.watch(authProvider).isLoading;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        context.go('/campanas');
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
        ref.read(authProvider.notifier).clearError();
      }
    });

    return AgroBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _Brand(onToggleTheme: () => ref.read(themeModeProvider.notifier).toggle(AppColors.palette.brightness)),
              const SizedBox(height: 22),
              GlassCard(
                highlight: true,
                radius: 28,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Tabs(register: _register, onChanged: _switch),
                    const SizedBox(height: 20),
                    Text(_register ? 'Crea tu cuenta' : 'Bienvenido de vuelta', style: text.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      _register ? 'Registra tus campañas y controla tus costos' : 'Gestiona tu cuaderno de campo y tus cosechas',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _register ? _registerForm(loading) : _loginForm(loading),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.cloud_off_rounded, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trabaja sin señal', style: text.titleSmall),
                          Text(
                            'Todo se guarda en tu teléfono y se respalda solo cuando vuelve el internet.',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
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

  Widget _loginForm(bool loading) {
    return Form(
      key: _loginKey,
      child: Column(
        key: const ValueKey('login'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthField(
            label: 'Correo electrónico',
            icon: Icons.mail_outline_rounded,
            controller: _emailCtrl,
            hint: 'tu@correo.com',
            keyboard: TextInputType.emailAddress,
            action: TextInputAction.next,
            validator: AppValidators.email,
          ),
          const SizedBox(height: 14),
          AuthField(
            label: 'Contraseña',
            icon: Icons.lock_outline_rounded,
            controller: _passwordCtrl,
            hint: 'Tu contraseña',
            obscure: _obscure,
            onToggleObscure: () => setState(() => _obscure = !_obscure),
            action: TextInputAction.done,
            onSubmitted: (_) => _login(),
            validator: (v) => (v == null || v.isEmpty) ? 'La contraseña es requerida' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 4),
          AgroActionButton(
            label: loading ? 'Ingresando…' : 'Ingresar a AgroControl',
            icon: Icons.arrow_forward_rounded,
            primary: true,
            height: 56,
            onPressed: loading ? () {} : _login,
          ),
        ],
      ),
    );
  }

  Widget _registerForm(bool loading) {
    return Form(
      key: _registerKey,
      child: Column(
        key: const ValueKey('register'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthField(
            label: 'Nombre completo',
            icon: Icons.badge_outlined,
            controller: _nombreCtrl,
            hint: 'Ej. Teófilo Quispe',
            capitalization: TextCapitalization.words,
            action: TextInputAction.next,
            validator: AppValidators.required('El nombre'),
          ),
          const SizedBox(height: 14),
          AuthField(
            label: 'Correo electrónico',
            icon: Icons.mail_outline_rounded,
            controller: _emailCtrl,
            hint: 'tu@correo.com',
            keyboard: TextInputType.emailAddress,
            action: TextInputAction.next,
            validator: AppValidators.email,
          ),
          const SizedBox(height: 14),
          AuthField(
            label: 'Contraseña',
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
            onSubmitted: (_) => _createAccount(),
            validator: (v) => v != _passwordCtrl.text ? 'Las contraseñas no coinciden' : null,
          ),
          const SizedBox(height: 20),
          AgroActionButton(
            label: loading ? 'Creando cuenta…' : 'Crear mi cuenta',
            icon: Icons.how_to_reg_rounded,
            primary: true,
            height: 56,
            onPressed: loading ? () {} : _createAccount,
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const _Brand({required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        const AppEmblem(size: 54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AgroControl', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text('Tu campaña, en números', style: text.bodySmall),
            ],
          ),
        ),
        GlassCircleButton(
          icon: AppColors.palette.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          tooltip: AppColors.palette.isDark ? 'Modo claro' : 'Modo oscuro',
          onPressed: onToggleTheme,
        ),
      ],
    );
  }
}

/// Selector Ingresar / Registrarse.
class _Tabs extends StatelessWidget {
  final bool register;
  final ValueChanged<bool> onChanged;

  const _Tabs({required this.register, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget tab(bool value, IconData icon, String label) {
      final selected = value == register;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 46,
            decoration: BoxDecoration(
              gradient: selected ? AppColors.ctaGradient : null,
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected ? [BoxShadow(color: AppColors.palette.ctaGlow, blurRadius: 14, spreadRadius: -4)] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: selected ? AppColors.onAccent : AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? AppColors.onAccent : AppColors.textMuted,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          tab(false, Icons.login_rounded, 'Ingresar'),
          tab(true, Icons.person_add_alt_rounded, 'Registrarse'),
        ],
      ),
    );
  }
}
