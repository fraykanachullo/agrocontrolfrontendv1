import 'package:agrocontrol/features/cuaderno/domain/entities/incidencia.dart';
import 'package:agrocontrol/features/planillas/domain/entities/plantilla_cultivo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Plantilla de cultivo', () {
    test('se guarda y se lee igual', () {
      const original = PlantillaCultivo(
        id: 3,
        cultivo: 'Cebolla',
        calidades: [(codigo: 'A', nombre: 'Gruesa'), (codigo: 'B', nombre: 'Mediana')],
        filas: 10,
        envase: 'saco',
        pesoEnvaseKg: 50,
      );
      final leida = PlantillaCultivo.fromMap(original.toMap());
      expect(leida.cultivo, 'Cebolla');
      expect(leida.calidades, original.calidades);
      expect(leida.filas, 10);
      expect(leida.envase, 'saco');
      expect(leida.pesoEnvaseKg, 50);
    });

    test('un cultivo sin plantilla usa tres calidades y java', () {
      final basica = PlantillaCultivo.basica('Vainita');
      expect(basica.calidades.map((c) => c.codigo), ['I', 'II', 'III']);
      expect(basica.envase, 'java');
      expect(basica.id, isNull);
    });
  });

  test('Incidencia se lee de su tabla', () {
    final i = Incidencia.fromMap({
      'id': 1,
      'campana_id': 2,
      'tipo': 'Helada',
      'severidad': 'alta',
      'nota': 'Sector bajo',
      'fecha': '2026-07-10T06:00:00',
      'is_synced': 0,
    });
    expect(i.tipo, 'Helada');
    expect(i.severidad, 'alta');
    expect(i.nota, 'Sector bajo');
    expect(i.isSynced, isFalse);
  });
}
