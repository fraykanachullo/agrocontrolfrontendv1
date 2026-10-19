import 'package:flutter/material.dart';

/// Paleta completa de un modo visual (claro u oscuro).
///
/// `scheme` cubre los roles de Material; el resto son los tokens propios del
/// diseño (tarjetas de vidrio, halos, montos, barra de navegación…).
@immutable
class AgroPalette {
  final ColorScheme scheme;

  // Fondo
  final Color background;
  final Color glowA;
  final Color glowB;

  // Tarjetas y botones secundarios
  final Color cardTop;
  final Color cardBottom;
  final Color cardBorder;
  final Color cardBorderStrong;
  final Color cardShadow;
  final Color highlightShadow;
  final Color buttonTop;
  final Color buttonBottom;

  // Acentos
  final LinearGradient cta;
  final Color ctaGlow;

  /// Exclusivo de barras de progreso (avance de etapa, carga…): lima / neón.
  final LinearGradient progress;
  final Color accentSoft;
  final Color live;

  // Texto y montos
  final Color textSubtle;
  final Color positive;
  final Color expense;
  final Color warning;
  final Color info;

  // Otros
  final Color track;
  final Color navBackground;

  /// Fondo de los formularios y hojas inferiores: en oscuro, un verde algo
  /// más claro que el fondo para que no canse la vista.
  final Color sheet;

  const AgroPalette({
    required this.scheme,
    required this.background,
    required this.glowA,
    required this.glowB,
    required this.cardTop,
    required this.cardBottom,
    required this.cardBorder,
    required this.cardBorderStrong,
    required this.cardShadow,
    required this.highlightShadow,
    required this.buttonTop,
    required this.buttonBottom,
    required this.cta,
    required this.ctaGlow,
    required this.progress,
    required this.accentSoft,
    required this.live,
    required this.textSubtle,
    required this.positive,
    required this.expense,
    required this.warning,
    required this.info,
    required this.track,
    required this.navBackground,
    required this.sheet,
  });

  Brightness get brightness => scheme.brightness;
  bool get isDark => brightness == Brightness.dark;

