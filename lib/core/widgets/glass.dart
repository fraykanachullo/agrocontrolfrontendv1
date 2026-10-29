import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Fondo con los halos de luz del diseño (según el modo activo).
class AgroBackground extends StatelessWidget {
  final Widget child;

  const AgroBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = AppColors.palette;
    return DecoratedBox(
      decoration: BoxDecoration(color: p.background),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.75, -0.8),
                  radius: 1.3,
                  colors: [p.glowA, p.glowA.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.7, 0),
                  radius: 1.2,
                  colors: [p.glowB, p.glowB.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          // Modo oscuro: viñeteado abajo para dar profundidad.
          if (p.isDark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.45)],
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Tarjeta "glass": degradado suave, borde tenue y esquinas amplias.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool highlight;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 20,
    this.highlight = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: shape,
        border: Border.all(
          color: highlight ? AppColors.cardBorderStrong : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: highlight ? AppColors.palette.highlightShadow : AppColors.palette.cardShadow,
            blurRadius: highlight ? 30 : 20,
            spreadRadius: highlight ? -10 : -8,
            offset: Offset(0, highlight ? 10 : 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Botón circular para acciones secundarias de cabecera.
class GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool showBadge;
  final double size;

  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.showBadge = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorderStrong.withValues(alpha: 0.4)),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 18, color: AppColors.textMuted),
                if (showBadge)
                  Positioned(
                    top: size * 0.22,
                    right: size * 0.22,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de acción. `primary` = degradado de acento con brillo; si no, satinado.
class AgroActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
  final double height;

  const AgroActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? AppColors.onAccent : AppColors.text;
    final shape = BorderRadius.circular(16);

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: primary ? AppColors.ctaGradient : AppColors.buttonGradient,
        borderRadius: shape,
        border: primary ? null : Border.all(color: AppColors.cardBorderStrong.withValues(alpha: 0.6)),
        boxShadow: primary
            ? [
                BoxShadow(
                  color: AppColors.palette.ctaGlow,
                  blurRadius: 25,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: shape,
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: primary ? AppColors.onAccent : AppColors.accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: primary ? FontWeight.w800 : FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado de sección en mayúsculas con acción opcional a la derecha.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: text.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: text.labelMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cuadrícula cuyas filas toman el alto de su contenido (no un alto
/// proporcional al ancho): no se desborda en pantallas angostas ni con la
/// letra agrandada. Las tarjetas de una misma fila quedan del mismo alto.
class GrillaAjustada extends StatelessWidget {
  final int columnas;
  final double espacio;
  final List<Widget> children;

  const GrillaAjustada({super.key, required this.columnas, this.espacio = 10, required this.children});

  @override
  Widget build(BuildContext context) {
    final filas = [for (var i = 0; i < children.length; i += columnas) children.sublist(i, (i + columnas).clamp(0, children.length))];
    return Column(
      children: [
        for (final (f, fila) in filas.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: f < filas.length - 1 ? espacio : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < columnas; c++) ...[
                    if (c > 0) SizedBox(width: espacio),
                    Expanded(child: c < fila.length ? fila[c] : const SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
