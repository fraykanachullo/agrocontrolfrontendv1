class CosechaClase {
  final int? id;
  final int cosechaId;
  final String clase;
  final double cantidad;
  final double precioUnitario;
  final double? pesoKg;
  final double subtotal;
  final String? createdAt;
  final bool isSynced;
  final String? uuidLocal;

  const CosechaClase({
    this.id,
    required this.cosechaId,
    required this.clase,
    required this.cantidad,
    required this.precioUnitario,
    this.pesoKg,
    required this.subtotal,
    this.createdAt,
    this.isSynced = false,
    this.uuidLocal,
  });

  /// Calcula el subtotal en base a la unidad de medida
  static double calcularSubtotal({
    required String clase,
    required double cantidad,
    required double precioUnitario,
    double? pesoKg,
  }) {
    if (pesoKg != null && pesoKg > 0) {
      return cantidad * pesoKg * precioUnitario;
    }
    return cantidad * precioUnitario;
  }

  /// Nombre legible de la clase
  static String nombreClase(String clase) {
    switch (clase) {
      case '1ra':
        return '1ra - Excelente';
      case '2da':
        return '2da - Buena';
      case '3ra':
        return '3ra - Regular';
      case '4ta':
        return '4ta - Mezcla';
      case 'sacos':
        return 'Sacos de malla';
      default:
        return clase;
    }
  }

  factory CosechaClase.fromMap(Map<String, dynamic> map) {
    return CosechaClase(
      id: map['id'] as int?,
      cosechaId: map['cosecha_id'] as int,
      clase: map['clase'] as String? ?? 'general',
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 0,
      precioUnitario: (map['precio_unitario'] as num?)?.toDouble() ?? 0,
      pesoKg: (map['peso_kg'] as num?)?.toDouble(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      uuidLocal: map['uuid_local'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'cosecha_id': cosechaId,
      'clase': clase,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'peso_kg': pesoKg,
      'subtotal': subtotal,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      if (uuidLocal != null) 'uuid_local': uuidLocal,
    };
  }

  CosechaClase copyWith({
    int? id,
    int? cosechaId,
    String? clase,
    double? cantidad,
    double? precioUnitario,
    double? pesoKg,
    double? subtotal,
  }) {
    return CosechaClase(
      id: id ?? this.id,
      cosechaId: cosechaId ?? this.cosechaId,
      clase: clase ?? this.clase,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      pesoKg: pesoKg ?? this.pesoKg,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt,
      isSynced: isSynced,
      uuidLocal: uuidLocal,
    );
  }
}
