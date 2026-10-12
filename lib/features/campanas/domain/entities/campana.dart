class Campana {
  final int id;
  final String nombre;
  final String cultivo;
  final double extension;
  final String tipoExtension;
  final double? latitud;
  final double? longitud;
  final String estado;
  final DateTime? fechaInicio;
  final DateTime? fechaCierre;
  final double? balanceNetoFinal;
  final DateTime? createdAt;

  const Campana({
    required this.id,
    required this.nombre,
    required this.cultivo,
    required this.extension,
    required this.tipoExtension,
    this.latitud,
    this.longitud,
    required this.estado,
    this.fechaInicio,
    this.fechaCierre,
    this.balanceNetoFinal,
    this.createdAt,
  });

  bool get isActive => estado == 'activa';
  bool get isClosed => estado == 'cerrada';

  String get extensionDisplay {
    final unit = tipoExtension == 'hectarea' ? 'Ha' : 'Topos';
    return '${extension.toStringAsFixed(2)} $unit';
  }
}
