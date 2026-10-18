import 'dart:convert';

/// Planilla de carga / Note de campo. Guardado offline-first con payload
/// JSON flexible listo para sincronización diferida con el backend.
class Planilla {
  final int? id;
  final String uuidLocal;
  final int campanaId;
  final String cultivo;
  final String tipo; // matricial (la hoja de anotación)
  final String fecha;
  final String? mercado;
  final String? transportista;
  final String? notas;
  final int totalUnidades;
  final double totalPeso;
  final String estado; // borrador | guardada | compartida
  final Map<String, dynamic> payload;
  final String createdAt;
  final String updatedAt;
  final bool isSynced;

  const Planilla({
    this.id,
    required this.uuidLocal,
    required this.campanaId,
    required this.cultivo,
    required this.tipo,
    required this.fecha,
    this.mercado,
    this.transportista,
    this.notas,
    this.totalUnidades = 0,
    this.totalPeso = 0,
    this.estado = 'guardada',
    this.payload = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
    'uuid_local': uuidLocal,
    'campana_id': campanaId,
    'cultivo': cultivo,
    'tipo': tipo,
    'fecha': fecha,
    'mercado': mercado,
    'transportista': transportista,
    'notas': notas,
    'total_unidades': totalUnidades,
    'total_peso': totalPeso,
    'estado': estado,
    'payload_json': jsonEncode(payload),
    'created_at': createdAt,
    'updated_at': updatedAt,
    'is_synced': isSynced ? 1 : 0,
  };

  factory Planilla.fromMap(Map<String, dynamic> m) {
    return Planilla(
      id: m['id'] as int?,
      uuidLocal: m['uuid_local'] as String,
      campanaId: m['campana_id'] as int,
      cultivo: m['cultivo'] as String,
      tipo: m['tipo'] as String,
      fecha: m['fecha'] as String,
      mercado: m['mercado'] as String?,
      transportista: m['transportista'] as String?,
      notas: m['notas'] as String?,
      totalUnidades: (m['total_unidades'] as num?)?.toInt() ?? 0,
      totalPeso: (m['total_peso'] as num?)?.toDouble() ?? 0,
      estado: (m['estado'] as String?) ?? 'guardada',
      payload: _decodePayload(m['payload_json']),
      createdAt: m['created_at'] as String,
      updatedAt: m['updated_at'] as String,
      isSynced: (m['is_synced'] as int?) == 1,
    );
  }

  static Map<String, dynamic> _decodePayload(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return const {};
  }

  /// Payload flexible listo para sincronización con Laravel.
  Map<String, dynamic> toSyncMap() => {
    'uuid_local': uuidLocal,
    'campana_id': campanaId,
    'cultivo': cultivo,
    'tipo': tipo,
    'fecha': fecha,
    'mercado': mercado,
    'transportista': transportista,
    'notas': notas,
    'estado': estado,
    ...payload,
  };

  Planilla copyWith({
    int? id,
    String? uuidLocal,
    int? campanaId,
    String? cultivo,
    String? tipo,
    String? fecha,
    String? mercado,
    String? transportista,
    String? notas,
    int? totalUnidades,
    double? totalPeso,
    String? estado,
    Map<String, dynamic>? payload,
    String? createdAt,
    String? updatedAt,
    bool? isSynced,
  }) {
    return Planilla(
      id: id ?? this.id,
      uuidLocal: uuidLocal ?? this.uuidLocal,
      campanaId: campanaId ?? this.campanaId,
      cultivo: cultivo ?? this.cultivo,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      mercado: mercado ?? this.mercado,
      transportista: transportista ?? this.transportista,
      notas: notas ?? this.notas,
      totalUnidades: totalUnidades ?? this.totalUnidades,
      totalPeso: totalPeso ?? this.totalPeso,
      estado: estado ?? this.estado,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
