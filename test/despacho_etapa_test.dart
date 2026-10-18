import 'package:agrocontrol/features/cosechas/domain/entities/cosecha.dart';
import 'package:flutter_test/flutter_test.dart';

String _haceDias(int d) => DateTime.now().subtract(Duration(days: d)).toIso8601String();

Cosecha _despacho({
  String tipoVenta = 'mayorista',
  String estado = 'pendiente',
  String? envio,
  String? salida,
  String? recepcion,
  String? cobro,
}) =>
    Cosecha(
      campanaId: 1,
      tipoVenta: tipoVenta,
      cantidadUnidades: 632,
      conductor: 'Chofer',
      mercadoDestino: 'Lima',
      estado: estado,
      fechaEnvio: envio,
      fechaSalida: salida,
      fechaRecepcion: recepcion,
      fechaCobro: cobro,
    );

void main() {
  group('Ciclo del despacho', () {
    test('recién anotado', () {
      expect(_despacho(envio: _haceDias(0)).etapa, EtapaDespacho.anotado);
    });

    test('salió el camión: en camino', () {
      expect(_despacho(salida: _haceDias(1)).etapa, EtapaDespacho.enTransito);
    });

    test('llegó al mercado', () {
      expect(_despacho(salida: _haceDias(2), recepcion: _haceDias(1)).etapa, EtapaDespacho.recibido);
    });

    test('liquidado sin cobro queda por cobrar', () {
      expect(_despacho(estado: 'entregado').etapa, EtapaDespacho.liquidado);
    });

    test('liquidado y cobrado', () {
      expect(_despacho(estado: 'entregado', cobro: _haceDias(0)).etapa, EtapaDespacho.cobrado);
    });

    test('la venta en campo pagada queda cobrada', () {
      expect(_despacho(tipoVenta: 'parcela', estado: 'entregado', cobro: _haceDias(0)).etapa, EtapaDespacho.cobrado);
    });

    test('la venta en campo fiada queda por cobrar', () {
      expect(_despacho(tipoVenta: 'parcela', estado: 'entregado').etapa, EtapaDespacho.liquidado);
    });
  });

  group('Aviso de despacho demorado', () {
    test('cuenta desde la salida del camión', () {
      final c = _despacho(envio: _haceDias(9), salida: _haceDias(5));
      expect(c.diasSinNoticias, 5);
      expect(c.demorado(4), isTrue);
      expect(c.demorado(5), isFalse);
    });

    test('sin salida marcada cuenta desde que se anotó', () {
      expect(_despacho(envio: _haceDias(3)).diasSinNoticias, 3);
    });

    test('al llegar al mercado ya no avisa', () {
      final c = _despacho(salida: _haceDias(10), recepcion: _haceDias(1));
      expect(c.diasSinNoticias, isNull);
      expect(c.demorado(4), isFalse);
    });
  });
}
