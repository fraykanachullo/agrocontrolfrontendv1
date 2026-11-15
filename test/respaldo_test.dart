import 'package:agrocontrol/core/backup/respaldo_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el nombre del respaldo lleva fecha y hora', () {
    expect(nombreRespaldo(DateTime(2026, 11, 15, 9, 30)), 'agrocontrol_respaldo_2026-11-15_0930.zip');
  });

  test('solo se restauran fotos con nombre simple', () {
    expect(nombreFotoValido('evid_123.jpg'), isTrue);
    expect(nombreFotoValido('../agrocontrol.db'), isFalse);
    expect(nombreFotoValido('sub/evid.jpg'), isFalse);
    expect(nombreFotoValido('..'), isFalse);
    expect(nombreFotoValido(''), isFalse);
  });

  test('rechaza archivos que no son respaldos o de una versión más nueva', () {
    expect(problemaDelManifiesto(null, versionBase: 12), isNotNull);
    expect(problemaDelManifiesto({'app': 'otra', 'version_base': 12}, versionBase: 12), isNotNull);
    expect(problemaDelManifiesto({'app': 'agrocontrol'}, versionBase: 12), isNotNull);
    expect(problemaDelManifiesto({'app': 'agrocontrol', 'version_base': 13}, versionBase: 12), contains('más nueva'));
  });

  test('acepta respaldos de la misma versión o anteriores (se migran al abrir)', () {
    expect(problemaDelManifiesto({'app': 'agrocontrol', 'version_base': 12}, versionBase: 12), isNull);
    expect(problemaDelManifiesto({'app': 'agrocontrol', 'version_base': 9}, versionBase: 12), isNull);
  });
}
