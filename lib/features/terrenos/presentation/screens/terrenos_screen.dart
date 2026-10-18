import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/topo_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ubicacion.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../../campanas/data/repositories/campana_repository_impl.dart' show kLocalUserId;
import '../../../campanas/domain/entities/campana.dart';
import '../../../campanas/presentation/campaign_display.dart';
import '../../domain/terreno.dart';
import '../widgets/ubicacion_card.dart';

/// Mis terrenos: cada terreno con su ubicación y el resultado de cada
/// campaña que tuvo (comparativo por terreno, Diseño v2 §3).
class TerrenosScreen extends ConsumerWidget {
  const TerrenosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final terrenos = ref.watch(terrenosProvider);
    final campanas = ref.watch(campanaListProvider).campanas;
    final resumenes = ref.watch(campanaResumenesProvider).value ?? const <int, CampanaResumen>{};
    final m2PorTopo = ref.watch(m2PorTopoProvider);

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
                  Expanded(child: Text('Mis terrenos', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text('El mismo terreno, campaña tras campaña: ¿cuál rinde más?', style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 14),
            if (terrenos.isLoading && !terrenos.hasValue)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if ((terrenos.value ?? const []).isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.landscape_outlined, color: AppColors.textSubtle, size: 32),
                    const SizedBox(height: 8),
                    Text('Aún no tienes terrenos', style: text.bodyMedium),
                    Text('Se crean al iniciar una campaña o con el botón de abajo', style: text.bodySmall, textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              for (final t in terrenos.value!) ...[
                _TerrenoCard(
                  terreno: t,
                  campanas: campanas.where((c) => c.terrenoId == t.id).toList(),
                  resumenes: resumenes,
                  m2PorTopo: m2PorTopo,
                  onEditar: () => showRecordSheet(context, _TerrenoSheet(terreno: t)),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AgroActionButton(
            label: 'Nuevo terreno',
            icon: Icons.add_location_alt_rounded,
            primary: true,
            height: 56,
            onPressed: () => showRecordSheet(context, const _TerrenoSheet()),
          ),
        ),
      ),
    );
  }
}

class _TerrenoCard extends StatelessWidget {
  final Terreno terreno;
  final List<Campana> campanas;
  final Map<int, CampanaResumen> resumenes;
  final double m2PorTopo;
  final VoidCallback onEditar;

  const _TerrenoCard({
    required this.terreno,
    required this.campanas,
    required this.resumenes,
    required this.m2PorTopo,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = terreno;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
                child: Icon(t.esAlquilado ? Icons.handshake_rounded : Icons.home_rounded, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.nombre, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      [
                        t.unidad == 'hectarea'
                            ? t.areaDisplay
                            : '${t.areaDisplay} (≈ ${aHectareas(t.area, t.unidad, m2PorTopo).toStringAsFixed(2)} ha)',
                        t.esAlquilado ? 'Alquilado' : 'Propio',
                        if (t.referencia != null) t.referencia!,
                      ].join(' · '),
                      style: text.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (t.tieneUbicacion)
                GlassCircleButton(icon: Icons.map_outlined, tooltip: 'Ver en el mapa', onPressed: () => abrirEnMapa(t.latitud!, t.longitud!)),
              const SizedBox(width: 6),
              GlassCircleButton(icon: Icons.edit_outlined, tooltip: 'Editar', onPressed: onEditar),
            ],
          ),
          const SizedBox(height: 12),
          if (campanas.isEmpty)
            Text('Sin campañas todavía', style: text.bodySmall)
          else
            for (final c in campanas)
              _CampanaFila(campana: c, resumen: resumenes[c.id], hectareas: aHectareas(c.extension, c.tipoExtension, m2PorTopo)),
        ],
      ),
    );
  }
}

/// Resultado de una campaña del terreno: utilidad y utilidad por unidad de área.
class _CampanaFila extends StatelessWidget {
  final Campana campana;
  final CampanaResumen? resumen;

  /// Área sembrada en hectáreas: así se comparan terrenos en topos y en ha.
  final double hectareas;

