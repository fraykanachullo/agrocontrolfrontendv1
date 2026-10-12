class User {
  final String id;
  final String nombreCompleto;
  final String email;
  final String? telefono;
  final String? rol;
  final String planSuscripcion;
  final int tenantId;

  const User({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    this.telefono,
    this.rol,
    required this.planSuscripcion,
    required this.tenantId,
  });

  bool get isPremium => planSuscripcion == 'premium';
  bool get isFree => planSuscripcion == 'gratuito';

  String get initials {
    final parts = nombreCompleto.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return nombreCompleto.isNotEmpty ? nombreCompleto[0].toUpperCase() : '?';
  }
}
