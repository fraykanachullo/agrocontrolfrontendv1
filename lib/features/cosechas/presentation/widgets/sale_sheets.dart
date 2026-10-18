import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';

/// Modalidades de venta (RF-COS-03 a RF-COS-05).
enum SaleMode { despachoConHoja, ventaEnCampo, despachoLibre }

const _mercados = ['Lima', 'Arequipa', 'Santa Anita', 'Río Seco'];

/// Selector de modalidad: tres tarjetas grandes con una explicación corta.
Future<SaleMode?> showSaleModePicker(BuildContext context) {
  return showModalBottomSheet<SaleMode>(
    context: context,
    // Las tres tarjetas superan la altura por defecto de la hoja (9/16 de pantalla).
    isScrollControlled: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      Widget option(SaleMode mode, IconData icon, String title, String caption, Color color) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              radius: 20,
              onTap: () => Navigator.of(ctx).pop(mode),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(caption, style: text.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textSubtle),
                ],
              ),
            ),
          );

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Cómo vas a vender?', style: text.titleLarge),
              const SizedBox(height: 14),
              option(SaleMode.despachoConHoja, Icons.grid_on_rounded, 'Despacho con hoja',
                  'Al mercado (ej. Lima). Anotas las javas por fila y calidad.', AppColors.accent),
              option(SaleMode.ventaEnCampo, Icons.scale_rounded, 'Venta en campo',
                  'El comprador se lleva todo. Se pesa en balanza y se cobra.', AppColors.positive),
              option(SaleMode.despachoLibre, Icons.local_shipping_outlined, 'Despacho libre',
                  'Al mercado (ej. Arequipa). El comprador anota y luego te da su lista.', AppColors.warning),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showFieldSaleSheet(BuildContext context, {required int campanaId, required String campanaNombre}) =>
    showRecordSheet(context, _FieldSaleSheet(campanaId: campanaId, campanaNombre: campanaNombre));

Future<void> showFreeDispatchSheet(BuildContext context, {required int campanaId, required String campanaNombre}) =>
    showRecordSheet(context, _FreeDispatchSheet(campanaId: campanaId, campanaNombre: campanaNombre));

String _fechaIso(DateTime date) {
  final now = DateTime.now();
  return DateTime(date.year, date.month, date.day, now.hour, now.minute).toIso8601String();
}

/// Campo numérico grande con etiqueta a la izquierda.
class _NumberRow extends StatelessWidget {
  final String label;
  final String? prefix;
  final String? suffix;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool decimal;