  const _CampanaFila({required this.campana, required this.resumen, required this.hectareas});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final utilidad = resumen?.utilidad ?? 0;
    final sinVentas = (resumen?.ingresos ?? 0) == 0;
    final porArea = hectareas > 0 ? utilidad / hectareas : null;
    final color = sinVentas ? AppColors.textMuted : (utilidad < 0 ? AppColors.expense : AppColors.positive);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Text(cropEmoji(campana.cultivo), style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(campana.nombre, style: text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  campana.isClosed ? 'Cerrada' : (sinVentas ? 'En curso · sin ventas' : 'En curso'),
                  style: text.labelSmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${utilidad < 0 ? '-' : ''}${formatSoles(utilidad.abs())}', style: AppTheme.display(fontSize: 14, color: color)),
              if (porArea != null && !sinVentas)
                Text('${porArea < 0 ? '-' : ''}${formatSoles(porArea.abs())} / ha', style: text.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// Crear o editar un terreno. La unidad se elige al crearlo y luego queda fija.
class _TerrenoSheet extends ConsumerStatefulWidget {
  final Terreno? terreno;

  const _TerrenoSheet({this.terreno});

  @override
  ConsumerState<_TerrenoSheet> createState() => _TerrenoSheetState();
}

class _TerrenoSheetState extends ConsumerState<_TerrenoSheet> {
  late final _nombreCtrl = TextEditingController(text: widget.terreno?.nombre);
  late final _areaCtrl = TextEditingController(
    text: widget.terreno == null ? '' : widget.terreno!.area.toString().replaceFirst(RegExp(r'\.0$'), ''),
  );
  late final _referenciaCtrl = TextEditingController(text: widget.terreno?.referencia);
  late final _notasCtrl = TextEditingController(text: widget.terreno?.notas);
  late String _tenencia = widget.terreno?.tenencia ?? 'propio';
  late String _unidad = widget.terreno?.unidad ?? 'hectarea';
  late double? _lat = widget.terreno?.latitud;
  late double? _lng = widget.terreno?.longitud;
  double? _precision;
  bool _buscando = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _areaCtrl, _referenciaCtrl, _notasCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _opcional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _marcar() async {
    setState(() => _buscando = true);
    final r = await obtenerUbicacionActual();
    if (!mounted) return;
    setState(() {
      _buscando = false;
      if (r.posicion != null) {
        _lat = r.posicion!.latitude;
        _lng = r.posicion!.longitude;
        _precision = r.posicion!.accuracy;
      }
    });
    if (r.error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error!)));
  }

  Future<void> _guardar() async {
    final messenger = ScaffoldMessenger.of(context);
    final area = AmountInput.parse(_areaCtrl);
    if (_nombreCtrl.text.trim().isEmpty || area <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Escribe el nombre y el área del terreno')));
      return;
    }
    setState(() => _saving = true);
    final ds = ref.read(terrenoLocalDatasourceProvider);
    final t = widget.terreno;
    if (t == null) {
      await ds.insertTerreno(
        userId: kLocalUserId,
        nombre: _nombreCtrl.text.trim(),
        tenencia: _tenencia,
        area: area,
        unidad: _unidad,
        latitud: _lat,
        longitud: _lng,
        referencia: _opcional(_referenciaCtrl),
        notas: _opcional(_notasCtrl),
      );
    } else {
      await ds.updateTerreno(
        t.id,
        nombre: _nombreCtrl.text.trim(),
        tenencia: _tenencia,
        area: area,
        latitud: _lat,
        longitud: _lng,
        referencia: _opcional(_referenciaCtrl),
        notas: _opcional(_notasCtrl),
      );
    }
    ref.invalidate(terrenosProvider);
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(t == null ? 'Terreno creado' : 'Terreno actualizado')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final nuevo = widget.terreno == null;
    return RecordSheetScaffold(
      title: nuevo ? 'Nuevo terreno' : 'Editar terreno',
      subtitle: nuevo ? 'Donde siembras' : widget.terreno!.nombre,
      saveBar: RecordSaveBar(label: nuevo ? 'Crear terreno' : 'Guardar cambios', saving: _saving, onSave: _guardar),
      children: [
        const StepTitle(number: 1, title: 'Nombre'),
        TextField(
          controller: _nombreCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej. La Pampa', prefixIcon: Icon(Icons.landscape_rounded)),
        ),
        const SizedBox(height: 22),
        const StepTitle(number: 2, title: '¿Es tuyo o alquilado?'),
        OptionTiles<String>(
          options: const [
            ('propio', 'Propio', Icons.home_rounded),
            ('alquilado', 'Alquilado', Icons.handshake_rounded),
          ],
          selected: _tenencia,
          onSelected: (v) => setState(() => _tenencia = v),
        ),
        const SizedBox(height: 22),
        const StepTitle(number: 3, title: 'Área'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _areaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: const InputDecoration(hintText: 'Área', prefixIcon: Icon(Icons.square_foot_rounded)),
              ),
            ),
            const SizedBox(width: 8),
            if (nuevo) ...[
              MiniChip(label: 'Hectáreas', large: true, selected: _unidad == 'hectarea', onTap: () => setState(() => _unidad = 'hectarea')),
              const SizedBox(width: 6),
              MiniChip(label: 'Topos', large: true, selected: _unidad == 'topo', onTap: () => setState(() => _unidad = 'topo')),
            ] else
              Text(_unidad == 'hectarea' ? 'hectáreas' : 'topos', style: text.titleSmall),
          ],
        ),
        if (!nuevo)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text('La unidad no cambia, para poder comparar campañas.', style: text.bodySmall),
          ),
        const SizedBox(height: 22),
        const StepTitle(number: 4, title: 'Ubicación'),
        UbicacionCard(lat: _lat, lng: _lng, precision: _precision, buscando: _buscando, onMarcar: _marcar),
        const SizedBox(height: 10),
        TextField(
          controller: _referenciaCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Referencia. Ej. Sección D, junto al canal', prefixIcon: Icon(Icons.signpost_outlined)),
        ),
        const SizedBox(height: 22),
        const StepTitle(number: 5, title: 'Notas del suelo (opcional)'),
        TextField(
          controller: _notasCtrl,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej. Suelo arenoso, se encharca en la parte baja'),
        ),
      ],
    );
  }
}
