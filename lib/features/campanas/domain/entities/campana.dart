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
  final int? terrenoId;
  final String? variedad;

  /// Hito que se registra desde el cuaderno con la labor de siembra.
  final DateTime? fechaSiembra;

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
    this.terrenoId,
    this.variedad,
    this.fechaSiembra,
  });

  bool get isActive => estado == 'activa';
  bool get isClosed => estado == 'cerrada';
  bool get isSown => fechaSiembra != null;

  /// Días desde la siembra (día 1 = el día que se sembró).
  int? get diasDesdeSiembra {
    final f = fechaSiembra;
    if (f == null) return null;
    final h = isClosed && fechaCierre != null ? fechaCierre! : DateTime.now();
    // En UTC para que el cambio de horario no quite ni agregue un día.
    return DateTime.utc(h.year, h.month, h.day).difference(DateTime.utc(f.year, f.month, f.day)).inDays + 1;
  }

  String get extensionDisplay {
    final unit = tipoExtension == 'hectarea' ? 'Ha' : 'Topos';
    return '${extension.toStringAsFixed(2)} $unit';
  }
}
