import '../../domain/entities/campana.dart';

class CampanaModel extends Campana {
  const CampanaModel({
    required super.id,
    required super.nombre,
    required super.cultivo,
    required super.extension,
    required super.tipoExtension,
    super.latitud,
    super.longitud,
    required super.estado,
    super.fechaInicio,
    super.fechaCierre,
    super.balanceNetoFinal,
    super.createdAt,
  });

  factory CampanaModel.fromJson(Map<String, dynamic> json) {
    return CampanaModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] as String? ?? '',
      cultivo: json['cultivo'] as String? ?? '',
      extension: (json['extension'] as num?)?.toDouble() ?? 0.0,
      tipoExtension: json['tipo_extension'] as String? ?? 'hectarea',
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      estado: json['estado'] as String? ?? 'activa',
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.tryParse(json['fecha_inicio'] as String)
          : null,
      fechaCierre: json['fecha_cierre'] != null
          ? DateTime.tryParse(json['fecha_cierre'] as String)
          : null,
      balanceNetoFinal: (json['balance_neto_final'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'cultivo': cultivo,
      'extension': extension,
      'tipo_extension': tipoExtension,
      'latitud': latitud,
      'longitud': longitud,
      'estado': estado,
      'fecha_inicio': fechaInicio?.toIso8601String().substring(0, 10),
      'fecha_cierre': fechaCierre?.toIso8601String().substring(0, 10),
      'balance_neto_final': balanceNetoFinal,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Campana toEntity() => this;
}
