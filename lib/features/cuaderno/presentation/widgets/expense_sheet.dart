import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/datasources/evidencia_local_datasource.dart';

const laborCategory = 'Mano de obra';

/// Catálogo de categorías de gasto (RF-CUA-02): (clave guardada, nombre, icono).
const expenseCategories = <(String, String, IconData)>[
  (laborCategory, 'Jornales', Icons.groups_rounded),
  ('Fitosanitarios', 'Fumigación', Icons.pest_control_rounded),
  ('Fertilizantes', 'Abonos', Icons.grass_rounded),
  ('Riego', 'Riego / agua', Icons.water_drop_rounded),
  ('Maquinaria', 'Maquinaria', Icons.agriculture_rounded),
  ('Semilla / plantín', 'Semilla', Icons.spa_rounded),
  ('Envases', 'Envases', Icons.inventory_2_rounded),
  ('Alquiler de terreno', 'Alquiler', Icons.landscape_rounded),
  ('Transporte de insumos', 'Transporte', Icons.local_shipping_rounded),
  ('Otros', 'Otros', Icons.more_horiz_rounded),
];

const _labores = ['Siembra', 'Deshierbe', 'Fumigación', 'Riego', 'Abonamiento', 'Cosecha', 'Amarre / estacado'];
const _extrasSugeridos = ['Pasaje', 'Agua', 'Gaseosas', 'Fruta', 'Refrigerio'];

/// Etapas del cultivo (RF-CUA-02) para ver en qué etapa se va la plata.
const expenseStages = <(String, String, IconData)>[
  ('Preparación', 'Preparación', Icons.landscape_rounded),
  ('Siembra', 'Siembra', Icons.spa_rounded),
  ('Mantenimiento', 'Mantenimiento', Icons.eco_rounded),
  ('Cosecha', 'Cosecha', Icons.shopping_basket_rounded),
];

/// Etapa sugerida según la categoría (y la labor, en jornales).
String suggestedStage(String category, {String? labor}) => switch (category) {
      'Maquinaria' || 'Alquiler de terreno' => 'Preparación',
      'Semilla / plantín' => 'Siembra',
      'Envases' => 'Cosecha',
      laborCategory when labor == 'Siembra' => 'Siembra',
      laborCategory when labor == 'Cosecha' => 'Cosecha',
      _ => 'Mantenimiento',
    };

/// Formas de pago de un gasto: (índice, nombre, icono).
const _formasPago = <(int, String, IconData)>[
  (0, 'Efectivo', Icons.wallet_rounded),
  (1, 'Yape / Plin', Icons.smartphone_rounded),
  (2, 'Debo (fiado)', Icons.pending_actions_rounded),
];

Future<void> showExpenseSheet(
  BuildContext context, {
  required int campanaId,
  required String campanaNombre,
  String? categoria,
  DateTime? date,
}) =>
    showRecordSheet(
      context,
      ExpenseSheet(campanaId: campanaId, campanaNombre: campanaNombre, initialCategory: categoria, initialDate: date),
    );

/// Gasto adicional de una jornada (pasaje, agua, gaseosas…).
class _Extra {
  final String nombre;
  final TextEditingController monto = TextEditingController();

  _Extra(this.nombre);

  double get value => AmountInput.parse(monto);
}

class ExpenseSheet extends ConsumerStatefulWidget {
  final int campanaId;
  final String campanaNombre;
  final String? initialCategory;
  final DateTime? initialDate;

  const ExpenseSheet({
    super.key,
    required this.campanaId,
    required this.campanaNombre,
    this.initialCategory,
    this.initialDate,
  });

