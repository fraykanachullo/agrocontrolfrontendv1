import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'agro_palette.dart';

abstract final class AppTheme {
  /// Tipografía para cifras grandes (montos, KPI).
  static TextStyle display({
    double fontSize = 34,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: -0.5,
      );

  static final ThemeData dark = build(AgroPalette.dark);
  static final ThemeData light = build(AgroPalette.light);

  static ThemeData build(AgroPalette p) {
    final colorScheme = p.scheme;
    final ink = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final accent = colorScheme.primary;
    final onAccent = colorScheme.onPrimary;

    final base = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: p.brightness).textTheme,
    );

    // El espaciado se fija explícitamente: si queda nulo, Material aplica el
    // suyo por defecto (hasta 0.5) y Plus Jakarta se ve "estirada".
    TextStyle jakarta(double size, double height, FontWeight weight, Color color, [double spacing = 0]) =>
        GoogleFonts.plusJakartaSans(
          fontSize: size,
          height: height / size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing,
        );

    final textTheme = base.copyWith(
      headlineLarge: jakarta(32, 40, FontWeight.w800, ink, -0.8),
      headlineMedium: jakarta(24, 32, FontWeight.w700, ink, -0.5),
      headlineSmall: jakarta(20, 28, FontWeight.w700, ink, -0.4),
      titleLarge: jakarta(18, 26, FontWeight.w700, ink, -0.3),
      titleMedium: jakarta(16, 24, FontWeight.w600, ink, -0.2),
      titleSmall: jakarta(14, 20, FontWeight.w600, ink, -0.1),
      bodyLarge: jakarta(16, 24, FontWeight.w400, ink),
      bodyMedium: jakarta(14, 20, FontWeight.w400, ink),
      bodySmall: jakarta(12, 16, FontWeight.w400, muted),
      labelLarge: jakarta(14, 18, FontWeight.w600, ink, -0.1),
      labelMedium: jakarta(12, 16, FontWeight.w500, muted),
      labelSmall: jakarta(11, 14, FontWeight.w500, p.textSubtle, 0.1),
    );

    final roundedField = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: p.cardBorder),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      splashFactory: InkSparkle.splashFactory,
      // Pantallas que se abren encima: la nueva entra deslizándose y la de
      // atrás se desvanece, sobre el color de fondo (sin zoom ni cruces).
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(backgroundColor: p.background),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: jakarta(17, 24, FontWeight.w700, ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: roundedField,
        enabledBorder: roundedField,
        focusedBorder: roundedField.copyWith(
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: roundedField.copyWith(
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: roundedField.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: jakarta(14, 20, FontWeight.w500, muted),
        floatingLabelStyle: jakarta(14, 20, FontWeight.w600, accent),
        hintStyle: jakarta(14, 20, FontWeight.w400, p.textSubtle),
        prefixIconColor: p.textSubtle,
        suffixIconColor: p.textSubtle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          disabledBackgroundColor: colorScheme.surfaceContainerHigh,
          disabledForegroundColor: p.textSubtle,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: jakarta(14, 18, FontWeight.w800, onAccent),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: jakarta(14, 18, FontWeight.w800, onAccent),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: p.cardBorderStrong),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: jakarta(14, 18, FontWeight.w600, ink),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: jakarta(14, 18, FontWeight.w600, accent),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: muted),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: onAccent,
        shape: StadiumBorder(),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.cardBorder),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: accent,
        side: BorderSide(color: p.cardBorder),
        shape: const StadiumBorder(),
        labelStyle: jakarta(12, 16, FontWeight.w600, ink),
        secondaryLabelStyle: jakarta(12, 16, FontWeight.w700, onAccent),
        checkmarkColor: onAccent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.sheet,
        modalBackgroundColor: p.sheet,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: p.cardBorder),
        ),
        titleTextStyle: jakarta(18, 26, FontWeight.w700, ink),
        contentTextStyle: jakarta(14, 20, FontWeight.w400, muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.surfaceContainerHigh,
        contentTextStyle: jakarta(14, 20, FontWeight.w500, ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.cardBorderStrong),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: accent,
        textColor: ink,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: colorScheme.surfaceContainerLow,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? onAccent : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : colorScheme.surfaceContainerLow,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: p.textSubtle,
        indicatorColor: accent,
        dividerColor: colorScheme.outlineVariant,
        labelStyle: jakarta(14, 18, FontWeight.w700, accent),
        unselectedLabelStyle: jakarta(14, 18, FontWeight.w500, p.textSubtle),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: colorScheme.surfaceContainerHigh,
        headerForegroundColor: ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.cardBorder),
        ),
      ),
    );
  }

  // Material 3 shape tokens
  static double get shapeSmall => 8;
  static double get shapeMedium => 12;
  static double get shapeLarge => 16;
  static double get shapeExtraLarge => 28;
}
