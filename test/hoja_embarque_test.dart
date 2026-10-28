import 'package:agrocontrol/features/planillas/presentation/screens/compartir_hoja_screen.dart';
import 'package:flutter_test/flutter_test.dart';

HojaEmbarque _hoja(List<List<int>> celdas, {double? peso}) => HojaEmbarque(
      numero: 3,
      cultivo: 'Tomate',
      campana: 'Tomate - Invierno 2026',
      fecha: DateTime(2026, 10, 10),
      destino: 'Santa Anita',
      chofer: 'Hugo Quispe',
      placa: 'V4R-821',
      comisionista: 'Rosa Mamani',
      envase: 'java',
      notas: '',
      anotadoPor: 'Carlos Mendoza',
      pesoEnvaseKg: peso,
      estado: 'Enviada',
      calidades: const [(codigo: 'I', nombre: 'Primera'), (codigo: 'II', nombre: 'Segunda'), (codigo: 'R', nombre: 'Rojos')],
      celdas: celdas,
    );

void main() {
  test('totales por fila, por calidad y filas vacías fuera de la hoja', () {
    final h = _hoja([
      [22, 68, 5],
      [0, 0, 0],
      [10, 4, 1],
    ]);
    expect(h.total, 110);
    expect(h.totalFila(0), 95);
    expect(h.totalCol(1), 72);
    expect(h.filasConDatos, [0, 2]);
    expect(h.nombreArchivo, 'hoja_3_2026-10-10');
  });

  test('el código cambia si cambia un número de la hoja', () {
    final a = _hoja([
      [22, 68, 5],
    ]);
    final b = _hoja([
      [22, 69, 5],
    ]);
    expect(a.codigo, matches(RegExp(r'^[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$')));
    expect(a.codigo, _hoja([
      [22, 68, 5],
    ]).codigo);
    expect(a.codigo, isNot(b.codigo));
  });

  test('kilos estimados con el peso por envase, o nada si no está configurado', () {
    expect(_hoja([
      [10, 6, 0],
    ], peso: 25).kilos, 400);
    expect(_hoja([
      [10, 6, 0],
    ]).kilos, isNull);
  });
}