  @override
  ConsumerState<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<ExpenseSheet> {
  /// Último pago por jornal usado en esta sesión, para no reescribirlo cada vez.
  static double _lastDailyPay = 70;

  late String _category = expenseCategories
      .firstWhere((c) => c.$1 == widget.initialCategory, orElse: () => expenseCategories.first)
      .$1;
  late DateTime _date = widget.initialDate ?? DateTime.now();

  final _amountCtrl = TextEditingController();

  // Jornales
  late final _payCtrl = TextEditingController(text: _lastDailyPay.toStringAsFixed(0));
  int _workers = 1;
  int _days = 1;
  String? _labor;
  final List<_Extra> _extras = [];

  int _payment = 0;
  String? _stage; // null = se usa la sugerida
  final _noteCtrl = TextEditingController();
  File? _photo;
  bool _saving = false;

  bool get _isLabor => _category == laborCategory;
  String get _effectiveStage => _stage ?? suggestedStage(_category, labor: _labor);
  double get _dailyPay => AmountInput.parse(_payCtrl);
  double get _laborSubtotal => _dailyPay * _workers * _days;
  double get _extrasTotal => _extras.fold(0, (s, e) => s + e.value);
  double get _total => _isLabor ? _laborSubtotal + _extrasTotal : AmountInput.parse(_amountCtrl);

  @override
  void dispose() {
    _amountCtrl.dispose();
    _payCtrl.dispose();
    _noteCtrl.dispose();
    for (final e in _extras) {
      e.monto.dispose();
    }
    super.dispose();
  }

  String _description() {
    final parts = <String>[];
    if (_isLabor) {
      parts.add('$_workers trabajador${_workers == 1 ? '' : 'es'} × ${formatSoles(_dailyPay)}'
          '${_days > 1 ? ' × $_days días' : ''}');
      if (_labor != null) parts.add(_labor!);
      final extras = _extras.where((e) => e.value > 0).map((e) => '${e.nombre} ${formatSoles(e.value)}');
      if (extras.isNotEmpty) parts.add('Extras: ${extras.join(', ')}');
    }
    if (_noteCtrl.text.trim().isNotEmpty) parts.add(_noteCtrl.text.trim());
    parts.add(_formasPago[_payment].$2);
    return parts.join(' · ');
  }

  Future<void> _save() async {
    if (_total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un monto mayor a cero')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final now = DateTime.now();
      final id = await ref.read(cuadernoProvider.notifier).addTransaccion(
            widget.campanaId,
            tipo: 'gasto',
            categoria: _category,
            monto: _total,
            descripcion: _description(),
            fecha: DateTime(_date.year, _date.month, _date.day, now.hour, now.minute).toIso8601String(),
            estadoPago: _payment == 2 ? 'por_pagar' : 'pagado',
            etapa: _effectiveStage,
          );
      if (_photo != null) {
        await EvidenciaLocalDatasource().saveEvidencia(
          relacionId: id,
          relacionTipo: 'transaccion',
          rutaArchivo: _photo!.path,
        );
      }
      if (_isLabor) _lastDailyPay = _dailyPay;
      ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
      HapticFeedback.mediumImpact();
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('Gasto de ${formatSoles(_total)} guardado')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 75, maxWidth: 1600);
    if (picked == null) return;
    final saved = await EvidenciaLocalDatasource().copyToEvidencias(picked.path);
    if (mounted) setState(() => _photo = saved);
  }

  @override
  Widget build(BuildContext context) {
    final category = expenseCategories.firstWhere((c) => c.$1 == _category);
    return RecordSheetScaffold(
      title: 'Nuevo gasto',
      subtitle: widget.campanaNombre,
      date: _date,
      onDateChanged: (d) => setState(() => _date = d),
      saveBar: RecordSaveBar(label: 'Guardar gasto', saving: _saving, onSave: _save, total: _total),
      children: [
        const StepTitle(number: 1, title: 'Categoría de gasto'),
        SelectPillRow<String>(
          options: [for (final (key, label, icon) in expenseCategories) (key, label, icon)],
          selected: _category,
          onSelected: (v) => setState(() => _category = v),
        ),
        const SizedBox(height: 22),
        if (_isLabor)
          ..._laborSection(Theme.of(context).textTheme)
        else ...[
          StepTitle(
            number: 2,
            title: 'Monto',
            action: TextButton.icon(
              onPressed: () => setState(_amountCtrl.clear),
              icon: Icon(Icons.backspace_outlined, size: 16, color: AppColors.error),
              label: Text('Limpiar', style: TextStyle(color: AppColors.error)),
            ),
          ),
          AmountInput(controller: _amountCtrl, caption: 'MONTO DEL GASTO', onChanged: () => setState(() {})),
        ],
        const SizedBox(height: 22),
        StepTitle(number: _isLabor ? 4 : 3, title: 'Etapa del cultivo'),
        OptionTiles<String>(
          options: expenseStages,
          selected: _effectiveStage,
          onSelected: (v) => setState(() => _stage = v),
        ),
        const SizedBox(height: 22),
        StepTitle(number: _isLabor ? 5 : 4, title: '¿Cómo pagaste?'),
        OptionTiles<int>(options: _formasPago, selected: _payment, onSelected: (v) => setState(() => _payment = v)),
        const SizedBox(height: 22),
        StepTitle(number: _isLabor ? 6 : 5, title: 'Nota y comprobante (opcional)'),
        TextField(
          controller: _noteCtrl,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Ej. Cuadrilla de don Juan, lote 2'),
        ),
        const SizedBox(height: 10),
        PhotoPickerTile(photo: _photo, onPick: _pickPhoto),
        const SizedBox(height: 18),
        RecordSummary(text: '${category.$2} · $_effectiveStage · ${_description()}'),
      ],
    );
  }

  List<Widget> _laborSection(TextTheme text) => [
        const StepTitle(number: 2, title: 'Pago a la cuadrilla'),
        GlassCard(
          radius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text('Pago por jornal', style: text.titleSmall)),
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: _payCtrl,
                      textAlign: TextAlign.end,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      style: AppTheme.display(fontSize: 20, color: AppColors.text),
                      decoration: const InputDecoration(prefixText: 'S/ ', isDense: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final v in [50, 60, 70, 80, 100])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: MiniChip(
                        label: '$v',
                        selected: _dailyPay == v,
                        onTap: () => setState(() => _payCtrl.text = '$v'),
                      ),
                    ),
                ],
              ),
              const Divider(height: 28),
              _Stepper(
                icon: Icons.groups_rounded,
                label: 'Trabajadores',
                value: _workers,
                onChanged: (v) => setState(() => _workers = v),
              ),
              const SizedBox(height: 12),
              _Stepper(
                icon: Icons.calendar_view_day_rounded,
                label: 'Días',
                value: _days,
                onChanged: (v) => setState(() => _days = v),
              ),
              const Divider(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$_workers × ${formatSoles(_dailyPay)}${_days > 1 ? ' × $_days días' : ''}',
                      style: text.bodySmall,
                    ),
                  ),
                  Text(formatSoles(_laborSubtotal), style: AppTheme.display(fontSize: 18, color: AppColors.text)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('¿Qué labor hicieron?', style: text.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final l in _labores)
              MiniChip(
                label: l,
                selected: _labor == l,
                large: true,
                onTap: () => setState(() => _labor = _labor == l ? null : l),
              ),
          ],
        ),
        const SizedBox(height: 22),
        const StepTitle(number: 3, title: 'Gastos adicionales'),
        Text('Pasaje, agua, gaseosas, fruta… se suman al total.', style: text.bodySmall),
        const SizedBox(height: 10),
        for (final e in _extras) ...[
          _ExtraRow(
            extra: e,
            onChanged: () => setState(() {}),
            onRemove: () => setState(() {
              _extras.remove(e);
              e.monto.dispose();
            }),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in _extrasSugeridos.where((n) => !_extras.any((e) => e.nombre == n)))
              MiniChip(label: '+ $name', large: true, onTap: () => setState(() => _extras.add(_Extra(name)))),
            MiniChip(label: '+ Otro', large: true, onTap: _addCustomExtra),
          ],
        ),
      ];

  Future<void> _addCustomExtra() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gasto adicional'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej. Combustible moto'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Agregar')),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null && name.isNotEmpty) setState(() => _extras.add(_Extra(name)));
  }
}

