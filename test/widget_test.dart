import 'package:flutter_test/flutter_test.dart';
import 'package:agrocontrol/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const AgroControlApp());
    expect(find.text('AgroControl'), findsOneWidget);
  });
}
