import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../cosechas/domain/entities/cosecha.dart';
import '../../../cosechas/presentation/screens/despacho_screen.dart';
import 'expense_sheet.dart' show expenseCategories, expenseStages;
import 'record_sheets.dart' show incomeConcepts, incidentTypes;

/// Pulsación larga sobre un registro del cuaderno: corregirlo o eliminarlo.
/// Los despachos y ventas se corrigen desde su detalle.
Future<void> mostrarOpcionesRegistro(BuildContext context, WidgetRef ref, HistorialEntry entry) async {
  final fila = entry.registro;
  if (fila == null) return;
  HapticFeedback.mediumImpact();
  final esCosecha = entry.tipo == 'cosecha';
  final accion = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(entry.titulo, style: Theme.of(ctx).textTheme.titleSmall),
            subtitle: entry.monto == null ? null : Text(formatSoles(entry.monto!)),
          ),
          if (esCosecha)
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Ver y corregir la venta'),
              onTap: () => Navigator.of(ctx).pop('despacho'),
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar'),
              subtitle: const Text('Corregir monto, fecha o detalle'),
              onTap: () => Navigator.of(ctx).pop('editar'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: Text('Eliminar', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.of(ctx).pop('eliminar'),
            ),
          ],
        ],
      ),
    ),
  );
  if (accion == null || !context.mounted) return;

  switch (accion) {
    case 'despacho':
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => DespachoScreen(cosecha: Cosecha.fromMap(fila))),
      );
    case 'editar':
      final hoja = switch (entry.tipo) {
        'gasto' || 'ingreso' => _EditarMovimiento(fila: fila),
        'incidencia' => _EditarIncidencia(fila: fila),
        _ => _EditarLabor(fila: fila),
      };
      await showRecordSheet(context, hoja);
    case 'eliminar':
      await _eliminar(context, ref, entry, fila);
  }
}

Future<void> _eliminar(BuildContext context, WidgetRef ref, HistorialEntry entry, Map<String, dynamic> fila) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar registro'),
      content: Text('${entry.titulo}${entry.monto == null ? '' : ' · ${formatSoles(entry.monto!)}'}\n\nSe borra de este teléfono y no se puede deshacer.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Eliminar', style: TextStyle(color: AppColors.error))),
      ],
    ),
  );
  if (ok != true) return;
  final ds = ref.read(campanaLocalDatasourceProvider);
  final id = fila['id'] as int;
  switch (entry.tipo) {
    case 'gasto' || 'ingreso':
      await ds.deleteTransaccion(id);
    case 'incidencia':
      await ds.deleteIncidencia(id);
    default:
      await ds.deleteActividad(id);
  }
  ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro eliminado')));
}

/// Fecha guardada → DateTime (o hoy si no se puede leer).
DateTime _fecha(Object? v) => DateTime.tryParse(v as String? ?? '') ?? DateTime.now();

/// Conserva la hora original al cambiar solo el día.
String _conDia(DateTime dia, DateTime original) =>
    DateTime(dia.year, dia.month, dia.day, original.hour, original.minute).toIso8601String();

// ═══ Gasto o ingreso ═══

class _EditarMovimiento extends ConsumerStatefulWidget {
  final Map<String, dynamic> fila;

  const _EditarMovimiento({required this.fila});

  @override
  ConsumerState<_EditarMovimiento> createState() => _EditarMovimientoState();
}

class _EditarMovimientoState extends ConsumerState<_EditarMovimiento> {
  late final bool _gasto = widget.fila['tipo'] == 'gasto';
  late final DateTime _original = _fecha(widget.fila['fecha']);
  late DateTime _dia = _original;
  late final _montoCtrl = TextEditingController(text: _num((widget.fila['monto'] as num?)?.toDouble() ?? 0));
  late final _descCtrl = TextEditingController(text: widget.fila['descripcion'] as String? ?? '');
  late String _categoria = widget.fila['categoria'] as String? ?? '';
  late String? _etapa = widget.fila['etapa'] as String?;
  late String _estado = widget.fila['estado_pago'] as String? ?? 'pagado';
  bool _saving = false;

