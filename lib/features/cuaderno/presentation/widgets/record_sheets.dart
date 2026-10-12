import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../data/datasources/evidencia_local_datasource.dart';
import '../../domain/entities/actividad.dart';

/// Formularios del cuaderno: labor (RF-CUA-01), ingreso directo (RF-CUA-06)
/// e incidencia (RF-CUA-08). Comparten estilo con el de gasto.

const _laborTypes = <(String, String, IconData)>[
  ('Deshierbe', 'Deshierbe', Icons.grass_rounded),
  ('Riego', 'Riego', Icons.water_drop_rounded),
  ('Fumigación', 'Fumigación', Icons.pest_control_rounded),
  ('Abonamiento', 'Abonamiento', Icons.science_rounded),
  ('Siembra / trasplante', 'Siembra', Icons.spa_rounded),
  ('Preparación de suelo', 'Preparación', Icons.agriculture_rounded),
  ('Surcado', 'Surcado', Icons.view_week_rounded),
  ('Poda / amarre', 'Poda / amarre', Icons.content_cut_rounded),
  ('Cosecha', 'Cosecha', Icons.shopping_basket_rounded),
  ('Otra labor', 'Otra', Icons.more_horiz_rounded),
];

const _incomeConcepts = <(String, String, IconData)>[
  ('Venta en campo', 'Venta en campo', Icons.storefront_rounded),
  ('Venta menor', 'Venta menor', Icons.shopping_bag_rounded),
  ('Apoyo / subsidio', 'Apoyo', Icons.volunteer_activism_rounded),
  ('Otro ingreso', 'Otro', Icons.more_horiz_rounded),
];

const _incidentTypes = <(String, String, IconData)>[
  ('Plaga', 'Plaga', Icons.bug_report_rounded),
  ('Enfermedad', 'Enfermedad', Icons.coronavirus_rounded),
  ('Helada', 'Helada', Icons.ac_unit_rounded),
  ('Granizo', 'Granizo', Icons.thunderstorm_rounded),
  ('Agua (falta o exceso)', 'Agua', Icons.water_damage_rounded),
  ('Robo', 'Robo', Icons.report_rounded),
  ('Otra incidencia', 'Otra', Icons.more_horiz_rounded),
];

Future<void> showLaborSheet(BuildContext context, {required int campanaId, required String campanaNombre, DateTime? date}) =>
    showRecordSheet(context, _ActivitySheet(campanaId: campanaId, campanaNombre: campanaNombre, incident: false, date: date));

Future<void> showIncidentSheet(BuildContext context, {required int campanaId, required String campanaNombre, DateTime? date}) =>
    showRecordSheet(context, _ActivitySheet(campanaId: campanaId, campanaNombre: campanaNombre, incident: true, date: date));

Future<void> showIncomeSheet(BuildContext context, {required int campanaId, required String campanaNombre, DateTime? date}) =>
    showRecordSheet(context, _IncomeSheet(campanaId: campanaId, campanaNombre: campanaNombre, date: date));

String _fechaIso(DateTime date) {
  final now = DateTime.now();
  return DateTime(date.year, date.month, date.day, now.hour, now.minute).toIso8601String();
}

Future<File?> _pickPhoto(ImageSource source) async {
  final picked = await ImagePicker().pickImage(source: source, imageQuality: 75, maxWidth: 1600);
  if (picked == null) return null;
  return EvidenciaLocalDatasource().copyToEvidencias(picked.path);
}

/// Labor o incidencia: ambas se guardan como actividad del cuaderno.
class _ActivitySheet extends ConsumerStatefulWidget {
  final int campanaId;
  final String campanaNombre;
  final bool incident;
  final DateTime? date;

  const _ActivitySheet({required this.campanaId, required this.campanaNombre, required this.incident, this.date});

