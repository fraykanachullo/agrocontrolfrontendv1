import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrocontrol/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgroControlApp()));
    expect(find.text('AgroControl'), findsOneWidget);

    // Let the splash screen timer and auth check settle.
    await tester.pump(const Duration(seconds: 3));
  });
}