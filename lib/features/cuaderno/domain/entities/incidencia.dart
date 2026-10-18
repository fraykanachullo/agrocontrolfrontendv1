/// Incidencia de la campaña (plaga, helada, enfermedad, robo…). Junto al
/// resultado ayuda a responder "¿fue el terreno, el precio o el manejo?".
class Incidencia {
  final int id;
  final int campanaId;
  final String tipo;

  /// `baja`, `media` o `alta`.
  final String severidad;
  final String? nota;
  final String fecha;
  final bool isSynced;

  const Incidencia({
    required this.id,
    required this.campanaId,
    required this.tipo,
    required this.severidad,
    this.nota,
    required this.fecha,
    this.isSynced = false,
  });

  factory Incidencia.fromMap(Map<String, dynamic> m) => Incidencia(
        id: m['id'] as int,
        campanaId: m['campana_id'] as int,
        tipo: m['tipo'] as String? ?? '',
        severidad: m['severidad'] as String? ?? 'media',
        nota: m['nota'] as String?,
        fecha: m['fecha'] as String? ?? '',
        isSynced: (m['is_synced'] as int? ?? 0) == 1,
      );
}
