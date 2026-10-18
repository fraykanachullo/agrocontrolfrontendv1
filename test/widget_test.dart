import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrocontrol/core/theme/app_colors.dart';
import 'package:agrocontrol/core/theme/theme_mode_provider.dart';
import 'package:agrocontrol/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgroControlApp()));
    expect(find.text('AgroControl'), findsOneWidget);

    // Let the splash screen timer and auth check settle.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Cambiar de modo redibuja con la nueva paleta sin errores', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AgroControlApp()));

    container.read(themeModeProvider.notifier).set(ThemeMode.dark); // sin esperar al almacenamiento
    await tester.pump();
    expect(AppColors.palette.isDark, isTrue);

    container.read(themeModeProvider.notifier).set(ThemeMode.light);
    await tester.pump();
    expect(AppColors.palette.isDark, isFalse);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 3));
  });
}
