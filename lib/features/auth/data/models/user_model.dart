import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nombreCompleto,
    required super.email,
    super.telefono,
    super.rol,
    required super.planSuscripcion,
    required super.tenantId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      nombreCompleto: json['nombre_completo'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telefono: json['telefono'] as String?,
      rol: json['rol'] as String?,
      planSuscripcion: json['plan_suscripcion'] as String? ?? 'gratuito',
      tenantId: json['tenant_id'] is int
          ? json['tenant_id'] as int
          : int.tryParse(json['tenant_id'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': int.tryParse(id) ?? 0,
      'nombre_completo': nombreCompleto,
      'email': email,
      'telefono': telefono,
      'rol': rol,
      'plan_suscripcion': planSuscripcion,
      'tenant_id': tenantId,
    };
  }

  User toEntity() => this;
}