  /// "Agro Dark": fondo bosque casi negro, tarjetas oliva grisáceo, acento menta y progreso lima.
  static const dark = AgroPalette(
    scheme: ColorScheme(
      brightness: Brightness.dark,
      // Acento (10 %): menta brillante solo para acciones prioritarias.
      primary: Color(0xFF20E3B2),
      onPrimary: Color(0xFF04120D),
      primaryContainer: Color(0xFF1F3A30),
      onPrimaryContainer: Color(0xFF4EFEB3),
      primaryFixed: Color(0xFF4EFEB3),
      primaryFixedDim: Color(0xFF20E3B2),
      onPrimaryFixed: Color(0xFF04120D),
      onPrimaryFixedVariant: Color(0xFF010A06),
      secondary: Color(0xFFFBBF24),
      onSecondary: Color(0xFF04120D),
      secondaryContainer: Color(0xFF3A2E0B),
      onSecondaryContainer: Color(0xFFFCD34D),
      secondaryFixed: Color(0xFFFBBF24),
      secondaryFixedDim: Color(0xFFF59E0B),
      onSecondaryFixed: Color(0xFF04120D),
      onSecondaryFixedVariant: Color(0xFF3A2E0B),
      tertiary: Color(0xFFF0ABFC),
      onTertiary: Color(0xFF04120D),
      tertiaryContainer: Color(0xFF3B1640),
      onTertiaryContainer: Color(0xFFF5D0FE),
      tertiaryFixed: Color(0xFFF5D0FE),
      tertiaryFixedDim: Color(0xFFF0ABFC),
      onTertiaryFixed: Color(0xFF04120D),
      onTertiaryFixedVariant: Color(0xFF3B1640),
      error: Color(0xFFFB7185),
      onError: Color(0xFF04120D),
      errorContainer: Color(0xFF3B1219),
      onErrorContainer: Color(0xFFFDA4AF),
      // Fondo (60 %): casi negro con un toque de verde oscuro.
      surface: Color(0xFF010A06),
      // Texto: blanco suave para cifras y títulos; gris menta para lo secundario.
      onSurface: Color(0xFFF2F5F3),
      onSurfaceVariant: Color(0xFFA3B8AE),
      surfaceDim: Color(0xFF000604),
      surfaceBright: Color(0xFF24392F),
      // Tarjetas y paneles (30 %): verde oliva profundo, un tono sobre el fondo.
      surfaceContainerLowest: Color(0xFF05140E),
      surfaceContainerLow: Color(0xFF091B14),
      surfaceContainer: Color(0xFF0D1F17),
      surfaceContainerHigh: Color(0xFF192E25),
      surfaceContainerHighest: Color(0xFF20362C),
      outline: Color(0xFF74887E),
      outlineVariant: Color(0xFF1E352B),
      inverseSurface: Color(0xFFE6F4EF),
      onInverseSurface: Color(0xFF04120D),
      inversePrimary: Color(0xFF0D631B),
      surfaceTint: Colors.transparent,
    ),
    background: Color(0xFF010A06),
    // Brillo esmeralda arriba a la derecha y bruma verde a la izquierda:
    // dan profundidad sin aclarar el fondo.
    glowA: Color(0x4014B886),
    glowB: Color(0x99082A1E),
    cardTop: Color(0xFF0F2018),
    cardBottom: Color(0xFF07150F),
    cardBorder: Color(0x14FFFFFF),
    cardBorderStrong: Color(0x3320E3B2),
    cardShadow: Colors.transparent,
    highlightShadow: Color(0x99000000),
    buttonTop: Color(0xFF1C3229),
    buttonBottom: Color(0xFF13271F),
    cta: LinearGradient(colors: [Color(0xFF20E3B2), Color(0xFF4EFEB3)]),
    ctaGlow: Color(0x5520E3B2),
    progress: LinearGradient(colors: [Color(0xFFDDF33B), Color(0xFF8FE35A)]),
    accentSoft: Color(0xFF12291F),
    live: Color(0xFF38EF7D),
    textSubtle: Color(0xFF74887E),
    positive: Color(0xFF4EFEB3),
    expense: Color(0xFFFDA4AF),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF7DD3FC),
    track: Color(0x66000000),
    navBackground: Color(0xE6081610),
    sheet: Color(0xFF13241C),
  );

  /// "Botánico": salvia clara con verdes de hoja profundos.
  static const light = AgroPalette(
    scheme: ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF21492D),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFEBF2EB),
      onPrimaryContainer: Color(0xFF1A3723),
      primaryFixed: Color(0xFFD5E5D5),
      primaryFixedDim: Color(0xFFB0CEB1),
      onPrimaryFixed: Color(0xFF122618),
      onPrimaryFixedVariant: Color(0xFF21492D),
      secondary: Color(0xFFB45309),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFEF3C7),
      onSecondaryContainer: Color(0xFF92400E),
      secondaryFixed: Color(0xFFFDE68A),
      secondaryFixedDim: Color(0xFFFCD34D),
      onSecondaryFixed: Color(0xFF451A03),
      onSecondaryFixedVariant: Color(0xFF92400E),
      tertiary: Color(0xFF9D174D),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFCE7F3),
      onTertiaryContainer: Color(0xFF831843),
      tertiaryFixed: Color(0xFFFCE7F3),
      tertiaryFixedDim: Color(0xFFF9A8D4),
      onTertiaryFixed: Color(0xFF500724),
      onTertiaryFixedVariant: Color(0xFF9D174D),
      error: Color(0xFFBE123C),
      onError: Colors.white,
      errorContainer: Color(0xFFFFE4E6),
      onErrorContainer: Color(0xFF9F1239),
      surface: Colors.white,
      onSurface: Color(0xFF122618),
      onSurfaceVariant: Color(0xFF627A68),
      surfaceDim: Color(0xFFDCE7DC),
      surfaceBright: Colors.white,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFF5F8F5),
      surfaceContainer: Color(0xFFEBF2EB),
      surfaceContainerHigh: Color(0xFFE3EDE3),
      surfaceContainerHighest: Color(0xFFD5E5D5),
      outline: Color(0xFF8FA595),
      outlineVariant: Color(0xFFDCE7DC),
      inverseSurface: Color(0xFF1A3723),
      onInverseSurface: Color(0xFFF5F8F5),
      inversePrimary: Color(0xFFB0CEB1),
      surfaceTint: Colors.transparent,
    ),
    background: Color(0xFFF2F6F2),
    glowA: Color(0x406EE7B7),
    glowB: Color(0x00F2F6F2),
    cardTop: Colors.white,
    cardBottom: Color(0xFFF0F6F0),
    cardBorder: Color(0xFFE0EBE0),
    cardBorderStrong: Color(0xFFB0CEB1),
    cardShadow: Color(0x0F1C3B26),
    highlightShadow: Color(0x1F122618),
    buttonTop: Colors.white,
    buttonBottom: Color(0xFFF5F8F5),
    cta: LinearGradient(colors: [Color(0xFF21492D), Color(0xFF2C5E3A)]),
    ctaGlow: Color(0x3321492D),
    progress: LinearGradient(colors: [Color(0xFFA3C93A), Color(0xFF5E9E2E)]),
    accentSoft: Color(0xFFEFF5EF),
    live: Color(0xFF10B981),
    textSubtle: Color(0xFF7F9585),
    positive: Color(0xFF047857),
    expense: Color(0xFFBE123C),
    warning: Color(0xFFD97706),
    info: Color(0xFF2563EB),
    track: Color(0xFFDEE8DE),
    navBackground: Color(0xD1FFFFFF),
    sheet: Color(0xFFF2F6F2),
  );
}
