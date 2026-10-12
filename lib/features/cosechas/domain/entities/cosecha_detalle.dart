/// Detalle/desglose de una cosecha-envío.
/// Corresponde a `cosecha_envio_detalles` en el backend y a
/// `cosecha_detalles` en el SQLite local.
class CosechaDetalle {
  final int? id;
  final int cosechaId;
  final String? categoria;
  final String? simbolo;
  final int? posicionFila;
  final int cantidadBultos;
  final double? pesoPromedioBultoKg;
  final double? pesoKg;
  final double? precioVenta;
  final double? montoParcial;
  final String? uuidLocal;
  final bool isSynced;

  const CosechaDetalle({
    this.id,
    required this.cosechaId,
    this.categoria,
    this.simbolo,
    this.posicionFila,
    required this.cantidadBultos,
    this.pesoPromedioBultoKg,
    this.pesoKg,
    this.precioVenta,
    this.montoParcial,
    this.uuidLocal,
    this.isSynced = false,
  });

  /// Peso de la línea: peso_kg directo o cantidad × peso promedio del bulto.
  double get pesoLineaKg {
    if (pesoKg != null && pesoKg! > 0) return pesoKg!;
    if (pesoPromedioBultoKg != null && pesoPromedioBultoKg! > 0) {
      return cantidadBultos * pesoPromedioBultoKg!;
    }
    return 0.0;
  }

  /// Monto de la línea con el precio dado y la unidad de cálculo de venta.
  double montoUnidad(String tipoCalculoVenta, double precio) {
    if (tipoCalculoVenta == 'por_unidad') {
      return cantidadBultos * precio;
    }
    return pesoLineaKg * precio;
  }

  double round2(double v) => (v * 100).roundToDouble() / 100;

  double get pesoLineaKgRounded => round2(pesoLineaKg);

  factory CosechaDetalle.fromMap(Map<String, dynamic> map) {
    return CosechaDetalle(
      id: map['id'] as int?,
      cosechaId: map['cosecha_id'] as int,
      categoria: map['categoria'] as String?,
      simbolo: map['simbolo'] as String?,
      posicionFila: map['posicion_fila'] as int?,
      cantidadBultos: (map['cantidad_bultos'] as num?)?.toInt() ?? 0,
      pesoPromedioBultoKg: (map['peso_promedio_bulto_kg'] as num?)?.toDouble(),
      pesoKg: (map['peso_kg'] as num?)?.toDouble(),
      precioVenta: (map['precio_venta'] as num?)?.toDouble(),
      montoParcial: (map['monto_parcial'] as num?)?.toDouble(),
      uuidLocal: map['uuid_local'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'cosecha_id': cosechaId,
      'categoria': categoria,
      'simbolo': simbolo,
      'posicion_fila': posicionFila,
      'cantidad_bultos': cantidadBultos,
      'peso_promedio_bulto_kg': pesoPromedioBultoKg,
      'peso_kg': pesoKg,
      'precio_venta': precioVenta,
      'monto_parcial': montoParcial,
      'uuid_local': uuidLocal,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// Payload para el backend (cosecha_envio_detalles).
  Map<String, dynamic> toSyncMap() {
    return {
      'categoria': categoria,
      'simbolo': simbolo,
      'posicion_fila': posicionFila,
      'cantidad_bultos': cantidadBultos,
      'peso_promedio_bulto_kg': pesoPromedioBultoKg,
      'peso_kg': pesoKg,
      if (uuidLocal != null) 'uuid_local': uuidLocal,
    };
  }

  CosechaDetalle copyWith({
    int? id,
    int? cosechaId,
    String? categoria,
    String? simbolo,
    int? posicionFila,
    int? cantidadBultos,
    double? pesoPromedioBultoKg,
    double? pesoKg,
    double? precioVenta,
    double? montoParcial,
    String? uuidLocal,
    bool? isSynced,
  }) {
    return CosechaDetalle(
      id: id ?? this.id,
      cosechaId: cosechaId ?? this.cosechaId,
      categoria: categoria ?? this.categoria,
      simbolo: simbolo ?? this.simbolo,
      posicionFila: posicionFila ?? this.posicionFila,
      cantidadBultos: cantidadBultos ?? this.cantidadBultos,
      pesoPromedioBultoKg: pesoPromedioBultoKg ?? this.pesoPromedioBultoKg,
      pesoKg: pesoKg ?? this.pesoKg,
      precioVenta: precioVenta ?? this.precioVenta,
      montoParcial: montoParcial ?? this.montoParcial,
      uuidLocal: uuidLocal ?? this.uuidLocal,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}