/// Contador con botones grandes − / + (uso con guantes).
class _Stepper extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _Stepper({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget button(IconData i, VoidCallback? onTap) => Material(
          color: onTap == null ? AppColors.accentSoft.withValues(alpha: 0.5) : AppColors.accentSoft,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(i, color: onTap == null ? AppColors.textSubtle : AppColors.accent),
            ),
          ),
        );

    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
        button(Icons.remove_rounded, value > 1 ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 52,
          child: Text('$value', textAlign: TextAlign.center, style: AppTheme.display(fontSize: 24, color: AppColors.text)),
        ),
        button(Icons.add_rounded, () => onChanged(value + 1)),
      ],
    );
  }
}

class _ExtraRow extends StatelessWidget {
  final _Extra extra;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ExtraRow({required this.extra, required this.onChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(extra.nombre, style: Theme.of(context).textTheme.titleSmall)),
        SizedBox(
          width: 120,
          child: TextField(
            controller: extra.monto,
            autofocus: extra.monto.text.isEmpty,
            textAlign: TextAlign.end,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: const InputDecoration(prefixText: 'S/ ', isDense: true, hintText: '0'),
            onChanged: (_) => onChanged(),
          ),
        ),
        IconButton(
          tooltip: 'Quitar',
          onPressed: onRemove,
          icon: Icon(Icons.close_rounded, color: AppColors.textSubtle),
        ),
      ],
    );
  }
}
