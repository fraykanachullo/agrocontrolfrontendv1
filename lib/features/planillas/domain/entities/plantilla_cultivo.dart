import 'dart:convert';

/// Calidad de la hoja: símbolo corto (columna) y nombre.
typedef Calidad = ({String codigo, String nombre});

/// Envases con los que se despacha la cosecha.
const envasesCosecha = ['java', 'saco', 'malla', 'caja'];

/// Plantilla de cultivo editable (Diseño v2): las calidades son las columnas
/// de la hoja de anotación; las filas, las del camión. El total por fila es
/// libre (depende del camión), por eso no hay tope.
class PlantillaCultivo {
  final int? id;
  final String cultivo;
  final List<Calidad> calidades;
  final int filas;
  final String envase;

  /// Peso promedio de un envase lleno, para estimar kilos (opcional).
  final double? pesoEnvaseKg;

  const PlantillaCultivo({
    this.id,
    required this.cultivo,
    required this.calidades,
    this.filas = 16,
    this.envase = 'java',
    this.pesoEnvaseKg,
  });

  /// Plantilla genérica para un cultivo que aún no tiene la suya.
  factory PlantillaCultivo.basica(String cultivo) => PlantillaCultivo(
        cultivo: cultivo,
        calidades: const [
          (codigo: 'I', nombre: 'Primera'),
          (codigo: 'II', nombre: 'Segunda'),
          (codigo: 'III', nombre: 'Tercera'),
        ],
      );

  factory PlantillaCultivo.fromMap(Map<String, dynamic> m) => PlantillaCultivo(
        id: m['id'] as int?,
        cultivo: m['cultivo'] as String,
        calidades: [
          for (final c in jsonDecode(m['calidades_json'] as String) as List)
            (codigo: c['codigo'] as String, nombre: c['nombre'] as String),
        ],
        filas: m['filas'] as int? ?? 16,
        envase: m['envase'] as String? ?? 'java',
        pesoEnvaseKg: (m['peso_envase_kg'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'cultivo': cultivo,
        'calidades_json': jsonEncode([for (final c in calidades) {'codigo': c.codigo, 'nombre': c.nombre}]),
        'filas': filas,
        'envase': envase,
        'peso_envase_kg': pesoEnvaseKg,
        'updated_at': DateTime.now().toIso8601String(),
      };
}