  static String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final monto = AmountInput.parse(_montoCtrl);
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un monto mayor a cero')));
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(campanaLocalDatasourceProvider).updateTransaccion(widget.fila['id'] as int, {
      'monto': monto,
      'categoria': _categoria,
      'descripcion': _descCtrl.text.trim(),
      'fecha': _conDia(_dia, _original),
      'estado_pago': _estado,
      if (_gasto) 'etapa': _etapa,
    });
    ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text('${_gasto ? 'Gasto' : 'Ingreso'} corregido: ${formatSoles(monto)}')));
  }

  @override
  Widget build(BuildContext context) {
    final categorias = _gasto ? [for (final c in expenseCategories) (c.$1, c.$2, c.$3)] : incomeConcepts;
    // Si la categoría guardada no está en la lista (texto antiguo), se muestra igual.
    final opciones = categorias.any((c) => c.$1 == _categoria) || _categoria.isEmpty
        ? categorias
        : [( _categoria, _categoria, Icons.label_outline_rounded), ...categorias];
    final estados = _gasto
        ? const [('pagado', 'Pagado', Icons.check_circle_outline_rounded), ('por_pagar', 'Debo (fiado)', Icons.pending_actions_rounded)]
        : const [('pagado', 'Cobrado', Icons.check_circle_outline_rounded), ('por_cobrar', 'Me deben', Icons.schedule_rounded)];

    return RecordSheetScaffold(
      title: _gasto ? 'Editar gasto' : 'Editar ingreso',
      subtitle: 'Corrige lo que anotaste mal',
      date: _dia,
      onDateChanged: (d) => setState(() => _dia = d),
      saveBar: RecordSaveBar(label: 'Guardar cambios', saving: _saving, onSave: _guardar, total: AmountInput.parse(_montoCtrl)),
      children: [
        AmountInput(controller: _montoCtrl, onChanged: () => setState(() {})),
        const SizedBox(height: 20),
        StepTitle(number: 1, title: _gasto ? 'Categoría' : 'Concepto'),
        SelectPillRow<String>(options: opciones, selected: _categoria, onSelected: (v) => setState(() => _categoria = v)),
        if (_gasto) ...[
          const SizedBox(height: 20),
          const StepTitle(number: 2, title: 'Etapa del cultivo'),
          SelectPillRow<String?>(
            options: [for (final e in expenseStages) (e.$1, e.$2, e.$3)],
            selected: _etapa,
            onSelected: (v) => setState(() => _etapa = v),
          ),
        ],
        const SizedBox(height: 20),
        StepTitle(number: _gasto ? 3 : 2, title: _gasto ? 'Pago' : 'Cobro'),
        OptionTiles<String>(options: estados, selected: _estado, onSelected: (v) => setState(() => _estado = v)),
        const SizedBox(height: 20),
        StepTitle(number: _gasto ? 4 : 3, title: 'Detalle'),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Descripción'),
        ),
      ],
    );
  }
}

// ═══ Labor ═══

class _EditarLabor extends ConsumerStatefulWidget {
  final Map<String, dynamic> fila;

  const _EditarLabor({required this.fila});

  @override
  ConsumerState<_EditarLabor> createState() => _EditarLaborState();
}

class _EditarLaborState extends ConsumerState<_EditarLabor> {
  late final DateTime _original = _fecha(widget.fila['fecha']);
  late DateTime _dia = _original;
  late final _descCtrl = TextEditingController(text: widget.fila['descripcion'] as String? ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    await ref.read(campanaLocalDatasourceProvider).updateActividad(widget.fila['id'] as int, {
      'descripcion': desc,
      'fecha': _conDia(_dia, _original),
    });
    ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return RecordSheetScaffold(
      title: 'Editar labor',
      subtitle: 'Corrige la descripción o la fecha',
      date: _dia,
      onDateChanged: (d) => setState(() => _dia = d),
      saveBar: RecordSaveBar(label: 'Guardar cambios', saving: _saving, onSave: _guardar),
      children: [
        const StepTitle(number: 1, title: 'Labor'),
        TextField(
          controller: _descCtrl,
          maxLines: 4,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej. Fumigación · Abamectina en el lote norte'),
        ),
      ],
    );
  }
}

// ═══ Incidencia ═══

class _EditarIncidencia extends ConsumerStatefulWidget {
  final Map<String, dynamic> fila;

  const _EditarIncidencia({required this.fila});

  @override
  ConsumerState<_EditarIncidencia> createState() => _EditarIncidenciaState();
}

class _EditarIncidenciaState extends ConsumerState<_EditarIncidencia> {
  late final DateTime _original = _fecha(widget.fila['fecha']);
  late DateTime _dia = _original;
  late String _tipo = widget.fila['tipo'] as String? ?? incidentTypes.first.$1;
  late String _severidad = widget.fila['severidad'] as String? ?? 'media';
  late final _notaCtrl = TextEditingController(text: widget.fila['nota'] as String? ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final nota = _notaCtrl.text.trim();
    await ref.read(campanaLocalDatasourceProvider).updateIncidencia(widget.fila['id'] as int, {
      'tipo': _tipo,
      'severidad': _severidad,
      'nota': nota.isEmpty ? null : nota,
      'fecha': _conDia(_dia, _original),
    });
    ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tipos = incidentTypes.any((t) => t.$1 == _tipo) ? incidentTypes : [(_tipo, _tipo, Icons.warning_amber_rounded), ...incidentTypes];
    return RecordSheetScaffold(
      title: 'Editar incidencia',
      subtitle: 'Corrige el tipo, la severidad o la nota',
      date: _dia,
      onDateChanged: (d) => setState(() => _dia = d),
      saveBar: RecordSaveBar(label: 'Guardar cambios', saving: _saving, onSave: _guardar),
      children: [
        const StepTitle(number: 1, title: 'Tipo'),
        SelectPillRow<String>(options: tipos, selected: _tipo, onSelected: (v) => setState(() => _tipo = v)),
        const SizedBox(height: 20),
        const StepTitle(number: 2, title: 'Severidad'),
        OptionTiles<String>(
          options: const [
            ('baja', 'Baja', Icons.signal_cellular_alt_1_bar_rounded),
            ('media', 'Media', Icons.signal_cellular_alt_2_bar_rounded),
            ('alta', 'Alta', Icons.signal_cellular_alt_rounded),
          ],
          selected: _severidad,
          onSelected: (v) => setState(() => _severidad = v),
        ),
        const SizedBox(height: 20),
        const StepTitle(number: 3, title: 'Nota'),
        TextField(
          controller: _notaCtrl,
          maxLines: 4,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Qué pasó, dónde, qué se hizo'),
        ),
      ],
    );
  }
}
