import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _initAuth();
  }

  Future<void> _initAuth() async {
    // Wait for animation to show at least a bit
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Check auth state
    await ref.read(authProvider.notifier).checkAuth();

    if (!mounted) return;
    final authState = ref.read(authProvider);

    if (authState.isAuthenticated) {
      context.go('/campanas');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryContainer,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    AppColors.primaryContainer.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          FadeTransition(
            opacity: _fadeScale,
            child: ScaleTransition(
              scale:
                  Tween<double>(begin: 0.95, end: 1.0).animate(_fadeScale),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.eco,
                        size: 72,
                        color: AppColors.surfaceContainerLowest,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'AgroControl',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                            color: AppColors.surfaceContainerLowest,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.secondaryContainer.withValues(alpha: 0.8),
                    ),
                    backgroundColor: AppColors.surfaceContainerLowest
                        .withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'INICIALIZANDO SISTEMA',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.surfaceContainerLowest
                            .withValues(alpha: 0.7),
                        letterSpacing: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
