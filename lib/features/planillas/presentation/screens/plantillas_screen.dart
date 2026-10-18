import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../../campanas/presentation/campaign_display.dart';
import '../../data/datasources/plantilla_local_datasource.dart';
import '../../domain/entities/plantilla_cultivo.dart';

/// Plantillas guardadas, de la A a la Z.
final plantillasProvider = FutureProvider<List<PlantillaCultivo>>((ref) => PlantillaLocalDatasource().listar());

/// Plantilla de un cultivo (o la básica), por ejemplo para el peso por envase.
final plantillaDeCultivoProvider = FutureProvider.family<PlantillaCultivo, String>((ref, cultivo) {
  ref.watch(plantillasProvider);
  return PlantillaLocalDatasource().paraCultivo(cultivo);
});

/// Plantillas de cultivo (Diseño v2): calidades de la hoja, filas del camión,
/// envase y peso promedio. Cada cultivo tiene la suya; sin plantilla se usa
/// una básica de tres calidades.
class PlantillasScreen extends ConsumerWidget {
  const PlantillasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final plantillas = ref.watch(plantillasProvider).value ?? const <PlantillaCultivo>[];
    final conPlantilla = {for (final p in plantillas) p.cultivo.toLowerCase()};
    // Cultivos de tus campañas que aún usan la plantilla básica.
    final sinPlantilla = {
      for (final c in ref.watch(campanaListProvider).campanas)
        if (!conPlantilla.contains(c.cultivo.toLowerCase())) c.cultivo,
    };

    return AgroBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GlassCircleButton(icon: Icons.arrow_back_rounded, tooltip: 'Volver', onPressed: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 12),
                  Text('Plantillas de cultivo', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text(
              'Las calidades son las columnas de la hoja de anotación. Cambiarlas solo afecta a las hojas nuevas.',
              style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            for (final p in plantillas) ...[
              _PlantillaCard(plantilla: p, onTap: () => showRecordSheet(context, _PlantillaSheet(plantilla: p))),
              const SizedBox(height: 10),
            ],
            for (final cultivo in sinPlantilla) ...[
              GlassCard(
                radius: 20,
                padding: const EdgeInsets.all(14),
                onTap: () => showRecordSheet(context, _PlantillaSheet(plantilla: PlantillaCultivo.basica(cultivo))),
                child: Row(
                  children: [
                    Text(cropEmoji(cultivo), style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cultivo, style: text.titleSmall),
                          Text('Usa la plantilla básica (I, II, III). Toca para ajustarla.', style: text.bodySmall),
                        ],
                      ),
                    ),
                    Icon(Icons.add_circle_outline_rounded, color: AppColors.accent),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AgroActionButton(
            label: 'Nueva plantilla',
            icon: Icons.add_rounded,
            primary: true,
            height: 56,
            onPressed: () => showRecordSheet(context, _PlantillaSheet(plantilla: PlantillaCultivo.basica(''))),
          ),
        ),
      ),
    );
  }
}

class _PlantillaCard extends StatelessWidget {
  final PlantillaCultivo plantilla;
  final VoidCallback onTap;

