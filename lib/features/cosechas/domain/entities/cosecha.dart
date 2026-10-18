import 'dart:convert';

import 'cosecha_clase.dart';
import 'cosecha_detalle.dart';

/// Ciclo de vida de un despacho al mercado. La venta en campo se liquida en
/// el momento: queda [cobrado] o, si el comprador debe, [liquidado].
enum EtapaDespacho {
  anotado('Anotado'),
  enTransito('En camino'),
  recibido('En el mercado'),
  liquidado('Por cobrar'),
  cobrado('Cobrado');

  final String label;
  const EtapaDespacho(this.label);
}

class Cosecha {
  final int? id;
  final int campanaId;
  final String tipoVenta;
  final String? modoCosecha;
  final String? tipoCalculoVenta;
  final String? unidadEmpaque;
  final int? totalBultos;
  final double? pesoTotalKg;
  final int cantidadUnidades;
  final String conductor;
  final String mercadoDestino;
  final String estado;
  final double? precioUnitario;
  final double? descuentosLogistica;
  final double? montoNetoFinal;
  final String? fechaEnvio;
  final String? fechaLiquidacion;

  /// Salió el camión (en tránsito).
  final String? fechaSalida;

  /// El comisionista confirmó que llegó la carga al mercado.
  final String? fechaRecepcion;

  /// El dinero de la liquidación ya se recibió.
  final String? fechaCobro;
  final String? createdAt;
  final bool isSynced;
  final List<CosechaClase> clases;
  final List<CosechaDetalle> detalles;

  /// Detalle de la liquidación (ver [LiquidacionDetalle] en el liquidador):
  /// vendidos por calidad, descuentos, forma de cobro y foto del comprobante.
  final Map<String, dynamic> liquidacion;

  const Cosecha({
    this.id,
    required this.campanaId,
    required this.tipoVenta,
    this.modoCosecha,
    this.tipoCalculoVenta,
    this.unidadEmpaque,
    this.totalBultos,
    this.pesoTotalKg,
    required this.cantidadUnidades,
    required this.conductor,
    required this.mercadoDestino,
    this.estado = 'pendiente',
    this.precioUnitario,
    this.descuentosLogistica,
    this.montoNetoFinal,
    this.fechaEnvio,
    this.fechaLiquidacion,
    this.fechaSalida,
    this.fechaRecepcion,
    this.fechaCobro,
    this.createdAt,
    this.isSynced = false,
    this.clases = const [],
    this.detalles = const [],
    this.liquidacion = const {},
  });

  static Map<String, dynamic> decodeLiquidacion(Object? raw) {
    if (raw is! String || raw.isEmpty) return const {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const {};
    }
  }

  bool get enCampo => tipoVenta == 'parcela';
  bool get isLiquidado => estado != 'pendiente' && estado != 'pendiente_de_liquidacion';

  EtapaDespacho get etapa {
    if (fechaCobro != null) return EtapaDespacho.cobrado;
    if (isLiquidado) return EtapaDespacho.liquidado;
    if (fechaRecepcion != null) return EtapaDespacho.recibido;
    if (fechaSalida != null) return EtapaDespacho.enTransito;
    return EtapaDespacho.anotado;
  }

  /// Días que la carga lleva sin noticias del mercado (desde que salió, o
  /// desde que se anotó si aún no se marcó la salida). Null si ya llegó.
  int? get diasSinNoticias {
    if (etapa.index >= EtapaDespacho.recibido.index) return null;
    final desde = DateTime.tryParse(fechaSalida ?? fechaEnvio ?? '');
    return desde == null ? null : DateTime.now().difference(desde).inDays;
  }

  /// Avisar si pasa más de [diasAviso] días en camino sin llegar al mercado.
  bool demorado(int diasAviso) => (diasSinNoticias ?? 0) > diasAviso;

  /// Unidad de cálculo de venta efectiva (fallback a por_kilo).
  String get tipoCalculoEfectivo => tipoCalculoVenta ?? 'por_kilo';

  /// Total bruto antes de descuentos (calculado desde detalles si existen).
  double get totalBruto {
    if (detalles.isNotEmpty) {
      return detalles.fold(0.0, (sum, d) {
        final precio = d.precioVenta ?? 0;
        if (precio <= 0) return sum;
        return sum + d.montoUnidad(tipoCalculoEfectivo, precio);
      });
    }
    if (clases.isNotEmpty) {
      return clases.fold(0.0, (sum, c) => sum + c.subtotal);
    }
    if (precioUnitario != null) {
      return precioUnitario! * cantidadUnidades;
    }
    return 0;
  }

