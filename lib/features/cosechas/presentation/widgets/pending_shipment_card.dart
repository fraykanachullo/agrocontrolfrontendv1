import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/config/cultivo_config.dart';
import '../../../cosechas/domain/entities/cosecha.dart';

class PendingShipmentCard extends ConsumerWidget {
  final List<Cosecha> pendientes;
  final int campanaId;
  final String cultivo;

  const PendingShipmentCard({super.key, required this.pendientes, required this.campanaId, required this.cultivo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pendientes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          Text('Sin despachos pendientes', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.pending_actions, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text('Pendientes de Liquidación', style: Theme.of(context).textTheme.headlineSmall),
        ]),
        const SizedBox(height: 16),
        ...pendientes.map((c) => _buildShipmentCard(context, ref, c)),
      ],
    );
  }

  Widget _buildShipmentCard(BuildContext context, WidgetRef ref, Cosecha c) {
    final fechaStr = c.fechaEnvio != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(c.fechaEnvio!)) : '--';
    final modoLabel = switch (c.modoCosecha) {
      'matricial_filas' => 'Matricial • ${c.totalBultos ?? c.cantidadUnidades} javas',
      'por_categorias' => 'Categorías • ${c.totalBultos ?? c.cantidadUnidades} sacos',
      'peso_directo' => 'Peso directo • ${c.pesoTotalKg?.toStringAsFixed(0) ?? c.totalBultos ?? c.cantidadUnidades} kg',
      _ => c.tipoCalculoEfectivo == 'por_unidad' ? '${c.cantidadUnidades} javas' : '${c.cantidadUnidades} sacos',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainer),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Despacho #${c.id ?? "---"}', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text('$fechaStr • ${c.mercadoDestino}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.warning, size: 14, color: AppColors.onSecondaryContainer),
                const SizedBox(width: 4),
                Text('PENDIENTE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSecondaryContainer, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Container(height: 1, color: AppColors.surfaceVariant)),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MODO', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(modoLabel, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            ])),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CONDUCTOR', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(c.conductor, style: Theme.of(context).textTheme.bodyMedium),
            ])),
          ]),
          if (c.detalles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Desglose', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ...c.detalles.take(4).map((d) {
                  final qty = d.cantidadBultos;
                  final peso = d.pesoLineaKgRounded;
                  final label = d.categoria ?? (d.posicionFila != null ? 'Fila ${d.posicionFila}' : '');
                  final detail = d.pesoPromedioBultoKg != null && d.pesoPromedioBultoKg! > 0
                      ? '$qty × ${d.pesoPromedioBultoKg!.toStringAsFixed(1)}kg'
                      : '$qty bultos';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(children: [
                      Expanded(child: Text('$label: $detail', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant))),
                      if (peso > 0) Text('${peso.toStringAsFixed(0)} kg', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    ]),
                  );
                }),
                if (c.detalles.length > 4)
                  Text('...${c.detalles.length - 4} más', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showLiquidarDialog(context, ref, c),
              icon: const Icon(Icons.receipt_long, size: 20),
              label: const Text('Liquidar Mercado'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLiquidarDialog(BuildContext context, WidgetRef ref, Cosecha c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _LiquidarBottomSheet(
        cosecha: c,
        cultivo: cultivo,
        onLiquidar: (detallesPrecios, descuento, precioGlobal) {
          ref.read(cosechasProvider.notifier).liquidarCosecha(
            c.campanaId, c.id!,
            detallesPrecios: detallesPrecios,
            descuentosLogistica: descuento,
            precioUnitarioGlobal: precioGlobal,
          );
          ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Despacho liquidado')));
        },
      ),
    );
  }
}

class _LiquidarBottomSheet extends ConsumerStatefulWidget {
  final Cosecha cosecha;
  final String cultivo;
  final void Function(List<Map<String, dynamic>> detallesPrecios, double descuento, double? precioGlobal) onLiquidar;

  const _LiquidarBottomSheet({required this.cosecha, required this.cultivo, required this.onLiquidar});

  @override
  ConsumerState<_LiquidarBottomSheet> createState() => _LiquidarBottomSheetState();
}

class _LiquidarBottomSheetState extends ConsumerState<_LiquidarBottomSheet> {
  final _descuentoController = TextEditingController(text: '0');
  final _precioGlobalController = TextEditingController();
  final Map<String, TextEditingController> _precioControllers = {};
  final Map<String, TextEditingController> _addDetailCantidadController = {};
  final Map<String, TextEditingController> _addDetailPesoController = {};
  late List<String> _categoriasActuales;
  bool _usarDetalle = false;

