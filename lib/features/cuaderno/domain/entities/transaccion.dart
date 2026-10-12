class Transaccion {
  final int? id;
  final int campanaId;
  final String tipo;
  final String categoria;
  final double monto;
  final String descripcion;
  final String fecha;
  final String? estadoPago;
  final String? createdAt;
  final bool isSynced;

  const Transaccion({
    this.id,
    required this.campanaId,
    required this.tipo,
    required this.categoria,
    required this.monto,
    required this.descripcion,
    required this.fecha,
    this.estadoPago,
    this.createdAt,
    this.isSynced = false,
  });

  factory Transaccion.fromMap(Map<String, dynamic> map) {
    return Transaccion(
      id: map['id'] as int?,
      campanaId: map['campana_id'] as int,
      tipo: map['tipo'] as String? ?? 'gasto',
      categoria: map['categoria'] as String? ?? 'general',
      monto: (map['monto'] as num?)?.toDouble() ?? 0,
      descripcion: map['descripcion'] as String? ?? '',
      fecha: map['fecha'] as String? ?? '',
      estadoPago: map['estado_pago'] as String?,
      createdAt: map['created_at'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'campana_id': campanaId,
      'tipo': tipo,
      'categoria': categoria,
      'monto': monto,
      'descripcion': descripcion,
      'fecha': fecha,
      'estado_pago': estadoPago ?? 'pendiente',
      'is_synced': isSynced ? 1 : 0,
    };
  }
}