  const _NumberRow({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.prefix,
    this.suffix,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
        SizedBox(
          width: 150,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.end,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]'))],
            style: AppTheme.display(fontSize: 20, color: AppColors.text),
            decoration: InputDecoration(prefixText: prefix, suffixText: suffix, isDense: true, hintText: '0'),
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
//  Venta en campo
// ═══════════════════════════════════════════════

class _FieldSaleSheet extends ConsumerStatefulWidget {
  final int campanaId;
  final String campanaNombre;

  const _FieldSaleSheet({required this.campanaId, required this.campanaNombre});

  @override
  ConsumerState<_FieldSaleSheet> createState() => _FieldSaleSheetState();
}

class _FieldSaleSheetState extends ConsumerState<_FieldSaleSheet> {
  /// (unidad de venta, envase): por kilo con balanza, o por saco / por java.
  String _mode = 'kilo';
  DateTime _date = DateTime.now();
  final _buyerCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController();
  final _kgCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _pagado = true;
  bool _saving = false;

  bool get _byKilo => _mode == 'kilo';
  int get _units => int.tryParse(_unitsCtrl.text) ?? 0;
  double get _kg => AmountInput.parse(_kgCtrl);
  double get _price => AmountInput.parse(_priceCtrl);
  double get _total => (_byKilo ? _kg : _units) * _price;
  String get _envase => _mode == 'java' ? 'java' : 'saco';

  @override
  void dispose() {
    _buyerCtrl.dispose();
    _unitsCtrl.dispose();
    _kgCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa la cantidad y el precio')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final notifier = ref.read(cosechasProvider.notifier);
      final id = await notifier.addCosecha(
        widget.campanaId,
        tipoVenta: 'parcela',
        tipoCalculoVenta: _byKilo ? 'por_kilo' : 'por_unidad',
        unidadEmpaque: _envase,
        cantidadUnidades: _units,
        totalBultos: _units,
        pesoTotalKg: _byKilo ? _kg : null,
        conductor: _buyerCtrl.text.trim(),
        mercadoDestino: 'Venta en campo',
        fechaEnvio: _fechaIso(_date),
      );
      // La venta en campo se liquida en el momento; si el comprador debe,
      // queda "por cobrar" hasta marcar el pago.
      await notifier.liquidarCosecha(
        widget.campanaId,
        id,
        detallesPrecios: const [],
        descuentosLogistica: 0,
        precioUnitarioGlobal: _price,
        cobrado: _pagado,
      );
      ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
      HapticFeedback.mediumImpact();
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('Venta de ${formatSoles(_total)} registrada${_pagado ? '' : ' por cobrar'}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unidadPrecio = _byKilo ? 'kg' : _envase;
    return RecordSheetScaffold(
      title: 'Venta en campo',
      subtitle: widget.campanaNombre,
      date: _date,
      onDateChanged: (d) => setState(() => _date = d),
      saveBar: RecordSaveBar(label: 'Guardar venta', saving: _saving, onSave: _save, total: _total),
      children: [
        const StepTitle(number: 1, title: '¿Quién compra?'),
        TextField(
          controller: _buyerCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nombre del comprador', prefixIcon: Icon(Icons.person_outline_rounded)),
        ),
        const SizedBox(height: 22),
        const StepTitle(number: 2, title: '¿Cómo se cobra?'),
        OptionTiles<String>(
          options: const [
            ('kilo', 'Por kilo', Icons.scale_rounded),
            ('saco', 'Por saco', Icons.shopping_bag_outlined),
            ('java', 'Por java', Icons.inventory_2_outlined),
          ],
          selected: _mode,
          onSelected: (v) => setState(() => _mode = v),
        ),
        const SizedBox(height: 22),
        const StepTitle(number: 3, title: 'Cantidad y precio'),
        GlassCard(
          radius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _NumberRow(
                label: _envase == 'java' ? 'Javas' : 'Sacos / mallas',
                controller: _unitsCtrl,
                onChanged: () => setState(() {}),
              ),
              if (_byKilo) ...[
                const SizedBox(height: 12),
                _NumberRow(
                  label: 'Peso en balanza',
                  suffix: ' kg',
                  decimal: true,
                  controller: _kgCtrl,
                  onChanged: () => setState(() {}),
                ),
              ],
              const SizedBox(height: 12),
              _NumberRow(
                label: 'Precio por $unidadPrecio',
                prefix: 'S/ ',
                decimal: true,
                controller: _priceCtrl,
                onChanged: () => setState(() {}),
              ),
              const Divider(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _byKilo
                          ? '${_kg.toStringAsFixed(0)} kg × ${formatSoles(_price)}'
                          : '$_units × ${formatSoles(_price)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(formatSoles(_total), style: AppTheme.display(fontSize: 18, color: AppColors.positive)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const StepTitle(number: 4, title: '¿Ya te pagó?'),
        OptionTiles<bool>(
          options: const [
            (true, 'Ya pagó', Icons.check_circle_rounded),
            (false, 'Debe', Icons.pending_actions_rounded),
          ],
          selected: _pagado,
          onSelected: (v) => setState(() => _pagado = v),
          colorOf: (v) => v ? AppColors.positive : AppColors.warning,
        ),
        const SizedBox(height: 18),
        RecordSummary(
          text: '${_pagado ? 'Se registra como venta cobrada.' : 'Queda por cobrar hasta que marques "Ya cobré" en el detalle.'} '
              'Los gastos del día (cortadores, mallas…) anótalos en el Cuaderno.',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
//  Despacho libre
// ═══════════════════════════════════════════════

class _FreeDispatchSheet extends ConsumerStatefulWidget {
  final int campanaId;
  final String campanaNombre;

  const _FreeDispatchSheet({required this.campanaId, required this.campanaNombre});

  @override
  ConsumerState<_FreeDispatchSheet> createState() => _FreeDispatchSheetState();
}

class _FreeDispatchSheetState extends ConsumerState<_FreeDispatchSheet> {
  String _market = _mercados[1];
  String _envase = 'java';
  DateTime _date = DateTime.now();
  final _buyerCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController();
  bool _saving = false;

  int get _units => int.tryParse(_unitsCtrl.text) ?? 0;

  @override
  void dispose() {
    _buyerCtrl.dispose();
    _unitsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_units <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indica cuántos bultos van (aprox.)')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(cosechasProvider.notifier).addCosecha(
            widget.campanaId,
            tipoVenta: 'mercado',
            tipoCalculoVenta: 'por_unidad',
            unidadEmpaque: _envase,
            cantidadUnidades: _units,
            totalBultos: _units,
            conductor: _buyerCtrl.text.trim(),
            mercadoDestino: _market,
            fechaEnvio: _fechaIso(_date),
          );
      ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
      HapticFeedback.mediumImpact();
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('Despacho a $_market registrado: queda por liquidar')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RecordSheetScaffold(
      title: 'Despacho libre',
      subtitle: widget.campanaNombre,
      date: _date,
      onDateChanged: (d) => setState(() => _date = d),
      saveBar: RecordSaveBar(label: 'Registrar despacho', saving: _saving, onSave: _save),
      children: [
        const StepTitle(number: 1, title: 'Mercado'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in _mercados) MiniChip(label: m, large: true, selected: _market == m, onTap: () => setState(() => _market = m)),
          ],
        ),
        const SizedBox(height: 22),
        const StepTitle(number: 2, title: 'Comprador o comisionista'),
        TextField(
          controller: _buyerCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Quién recibe y anota', prefixIcon: Icon(Icons.handshake_outlined)),
        ),
        const SizedBox(height: 22),
        const StepTitle(number: 3, title: 'Carga aproximada'),
        OptionTiles<String>(
          options: const [('java', 'Javas', Icons.inventory_2_outlined), ('saco', 'Sacos', Icons.shopping_bag_outlined)],
          selected: _envase,
          onSelected: (v) => setState(() => _envase = v),
        ),
        const SizedBox(height: 12),
        GlassCard(
          radius: 20,
          padding: const EdgeInsets.all(16),
          child: _NumberRow(
            label: 'Cantidad (aprox.)',
            controller: _unitsCtrl,
            onChanged: () => setState(() {}),
          ),
        ),
        const SizedBox(height: 18),
        const RecordSummary(
          text: 'Queda "por liquidar". Cuando el comprador te dé su lista, registra la liquidación por calidad en Cosechas.',
        ),
      ],
    );
  }
}
