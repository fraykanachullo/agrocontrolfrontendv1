import 'package:flutter/material.dart';
import '../domain/entities/cosecha.dart';

/// Clave usada cuando el despacho no tiene detalle por calidad.
const kTodaLaCarga = '*';

/// Formas de cobro de una liquidación: (clave, nombre, icono).
const formasCobro = <(String, String, IconData)>[
  ('deposito', 'Depósito', Icons.account_balance_rounded),
  ('efectivo', 'Efectivo', Icons.payments_rounded),
  ('yape', 'Yape / Plin', Icons.smartphone_rounded),
];

String nombreFormaCobro(String? clave) =>
    formasCobro.where((f) => f.$1 == clave).map((f) => f.$2).firstOrNull ?? '—';

/// Carga de una calidad del despacho: lo anotado en campo y, si ya se
/// liquidó, lo vendido y su precio.
class CalidadCarga {
  final String clave; // categoría guardada en el detalle ('*' si no hay detalle)
  final String simbolo;
  final String nombre;
  final int anotado;
  final double? precio;
  final int? vendido;

  const CalidadCarga({
    required this.clave,
    required this.simbolo,
    required this.nombre,
    required this.anotado,
    this.precio,
    this.vendido,
  });

  int get vendidoEfectivo => vendido ?? anotado;
  int get merma => anotado - vendidoEfectivo;
  double get subtotal => vendidoEfectivo * (precio ?? 0);
}

/// Agrupa la carga por calidad en el orden de la hoja, con los datos de
/// la liquidación si ya existe.
List<CalidadCarga> calidadesDe(Cosecha c) {
  final vendidos = (c.liquidacion['vendidos'] as Map?)?.map((k, v) => MapEntry('$k', (v as num).toInt())) ?? const {};
  if (c.detalles.isEmpty) {
    // Venta por kilo: el precio es por kg, así que la cantidad son los kilos.
    final porKilo = c.tipoCalculoVenta == 'por_kilo' && (c.pesoTotalKg ?? 0) > 0;
    return [
      CalidadCarga(
        clave: kTodaLaCarga,
        simbolo: porKilo ? 'kg' : '∑',
        nombre: porKilo ? 'Toda la carga (kg)' : 'Toda la carga',
        anotado: porKilo ? c.pesoTotalKg!.round() : c.cantidadUnidades,
        precio: c.precioUnitario,
        vendido: vendidos[kTodaLaCarga],
      ),
    ];
  }
  final orden = <String>[];
  final anotados = <String, int>{};
  final simbolos = <String, String>{};
  final precios = <String, double?>{};
  for (final d in c.detalles) {
    final key = d.categoria ?? d.simbolo ?? '—';
    if (!anotados.containsKey(key)) orden.add(key);
    anotados[key] = (anotados[key] ?? 0) + d.cantidadBultos;
    simbolos[key] = d.simbolo ?? key.characters.first;
    precios[key] ??= d.precioVenta;
  }
  return [
    for (final k in orden)
      CalidadCarga(
        clave: k,
        simbolo: simbolos[k]!,
        nombre: k,
        anotado: anotados[k]!,
        precio: precios[k],
        vendido: vendidos[k],
      ),
  ];
}
