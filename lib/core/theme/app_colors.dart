import 'package:flutter/material.dart';
import 'agro_palette.dart';

/// Acceso a los colores del modo visual activo (claro u oscuro).
///
/// `AgroApp` llama a [use] al construir el tema y fuerza la reconstrucción
/// de las pantallas al cambiar de modo, por eso los getters siempre
/// devuelven la paleta vigente. Como son valores en tiempo de ejecución,
/// no pueden usarse dentro de expresiones `const`.
abstract final class AppColors {
  static AgroPalette _p = AgroPalette.dark;

  static AgroPalette get palette => _p;
  static void use(AgroPalette palette) => _p = palette;

  static ColorScheme get _s => _p.scheme;

  // ── Tokens del diseño ──
  static Color get background => _p.background;
  static Color get text => _s.onSurface;
  static Color get textMuted => _s.onSurfaceVariant;
  static Color get textSubtle => _p.textSubtle;
  static Color get accent => _s.primary;
  static Color get onAccent => _s.onPrimary;
  static Color get accentSoft => _p.accentSoft;
  static Color get live => _p.live;
  static Color get card => _s.surfaceContainer;
  static Color get cardBorder => _p.cardBorder;
  static Color get cardBorderStrong => _p.cardBorderStrong;
  static Color get positive => _p.positive;
  static Color get expense => _p.expense;
  static Color get warning => _p.warning;
  static Color get info => _p.info;
  static Color get track => _p.track;
  static Color get chartIngreso => _p.chartIngreso;
  static Color get chartGasto => _p.chartGasto;
  static Color get chartGanancia => _p.chartGanancia;
  static LinearGradient get ctaGradient => _p.cta;
  static LinearGradient get progressGradient => _p.progress;

  static LinearGradient get cardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_p.cardTop, _p.cardBottom],
      );

  static LinearGradient get buttonGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_p.buttonTop, _p.buttonBottom],
      );

  // ── Roles de Material (pantallas existentes) ──
  static Color get primary => _s.primary;
  static Color get onPrimary => _s.onPrimary;
  static Color get primaryContainer => _s.primaryContainer;
  static Color get onPrimaryContainer => _s.onPrimaryContainer;
  static Color get primaryFixed => _s.primaryFixed;
  static Color get primaryFixedDim => _s.primaryFixedDim;
  static Color get onPrimaryFixed => _s.onPrimaryFixed;
  static Color get onPrimaryFixedVariant => _s.onPrimaryFixedVariant;
  static Color get surfaceTint => _s.primary;
  static Color get inversePrimary => _s.inversePrimary;

  static Color get secondary => _s.secondary;
  static Color get onSecondary => _s.onSecondary;
  static Color get secondaryContainer => _s.secondaryContainer;
  static Color get onSecondaryContainer => _s.onSecondaryContainer;
  static Color get secondaryFixed => _s.secondaryFixed;
  static Color get secondaryFixedDim => _s.secondaryFixedDim;
  static Color get onSecondaryFixed => _s.onSecondaryFixed;
  static Color get onSecondaryFixedVariant => _s.onSecondaryFixedVariant;

  static Color get tertiary => _s.tertiary;
  static Color get onTertiary => _s.onTertiary;
  static Color get tertiaryContainer => _s.tertiaryContainer;
  static Color get onTertiaryContainer => _s.onTertiaryContainer;

  static Color get surface => _s.surface;
  static Color get surfaceLight => _s.surfaceContainerLow;
  static Color get surfaceContainerLowest => _s.surfaceContainerLowest;
  static Color get surfaceContainerLow => _s.surfaceContainerLow;
  static Color get surfaceContainer => _s.surfaceContainer;
  static Color get surfaceContainerHigh => _s.surfaceContainerHigh;
  static Color get surfaceContainerHighest => _s.surfaceContainerHighest;
  static Color get surfaceDim => _s.surfaceDim;
  static Color get surfaceBright => _s.surfaceBright;
  static Color get surfaceVariant => _s.surfaceContainerHighest;
  static Color get onSurface => _s.onSurface;
  static Color get onSurfaceVariant => _s.onSurfaceVariant;
  static Color get inverseSurface => _s.inverseSurface;
  static Color get inverseOnSurface => _s.onInverseSurface;
  static Color get onBackground => _s.onSurface;

  static Color get outline => _s.outline;
  static Color get outlineVariant => _s.outlineVariant;

  static Color get error => _s.error;
  static Color get onError => _s.onError;
  static Color get errorContainer => _s.errorContainer;
  static Color get onErrorContainer => _s.onErrorContainer;

  static Color get statusActive => _p.positive;
  static Color get statusPending => _p.warning;
  static Color get statusClosed => _p.textSubtle;
}
