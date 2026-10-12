import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';

/// Pantalla de arranque: abre la base local, verifica la sesión y decide
/// a dónde ir. Los mensajes de progreso reflejan esos pasos reales.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();
  String _status = 'Abriendo la base de datos del teléfono…';
  double _progress = 0.15;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _step(String status, double progress) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _progress = progress;
    });
  }

  Future<void> _start() async {
    // Tiempo mínimo para que el logo no parpadee.
    final minimo = Future<void>.delayed(const Duration(milliseconds: 1400));
    try {
      await AppDatabase.database;
    } catch (e) {
      // No se bloquea el arranque: el error aparecerá en la pantalla que use la base.
      debugPrint('No se pudo abrir la base local: $e');
    }
    _step('Verificando tu sesión…', 0.6);
    await ref.read(authProvider.notifier).checkAuth();
    _step('Listo para trabajar', 1);
    await minimo;
    if (!mounted) return;
    context.go(ref.read(authProvider).isAuthenticated ? '/campanas' : '/login');
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AgroBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Pill(icon: Icons.cloud_off_rounded, label: 'Funciona sin internet'),
                ),
                const Spacer(),
                const AppEmblem(size: 112),
                const SizedBox(height: 28),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('AgroControl', style: text.headlineLarge),
                    const SizedBox(width: 6),
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.7), blurRadius: 8)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Tu campaña, en números', style: text.titleMedium?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 18),
                _Pill(icon: Icons.verified_outlined, label: 'Cuaderno de campo digital'),
                const Spacer(),
                GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final activo = (_pulse.value * 3).floor();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < 3; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: i == activo ? 1 : 0.3),
                                    shape: BoxShape.circle,
                                    boxShadow: i == activo
                                        ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.6), blurRadius: 10)]
                                        : null,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(_status, style: text.bodySmall, textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: _progress),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, _) => Container(
                            height: 4,
                            color: AppColors.track,
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: value,
                              child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.progressGradient)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Hecho para el campo peruano 🇵🇪', style: text.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Emblema de la app: hoja en una tarjeta de vidrio con brillo.
class AppEmblem extends StatelessWidget {
  final double size;

  const AppEmblem({super.key, this.size = 112});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: AppColors.cardBorderStrong),
        boxShadow: [BoxShadow(color: AppColors.palette.ctaGlow, blurRadius: size * 0.35, spreadRadius: -size * 0.04)],
      ),
      child: ShaderMask(
        shaderCallback: (rect) => AppColors.ctaGradient.createShader(rect),
        child: Icon(Icons.eco_rounded, size: size * 0.5, color: Colors.white),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.text, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
