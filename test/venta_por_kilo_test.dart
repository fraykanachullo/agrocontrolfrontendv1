import 'package:agrocontrol/features/cosechas/domain/entities/cosecha.dart';
import 'package:agrocontrol/features/cosechas/presentation/liquidacion_model.dart';
import 'package:flutter_test/flutter_test.dart';

Cosecha _ventaEnCampo({required String calculo, double? kg}) => Cosecha(
      campanaId: 1,
      tipoVenta: 'parcela',
      tipoCalculoVenta: calculo,
      cantidadUnidades: 10,
      pesoTotalKg: kg,
      precioUnitario: 5,
      conductor: '',
      mercadoDestino: 'Venta en campo',
      estado: 'entregado',
    );

void main() {
  test('la venta por kilo se detalla en kilos, no en sacos', () {
    final [carga] = calidadesDe(_ventaEnCampo(calculo: 'por_kilo', kg: 200));
    expect(carga.anotado, 200);
    expect(carga.subtotal, 1000);
  });

  test('la venta por envase sigue contando envases', () {
    final [carga] = calidadesDe(_ventaEnCampo(calculo: 'por_unidad'));
    expect(carga.anotado, 10);
    expect(carga.subtotal, 50);
  });
}