  const _PlantillaCard({required this.plantilla, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = plantilla;
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(cropEmoji(p.cultivo), style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.cultivo, style: text.titleSmall),
                    Text(
                      [
                        '${p.filas} filas',
                        p.envase,
                        if (p.pesoEnvaseKg != null) '≈ ${_num(p.pesoEnvaseKg!)} kg por ${p.envase}',
                      ].join(' · '),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, size: 20, color: AppColors.textSubtle),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in p.calidades)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: c.codigo, style: AppTheme.display(fontSize: 12, color: AppColors.accent)),
                        TextSpan(text: ' ${c.nombre}', style: text.labelMedium?.copyWith(color: AppColors.text)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _num(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Calidad en edición: dos campos (símbolo y nombre).
class _CalidadEdit {
  final TextEditingController codigo;
  final TextEditingController nombre;

  _CalidadEdit(String c, String n)
      : codigo = TextEditingController(text: c),
        nombre = TextEditingController(text: n);

  void dispose() {
    codigo.dispose();
    nombre.dispose();
  }
}

class _PlantillaSheet extends ConsumerStatefulWidget {
  final PlantillaCultivo plantilla;

  const _PlantillaSheet({required this.plantilla});

  @override
  ConsumerState<_PlantillaSheet> createState() => _PlantillaSheetState();
}

class _PlantillaSheetState extends ConsumerState<_PlantillaSheet> {
  late final _cultivoCtrl = TextEditingController(text: widget.plantilla.cultivo);
  late final _calidades = [for (final c in widget.plantilla.calidades) _CalidadEdit(c.codigo, c.nombre)];
  late int _filas = widget.plantilla.filas;
  late String _envase = widget.plantilla.envase;
  late final _pesoCtrl = TextEditingController(
    text: widget.plantilla.pesoEnvaseKg == null ? '' : _num(widget.plantilla.pesoEnvaseKg!),
  );
  bool _saving = false;

  bool get _existe => widget.plantilla.id != null;

  @override
  void dispose() {
    _cultivoCtrl.dispose();
    _pesoCtrl.dispose();
    for (final c in _calidades) {
      c.dispose();
    }
    super.dispose();
  }

  void _mover(int i, int delta) {
    final j = i + delta;
    if (j < 0 || j >= _calidades.length) return;
    setState(() => _calidades.insert(j, _calidades.removeAt(i)));
  }

  Future<void> _guardar() async {
    final messenger = ScaffoldMessenger.of(context);
    final cultivo = _cultivoCtrl.text.trim();
    final calidades = [
      for (final c in _calidades)
        if (c.codigo.text.trim().isNotEmpty) (codigo: c.codigo.text.trim().toUpperCase(), nombre: c.nombre.text.trim()),
    ];
    if (cultivo.isEmpty || calidades.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Escribe el cultivo y al menos una calidad')));
      return;
    }
    if (calidades.map((c) => c.codigo).toSet().length != calidades.length) {
      messenger.showSnackBar(const SnackBar(content: Text('Dos calidades tienen el mismo símbolo')));
      return;
    }
    setState(() => _saving = true);
    final peso = AmountInput.parse(_pesoCtrl);
    await PlantillaLocalDatasource().guardar(PlantillaCultivo(
      id: widget.plantilla.id,
      cultivo: cultivo,
      calidades: [for (final c in calidades) (codigo: c.codigo, nombre: c.nombre.isEmpty ? c.codigo : c.nombre)],
      filas: _filas,
      envase: _envase,
      pesoEnvaseKg: peso > 0 ? peso : null,
    ));
    ref.invalidate(plantillasProvider);
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text('Plantilla de $cultivo guardada')));
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar plantilla'),
        content: Text('Las hojas nuevas de ${widget.plantilla.cultivo} usarán la plantilla básica. Las hojas ya hechas no cambian.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Eliminar', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    await PlantillaLocalDatasource().eliminar(widget.plantilla.id!);
    ref.invalidate(plantillasProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return RecordSheetScaffold(
      title: _existe ? 'Plantilla de ${widget.plantilla.cultivo}' : 'Nueva plantilla',
      subtitle: 'Columnas y filas de la hoja de anotación',
      saveBar: RecordSaveBar(label: 'Guardar plantilla', saving: _saving, onSave: _guardar),
      children: [
        const StepTitle(number: 1, title: 'Cultivo'),
        TextField(
          controller: _cultivoCtrl,
          enabled: !_existe && widget.plantilla.cultivo.isEmpty,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej. Cebolla', prefixIcon: Icon(Icons.eco_outlined)),
        ),
        const SizedBox(height: 22),
        StepTitle(
          number: 2,
          title: 'Calidades (columnas)',
          action: TextButton.icon(
            onPressed: () => setState(() => _calidades.add(_CalidadEdit('', ''))),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Agregar'),
          ),
        ),
        for (final (i, c) in _calidades.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: c.codigo,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 4,
                    style: AppTheme.display(fontSize: 16, color: AppColors.accent),
                    decoration: const InputDecoration(hintText: 'I', counterText: ''),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: c.nombre,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Nombre. Ej. Primera'),
                  ),
                ),
                IconButton(
                  tooltip: 'Subir',
                  onPressed: i == 0 ? null : () => _mover(i, -1),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                ),
                IconButton(
                  tooltip: 'Quitar',
                  onPressed: _calidades.length == 1 ? null : () => setState(() => _calidades.removeAt(i).dispose()),
                  icon: Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        const StepTitle(number: 3, title: 'Filas de una hoja nueva'),
        GlassCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text('Filas del camión', style: text.titleSmall)),
              IconButton(onPressed: _filas > 1 ? () => setState(() => _filas--) : null, icon: const Icon(Icons.remove_rounded)),
              SizedBox(width: 40, child: Text('$_filas', textAlign: TextAlign.center, style: AppTheme.display(fontSize: 20, color: AppColors.text))),
              IconButton(onPressed: _filas < 60 ? () => setState(() => _filas++) : null, icon: const Icon(Icons.add_rounded)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text('En la hoja puedes agregar o quitar filas. El total por fila es libre.', style: text.bodySmall),
        ),
        const SizedBox(height: 22),
        const StepTitle(number: 4, title: 'Envase'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in envasesCosecha)
              MiniChip(label: e[0].toUpperCase() + e.substring(1), large: true, selected: _envase == e, onTap: () => setState(() => _envase = e)),
          ],
        ),
        const SizedBox(height: 22),
        StepTitle(number: 5, title: 'Peso promedio por $_envase (opcional)'),
        TextField(
          controller: _pesoCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: const InputDecoration(hintText: 'Ej. 22', suffixText: 'kg', prefixIcon: Icon(Icons.scale_outlined)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text('Sirve para estimar los kilos y el costo por kilo en el resumen.', style: text.bodySmall),
        ),
        if (_existe) ...[
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: _eliminar,
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
            label: Text('Eliminar plantilla', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ],
    );
  }
}
