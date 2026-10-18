class Actividad {
  final int? id;
  final int campanaId;
  final String descripcion;
  final String fecha;
  final String? createdAt;
  final bool isSynced;

  const Actividad({
    this.id,
    required this.campanaId,
    required this.descripcion,
    required this.fecha,
    this.createdAt,
    this.isSynced = false,
  });

  factory Actividad.fromMap(Map<String, dynamic> map) {
    return Actividad(
      id: map['id'] as int?,
      campanaId: map['campana_id'] as int,
      descripcion: map['descripcion'] as String? ?? '',
      fecha: map['fecha'] as String? ?? '',
      createdAt: map['created_at'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'campana_id': campanaId,
      'descripcion': descripcion,
      'fecha': fecha,
      'is_synced': isSynced ? 1 : 0,
    };
  }
}