  @override
  ConsumerState<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends ConsumerState<_ActivitySheet> {
  late String _type = (widget.incident ? _incidentTypes : _laborTypes).first.$1;
  String _severity = 'Media';
  late DateTime _date = widget.date ?? DateTime.now();
  final _noteCtrl = TextEditingController();
  File? _photo;
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  String _description() {
    final note = _noteCtrl.text.trim();
    if (widget.incident) {
      return '$kIncidentPrefix$_type · Severidad ${_severity.toLowerCase()}${note.isEmpty ? '' : ' · $note'}';
    }
    return note.isEmpty ? _type : '$_type · $note';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final id = await ref
          .read(cuadernoProvider.notifier)
          .addActividad(widget.campanaId, _description(), _fechaIso(_date));
      if (_photo != null) {
        await EvidenciaLocalDatasource().saveEvidencia(
          relacionId: id,
          relacionTipo: 'actividad',
          rutaArchivo: _photo!.path,
        );
      }
      ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
      HapticFeedback.mediumImpact();
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(widget.incident ? 'Incidencia registrada' : 'Labor registrada')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    return RecordSheetScaffold(
      title: incident ? 'Nueva incidencia' : 'Nueva labor',
      subtitle: widget.campanaNombre,
      date: _date,
      onDateChanged: (d) => setState(() => _date = d),
      saveBar: RecordSaveBar(
        label: incident ? 'Guardar incidencia' : 'Guardar labor',
        saving: _saving,
        onSave: _save,
      ),
      children: [
        StepTitle(number: 1, title: incident ? '¿Qué pasó?' : '¿Qué labor se hizo?'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label, icon) in incident ? _incidentTypes : _laborTypes)
              SelectPill(icon: icon, label: label, selected: _type == value, onTap: () => setState(() => _type = value)),
          ],
        ),
        if (incident) ...[
          const SizedBox(height: 22),
          const StepTitle(number: 2, title: '¿Qué tan grave?'),
          OptionTiles<String>(
            options: const [
              ('Baja', 'Baja', Icons.sentiment_satisfied_rounded),
              ('Media', 'Media', Icons.sentiment_neutral_rounded),
              ('Alta', 'Alta', Icons.sentiment_very_dissatisfied_rounded),
            ],
            selected: _severity,
            onSelected: (v) => setState(() => _severity = v),
            colorOf: (v) => switch (v) {
              'Baja' => AppColors.positive,
              'Media' => AppColors.warning,
              _ => AppColors.error,
            },
          ),
        ],
        const SizedBox(height: 22),
        StepTitle(number: incident ? 3 : 2, title: 'Detalle y foto (opcional)'),
        TextField(
          controller: _noteCtrl,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: incident ? 'Ej. Polilla en la hilera norte, se aisló el sector' : 'Ej. Lote 2, cuadrilla de la mañana',
          ),
        ),
        const SizedBox(height: 10),
        PhotoPickerTile(
          photo: _photo,
          title: incident ? 'Foto de la incidencia' : 'Foto de la labor',
          hint: incident ? 'Ayuda a recordar y comparar' : 'Opcional',
          onPick: (s) async {
            final file = await _pickPhoto(s);
            if (file != null && mounted) setState(() => _photo = file);
          },
        ),
        const SizedBox(height: 18),
        RecordSummary(text: _description().replaceFirst(kIncidentPrefix, 'Incidencia: ')),
      ],
    );
  }
}

/// Ingreso directo: ventas pequeñas u otros ingresos fuera de cosechas.
class _IncomeSheet extends ConsumerStatefulWidget {
  final int campanaId;
  final String campanaNombre;
  final DateTime? date;

  const _IncomeSheet({required this.campanaId, required this.campanaNombre, this.date});

  @override
  ConsumerState<_IncomeSheet> createState() => _IncomeSheetState();
}

class _IncomeSheetState extends ConsumerState<_IncomeSheet> {
  String _concept = _incomeConcepts.first.$1;
  bool _collected = true;
  late DateTime _date = widget.date ?? DateTime.now();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  File? _photo;
  bool _saving = false;

  double get _amount => AmountInput.parse(_amountCtrl);

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _description() {
    final note = _noteCtrl.text.trim();
    return [if (note.isNotEmpty) note, _collected ? 'Cobrado' : 'Me deben'].join(' · ');
  }

  Future<void> _save() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un monto mayor a cero')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final id = await ref.read(cuadernoProvider.notifier).addTransaccion(
            widget.campanaId,
            tipo: 'ingreso',
            categoria: _concept,
            monto: _amount,
            descripcion: _description(),
            fecha: _fechaIso(_date),
            estadoPago: _collected ? 'pagado' : 'por_cobrar',
          );
      if (_photo != null) {
        await EvidenciaLocalDatasource().saveEvidencia(
          relacionId: id,
          relacionTipo: 'transaccion',
          rutaArchivo: _photo!.path,
        );
      }
      ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
      HapticFeedback.mediumImpact();
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('Ingreso de ${formatSoles(_amount)} guardado')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RecordSheetScaffold(
      title: 'Nuevo ingreso',
      subtitle: widget.campanaNombre,
      date: _date,
      onDateChanged: (d) => setState(() => _date = d),
      saveBar: RecordSaveBar(label: 'Guardar ingreso', saving: _saving, onSave: _save, total: _amount),
      children: [
        const StepTitle(number: 1, title: 'Concepto'),
        SelectPillRow<String>(
          options: _incomeConcepts,
          selected: _concept,
          onSelected: (v) => setState(() => _concept = v),
        ),
        const SizedBox(height: 22),
        const StepTitle(number: 2, title: 'Monto'),
        AmountInput(controller: _amountCtrl, caption: 'MONTO DEL INGRESO', onChanged: () => setState(() {})),
        const SizedBox(height: 22),
        const StepTitle(number: 3, title: '¿Ya te pagaron?'),
        OptionTiles<bool>(
          options: const [
            (true, 'Sí, cobrado', Icons.check_circle_rounded),
            (false, 'Me deben', Icons.schedule_rounded),
          ],
          selected: _collected,
          onSelected: (v) => setState(() => _collected = v),
        ),
        const SizedBox(height: 22),
        const StepTitle(number: 4, title: 'Nota y comprobante (opcional)'),
        TextField(
          controller: _noteCtrl,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Ej. 20 sacos de cebolla a don Pedro'),
        ),
        const SizedBox(height: 10),
        PhotoPickerTile(
          photo: _photo,
          onPick: (s) async {
            final file = await _pickPhoto(s);
            if (file != null && mounted) setState(() => _photo = file);
          },
        ),
        const SizedBox(height: 18),
        RecordSummary(text: '$_concept · ${formatSoles(_amount)} · ${_description()}'),
      ],
    );
  }
}
