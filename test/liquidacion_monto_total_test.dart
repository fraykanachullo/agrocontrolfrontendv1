import 'package:agrocontrol/features/cosechas/domain/entities/cosecha.dart';
import 'package:agrocontrol/features/cosechas/presentation/liquidacion_model.dart';
import 'package:agrocontrol/features/cosechas/presentation/screens/liquidacion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Cosecha _despacho({String estado = 'entregado', Map<String, dynamic> liquidacion = const {}}) => Cosecha(
      campanaId: 1,
      id: 1,
      tipoVenta: 'despacho',
      cantidadUnidades: 100,
      conductor: '',
      mercadoDestino: 'Lima',
      estado: estado,
      liquidacion: liquidacion,
    );

Future<void> _abrir(WidgetTester tester, Cosecha c) async {
  tester.view.physicalSize = const Size(1080, 7800);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: LiquidacionScreen(cosecha: c))));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  test('reconoce una liquidación hecha con el total de la boleta', () {
    expect(liquidadoConTotal(_despacho(liquidacion: {'modo': 'total', 'bruto': 50000})), isTrue);
  });

  test('las liquidaciones por calidad y las antiguas siguen siendo por calidad', () {
    expect(liquidadoConTotal(_despacho(liquidacion: {'vendidos': {'*': 100}})), isFalse);
    expect(liquidadoConTotal(_despacho()), isFalse);
  });

  test('con el total no se inventa merma', () {
    final [carga] = calidadesDe(_despacho(liquidacion: {'modo': 'total', 'bruto': 50000}));
    expect(carga.merma, 0);
  });

  testWidgets('una liquidación nueva abre en monto total y se puede pasar a calidades', (tester) async {
    await _abrir(tester, _despacho(estado: 'pendiente'));
    expect(find.text('CUÁNTO SE VENDIÓ EN TOTAL'), findsOneWidget);
    expect(find.text('CIERRE DE CALIDADES'), findsNothing);

    await tester.tap(find.text('Por calidad'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('CIERRE DE CALIDADES'), findsOneWidget);
    expect(find.text('CUÁNTO SE VENDIÓ EN TOTAL'), findsNothing);
  });

  testWidgets('al corregir un total reaparece el monto guardado', (tester) async {
    await _abrir(tester, _despacho(liquidacion: {'modo': 'total', 'bruto': 50000}));
    expect(find.text('CUÁNTO SE VENDIÓ EN TOTAL'), findsOneWidget);
    expect(find.widgetWithText(TextField, '50000'), findsOneWidget);
  });

  testWidgets('al corregir una liquidación por calidad sigue por calidad', (tester) async {
    await _abrir(tester, _despacho(liquidacion: {'vendidos': {'*': 100}, 'bruto': 500}));
    expect(find.text('CIERRE DE CALIDADES'), findsOneWidget);
  });
}