  @override
  void initState() {
    super.initState();
    _usarDetalle = widget.cosecha.detalles.isNotEmpty;

    if (_usarDetalle) {
      _categoriasActuales = widget.cosecha.detalles.map((d) => d.categoria ?? '').toSet().toList();
      for (final cat in _categoriasActuales) {
        if (cat.isNotEmpty) _precioControllers[cat] = TextEditingController();
      }
    } else {
      final config = CultivoConfig.forCultivo(widget.cultivo);
      _categoriasActuales = config.clases.map((c) => c.codigo).toList();
      for (final cat in _categoriasActuales) {
        _precioControllers[cat] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _descuentoController.dispose();
    _precioGlobalController.dispose();
    for (final c in _precioControllers.values) c.dispose();
    for (final c in _addDetailCantidadController.values) c.dispose();
    for (final c in _addDetailPesoController.values) c.dispose();
    super.dispose();
  }

  double _calcularTotal() {
    final tipoCalculo = widget.cosecha.tipoCalculoEfectivo;
    double total = 0;

    if (_usarDetalle) {
      for (final d in widget.cosecha.detalles) {
        if (d.categoria == null || !_precioControllers.containsKey(d.categoria)) continue;
        final precio = double.tryParse(_precioControllers[d.categoria]!.text) ?? 0;
        if (precio > 0) total += d.montoUnidad(tipoCalculo, precio);
      }
    } else {
      final precio = double.tryParse(_precioGlobalController.text) ?? 0;
      if (precio > 0) {
        final base = widget.cosecha.pesoTotalKg ?? widget.cosecha.cantidadUnidades;
        total = tipoCalculo == 'por_unidad' ? widget.cosecha.cantidadUnidades * precio : base * precio;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final totalBruto = _calcularTotal();
    final descuento = double.tryParse(_descuentoController.text) ?? 0;
    final montoNeto = totalBruto - descuento;
    final isPeso = widget.cosecha.tipoCalculoEfectivo != 'por_unidad';

    return StatefulBuilder(
      builder: (ctx, setDialogState) {
        void recalcular() => setDialogState(() {});

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Icon(Icons.receipt_long, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Liquidar #${widget.cosecha.id ?? ""}', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Text(
                '${widget.cosecha.cantidadUnidades} ${widget.cosecha.unidadEmpaque ?? "unidades"} • ${widget.cosecha.mercadoDestino}',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              if (_usarDetalle) ...[
                Text('Precio por categoría (S/${isPeso ? "kg" : "java"})', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...widget.cosecha.detalles.where((d) => d.categoria != null).map((d) {
                  final cat = d.categoria!;
                  final controllers = _precioControllers.putIfAbsent(cat, () => TextEditingController());
                  final pesoLinea = d.pesoLineaKgRounded;
                  final cant = d.cantidadBultos;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(cat, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text('$cant ${isPeso ? 'bultos' : 'javas'}${pesoLinea > 0 ? ' × ${pesoLinea.toStringAsFixed(0)}kg' : ''}', style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                      ])),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(
                        controller: controllers,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'S/', isDense: true, hintText: '0.00'),
                        onChanged: (_) => recalcular(),
                      )),
                    ]),
                  );
                }),
              ] else ...[
                Text('Precio por ${isPeso ? "kg" : "unidad"}', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _precioGlobalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'S/ por kg', hintText: '0.00', prefixText: 'S/ '),
                  onChanged: (_) => recalcular(),
                ),
              ],
              const SizedBox(height: 16),
              Text('Descuento flete / logística (S/)', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: _descuentoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'Costo del transporte, Ej. 50.00', prefixText: 'S/ '),
                onChanged: (_) => recalcular(),
              ),
              const SizedBox(height: 20),

              // ── Resumen ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Resumen', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...(_usarDetalle ? widget.cosecha.detalles.where((d) => d.categoria != null).map((d) {
                    final precio = double.tryParse(_precioControllers[d.categoria]?.text ?? '') ?? 0;
                    final sub = precio > 0 ? d.montoUnidad(widget.cosecha.tipoCalculoEfectivo, precio) : 0;
                    final isPesoRow = widget.cosecha.tipoCalculoEfectivo != 'por_unidad';
                    final detail = isPesoRow
                        ? '${d.pesoLineaKgRounded.toStringAsFixed(0)} kg × S/${precio.toStringAsFixed(2)}'
                        : '${d.cantidadBultos} javas × S/${precio.toStringAsFixed(2)}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text('${d.categoria}: $detail', style: Theme.of(ctx).textTheme.bodySmall)),
                        Text('S/${sub.toStringAsFixed(2)}', style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      ]),
                    );
                  }) : [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Global: ${widget.cosecha.cantidadUnidades} × S/${double.tryParse(_precioGlobalController.text)?.toStringAsFixed(2) ?? "0"}', style: Theme.of(ctx).textTheme.bodySmall),
                        Text('S/${totalBruto.toStringAsFixed(2)}', style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                  const Divider(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total bruto', style: Theme.of(ctx).textTheme.bodyMedium),
                    Text('S/${totalBruto.toStringAsFixed(2)}', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                  if (descuento > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Descuento flete', style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppColors.error)),
                    Text('-S/${descuento.toStringAsFixed(2)}', style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppColors.error)),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('MONTO NETO', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text('S/${montoNeto.toStringAsFixed(2)}', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: montoNeto >= 0 ? AppColors.primary : AppColors.error)),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  onPressed: totalBruto <= 0 ? null : () {
                    final precioGlobal = _usarDetalle ? null : (double.tryParse(_precioGlobalController.text));
                    final detallesPrecios = <Map<String, dynamic>>[];
                    if (_usarDetalle) {
                      for (final d in widget.cosecha.detalles) {
                        if (d.categoria == null) continue;
                        final precio = double.tryParse(_precioControllers[d.categoria]?.text ?? '');
                        if (precio != null && precio > 0) {
                          detallesPrecios.add({'categoria': d.categoria, 'precio_venta': precio});
                        }
                      }
                    }
                    widget.onLiquidar(detallesPrecios, descuento, precioGlobal);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Liquidar'),
                )),
              ]),
              const SizedBox(height: 20),
            ]),
          ),
        );
      },
    );
  }
}