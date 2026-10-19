import 'package:agrocontrol/features/campanas/data/datasources/campana_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('al marcar el pago, la descripción deja de decir que se debe', () {
    expect(CampanaLocalDatasource.descripcionPagada('20 sacos · Me deben'), '20 sacos · Cobrado');
    expect(CampanaLocalDatasource.descripcionPagada('Me deben'), 'Cobrado');
    expect(CampanaLocalDatasource.descripcionPagada('Urea 5 sacos · Debo (fiado)'), 'Urea 5 sacos · Pagado');
    expect(CampanaLocalDatasource.descripcionPagada('Venta a Me deben SAC · Efectivo'), 'Venta a Me deben SAC · Efectivo');
    expect(CampanaLocalDatasource.descripcionPagada(null), isNull);
  });
}