  /// Monto neto final (total bruto - descuentos)
  double get montoNetoCalculado {
    return totalBruto - (descuentosLogistica ?? 0);
  }

  /// Resumen legible de detalles por categoría
  String get resumenDetalles {
    if (detalles.isEmpty) return '';
    return detalles.map((d) {
      final categoria = d.categoria ?? 'General';
      if (d.precioVenta != null) {
        final monto = d.montoParcial ?? d.montoUnidad(tipoCalculoEfectivo, d.precioVenta!);
        return '$categoria: S/${monto.toStringAsFixed(2)}';
      }
      if (d.pesoLineaKg > 0) {
        return '$categoria: ${d.cantidadBultos} bultos × ${d.pesoLineaKgRounded.toStringAsFixed(1)}kg';
      }
      return '$categoria: ${d.cantidadBultos} bultos';
    }).join('\n');
  }

  /// Resumen legible de clases
  String get resumenClases {
    if (clases.isEmpty) return '';
    return clases.map((c) {
      final nombre = CosechaClase.nombreClase(c.clase);
      if (c.pesoKg != null) {
        return '$nombre: ${c.cantidad.toInt()} sacos × ${c.pesoKg!.toStringAsFixed(1)}kg × S/${c.precioUnitario.toStringAsFixed(2)}';
      }
      return '$nombre: ${c.cantidad.toInt()} javas × S/${c.precioUnitario.toStringAsFixed(2)}';
    }).join('\n');
  }

  factory Cosecha.fromMap(Map<String, dynamic> map) {
    final detallesRaw = map['detalles'];
    final detalles = detallesRaw is List
        ? detallesRaw
            .map((d) => CosechaDetalle.fromMap(Map<String, dynamic>.from(d as Map)))
            .toList()
        : <CosechaDetalle>[];

    return Cosecha(
      id: map['id'] as int?,
      campanaId: map['campana_id'] as int,
      tipoVenta: map['tipo_venta'] as String? ?? 'mayorista',
      modoCosecha: map['modo_cosecha'] as String?,
      tipoCalculoVenta: map['tipo_calculo_venta'] as String?,
      unidadEmpaque: map['unidad_empaque'] as String?,
      totalBultos: map['total_bultos'] as int?,
      pesoTotalKg: (map['peso_total_kg'] as num?)?.toDouble(),
      cantidadUnidades: (map['cantidad_unidades'] as num?)?.toInt() ?? 0,
      conductor: map['conductor'] as String? ?? '',
      mercadoDestino: map['mercado_destino'] as String? ?? '',
      estado: map['estado'] as String? ?? 'pendiente',
      precioUnitario: (map['precio_unitario'] as num?)?.toDouble(),
      descuentosLogistica: (map['descuentos_logistica'] as num?)?.toDouble(),
      montoNetoFinal: (map['monto_neto_final'] as num?)?.toDouble(),
      fechaEnvio: map['fecha_envio'] as String?,
      fechaLiquidacion: map['fecha_liquidacion'] as String?,
      fechaSalida: map['fecha_salida'] as String?,
      fechaRecepcion: map['fecha_recepcion'] as String?,
      fechaCobro: map['fecha_cobro'] as String?,
      liquidacion: decodeLiquidacion(map['liquidacion_json']),
      createdAt: map['created_at'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      detalles: detalles,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'campana_id': campanaId,
      'tipo_venta': tipoVenta,
      'modo_cosecha': modoCosecha,
      'tipo_calculo_venta': tipoCalculoVenta,
      'unidad_empaque': unidadEmpaque,
      'total_bultos': totalBultos,
      'peso_total_kg': pesoTotalKg,
      'cantidad_unidades': cantidadUnidades,
      'conductor': conductor,
      'mercado_destino': mercadoDestino,
      'estado': estado,
      'precio_unitario': precioUnitario,
      'descuentos_logistica': descuentosLogistica,
      'monto_neto_final': montoNetoFinal,
      'fecha_envio': fechaEnvio,
      'fecha_liquidacion': fechaLiquidacion,
      'fecha_salida': fechaSalida,
      'fecha_recepcion': fechaRecepcion,
      'fecha_cobro': fechaCobro,
      'is_synced': isSynced ? 1 : 0,
    };
  }
}
