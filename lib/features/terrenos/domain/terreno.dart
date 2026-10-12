/// Terreno donde se siembra. Vive más que la campaña: el mismo terreno
/// acumula sus campañas, y así se puede comparar cómo rinde año tras año.
class Terreno {
  final int id;
  final String nombre;

  /// `propio` o `alquilado`.
  final String tenencia;
  final double area;

  /// `hectarea` o `topo`. No cambia después de crear el terreno (RN-02).
  final String unidad;
  final double? latitud;
  final double? longitud;

  /// Cómo llegar en palabras: sector, canal, nombre de la chacra.
  final String? referencia;
  final String? notas;

  const Terreno({
    required this.id,
    required this.nombre,
    required this.tenencia,
    required this.area,
    required this.unidad,
    this.latitud,
    this.longitud,
    this.referencia,
    this.notas,
  });

  bool get esAlquilado => tenencia == 'alquilado';
  bool get tieneUbicacion => latitud != null && longitud != null;

  String get unidadCorta => unidad == 'hectarea' ? 'ha' : (area == 1 ? 'topo' : 'topos');

  String get areaDisplay {
    final valor = area % 1 == 0 ? area.toStringAsFixed(0) : area.toStringAsFixed(2);
    return '$valor $unidadCorta';
  }

  factory Terreno.fromMap(Map<String, dynamic> m) => Terreno(
        id: m['id'] as int,
        nombre: m['nombre'] as String? ?? '',
        tenencia: m['tenencia'] as String? ?? 'propio',
        area: (m['area'] as num?)?.toDouble() ?? 0,
        unidad: m['unidad'] as String? ?? 'hectarea',
        latitud: (m['latitud'] as num?)?.toDouble(),
        longitud: (m['longitud'] as num?)?.toDouble(),
        referencia: m['referencia'] as String?,
        notas: m['notas'] as String?,
      );
}
