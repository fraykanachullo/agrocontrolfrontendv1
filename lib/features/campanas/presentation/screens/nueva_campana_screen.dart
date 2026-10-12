import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/ubicacion.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../../cuaderno/presentation/widgets/expense_sheet.dart' show suggestedStage;
import '../../../terrenos/domain/terreno.dart';
import '../../data/repositories/campana_repository_impl.dart' show kLocalUserId;
import '../campaign_display.dart';

/// Nueva campaña (RF-01): un terreno + un cultivo. La fecha de siembra no se
/// pide aquí: se marca en el cuaderno con la labor de siembra.

const _cultivos = ['Tomate', 'Cebolla', 'Vainita', 'Ajo', 'Papa', 'Maíz'];
const _otroCultivo = 'Otro';
const _alquilerCategoria = 'Alquiler de terreno';

class NuevaCampanaScreen extends ConsumerStatefulWidget {
  const NuevaCampanaScreen({super.key});

  @override
  ConsumerState<NuevaCampanaScreen> createState() => _NuevaCampanaScreenState();
}

class _NuevaCampanaScreenState extends ConsumerState<NuevaCampanaScreen> {
  // Terreno: uno existente o uno nuevo (id null).
  int? _terrenoId;
  bool _terrenoNuevo = false;
  final _terrenoNombreCtrl = TextEditingController();
  final _terrenoAreaCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  String _tenencia = 'propio';
  String _unidad = 'hectarea';
  double? _lat;
  double? _lng;
  double? _precision;
  bool _buscandoGps = false;

  // Cultivo y campaña.
  String? _cultivo;
  final _otroCultivoCtrl = TextEditingController();
  final _variedadCtrl = TextEditingController();
  final _areaSembradaCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  bool _nombreEditado = false;
  DateTime _inicio = DateTime.now();

  // Alquiler de esta campaña (solo terreno alquilado).
  final _alquilerCtrl = TextEditingController();
  bool _alquilerPagado = true;

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _terrenoNombreCtrl,
      _terrenoAreaCtrl,
      _referenciaCtrl,
      _otroCultivoCtrl,
      _variedadCtrl,
      _areaSembradaCtrl,
      _nombreCtrl,
      _alquilerCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static double _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  String _fmtArea(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Terreno? _terrenoElegido(List<Terreno> terrenos) =>
      _terrenoNuevo ? null : terrenos.where((t) => t.id == _terrenoId).firstOrNull;

  String get _cultivoFinal => _cultivo == _otroCultivo ? _otroCultivoCtrl.text.trim() : (_cultivo ?? '');

  // Datos efectivos del terreno, sea elegido o nuevo.
  String _terrenoNombre(Terreno? t) => t?.nombre ?? _terrenoNombreCtrl.text.trim();
  double _terrenoArea(Terreno? t) => t?.area ?? _num(_terrenoAreaCtrl);
  String _terrenoUnidad(Terreno? t) => t?.unidad ?? _unidad;
  bool _esAlquilado(Terreno? t) => (t?.tenencia ?? _tenencia) == 'alquilado';
  String _unidadCorta(String unidad, double area) => unidad == 'hectarea' ? 'ha' : (area == 1 ? 'topo' : 'topos');

  double _areaSembrada(Terreno? t) {
    final escrita = _num(_areaSembradaCtrl);
    return escrita > 0 ? escrita : _terrenoArea(t);
  }

  String _nombreSugerido(Terreno? t) {
    final partes = [
      if (_cultivoFinal.isNotEmpty) _cultivoFinal,
      if (_terrenoNombre(t).isNotEmpty) _terrenoNombre(t),
    ];
    return partes.isEmpty ? '' : '${partes.join(' · ')} ${_inicio.year}';
  }

  /// Mantiene el nombre sugerido mientras el usuario no lo haya escrito.
  void _refrescar(Terreno? t) {
    if (!_nombreEditado) _nombreCtrl.text = _nombreSugerido(t);
    setState(() {});
  }

  Future<void> _marcarUbicacion() async {
    setState(() => _buscandoGps = true);
    final r = await obtenerUbicacionActual();
    if (!mounted) return;
    setState(() {
      _buscandoGps = false;
      if (r.posicion != null) {
        _lat = r.posicion!.latitude;
        _lng = r.posicion!.longitude;
        _precision = r.posicion!.accuracy;
      }
    });
    if (r.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error!)));
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _elegirInicio() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _inicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null) {
      _inicio = picked;
      _refrescar(_terrenoElegido(ref.read(terrenosProvider).valueOrNull ?? const []));
    }
  }

  String? _validar(Terreno? t) {
    if (!_terrenoNuevo && t == null) return 'Elige el terreno o crea uno nuevo';
    if (_terrenoNuevo) {
      if (_terrenoNombreCtrl.text.trim().isEmpty) return 'Ponle un nombre al terreno';
      if (_num(_terrenoAreaCtrl) <= 0) return 'Escribe el área del terreno';
    }
    if (_cultivoFinal.isEmpty) return 'Elige qué vas a sembrar';
    if (_areaSembrada(t) > _terrenoArea(t)) return 'El área a sembrar no puede ser mayor que el terreno';
    if (_nombreCtrl.text.trim().isEmpty) return 'Ponle un nombre a la campaña';
    return null;
  }

  Future<void> _guardar(Terreno? elegido) async {
    final error = _validar(elegido);
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _saving = true);
    try {
      final terreno = elegido ??
          await ref.read(terrenoLocalDatasourceProvider).insertTerreno(
                userId: kLocalUserId,
                nombre: _terrenoNombreCtrl.text.trim(),
                tenencia: _tenencia,
                area: _num(_terrenoAreaCtrl),
                unidad: _unidad,
                latitud: _lat,
                longitud: _lng,
                referencia: _referenciaCtrl.text.trim().isEmpty ? null : _referenciaCtrl.text.trim(),
              );

      final campana = await ref.read(campanaListProvider.notifier).createCampana(
            nombre: _nombreCtrl.text.trim(),
            cultivo: _cultivoFinal,
            extension: _areaSembrada(terreno),
            tipoExtension: terreno.unidad,
            fechaInicio: _inicio,
            latitud: terreno.latitud,
            longitud: terreno.longitud,
            terrenoId: terreno.id,
            variedad: _variedadCtrl.text.trim().isEmpty ? null : _variedadCtrl.text.trim(),
          );
      if (campana == null) {
        messenger.showSnackBar(SnackBar(content: Text(ref.read(campanaListProvider).error ?? 'No se pudo crear la campaña')));
        if (mounted) setState(() => _saving = false);
        return;
      }

      final alquiler = AmountInput.parse(_alquilerCtrl);
      if (terreno.esAlquilado && alquiler > 0) {
        final now = DateTime.now();
        await ref.read(cuadernoProvider.notifier).addTransaccion(
              campana.id,
              tipo: 'gasto',
              categoria: _alquilerCategoria,
              monto: alquiler,
              descripcion: 'Alquiler de terreno · ${terreno.nombre}',
              fecha: DateTime(_inicio.year, _inicio.month, _inicio.day, now.hour, now.minute).toIso8601String(),
              estadoPago: _alquilerPagado ? 'pagado' : 'por_pagar',
              etapa: suggestedStage(_alquilerCategoria),
            );
      }

      ref.invalidate(terrenosProvider);
      ref.read(activeCampanaIdProvider.notifier).state = campana.id;
      HapticFeedback.mediumImpact();
      messenger.showSnackBar(SnackBar(content: Text('${campana.nombre} creada')));
      if (mounted) context.go('/c/${campana.id}/inicio');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final terrenos = ref.watch(terrenosProvider).valueOrNull ?? const <Terreno>[];
    // Sin terrenos guardados, se crea uno nuevo directamente.
    if (terrenos.isEmpty && !_terrenoNuevo && ref.watch(terrenosProvider).hasValue) _terrenoNuevo = true;
    final elegido = _terrenoElegido(terrenos);
    final hayTerreno = _terrenoNuevo || elegido != null;
    final unidad = _terrenoUnidad(elegido);
    final areaTerreno = _terrenoArea(elegido);
    var paso = 1;

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
                  Text('Nueva campaña', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text('Una campaña es un cultivo en un terreno.', style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 18),

            // 1. Terreno
            StepTitle(number: paso++, title: '¿Dónde vas a sembrar?'),
            for (final t in terrenos) ...[
              _TerrenoTile(
                terreno: t,
                selected: !_terrenoNuevo && _terrenoId == t.id,
                onTap: () {
                  _terrenoNuevo = false;
                  _terrenoId = t.id;
                  _areaSembradaCtrl.clear();
                  _refrescar(t);
                },
              ),
              const SizedBox(height: 8),
            ],
            if (terrenos.isNotEmpty)
              _NuevoTerrenoTile(
                selected: _terrenoNuevo,
                onTap: () {
                  _terrenoNuevo = true;
                  _terrenoId = null;
                  _areaSembradaCtrl.clear();
                  _refrescar(null);
                },
              ),
            if (_terrenoNuevo) ...[
              if (terrenos.isNotEmpty) const SizedBox(height: 10),
              _nuevoTerrenoForm(text),
            ],
            const SizedBox(height: 22),

            // 2. Cultivo
            StepTitle(number: paso++, title: '¿Qué vas a sembrar?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in [..._cultivos, _otroCultivo])
                  SelectPill(
                    icon: Icons.eco_rounded,
                    label: c == _otroCultivo ? c : '${cropEmoji(c)} $c',
                    selected: _cultivo == c,
                    onTap: () {
                      _cultivo = c;
                      _refrescar(elegido);
                    },
                  ),
              ],
            ),
            if (_cultivo == _otroCultivo) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _otroCultivoCtrl,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _refrescar(elegido),
                decoration: const InputDecoration(hintText: '¿Qué cultivo? Ej. Zanahoria'),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _variedadCtrl,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Variedad (opcional)', prefixIcon: Icon(Icons.spa_outlined)),
            ),
            const SizedBox(height: 22),

            // 3. Área a sembrar
            if (hayTerreno) ...[
              StepTitle(number: paso++, title: '¿Cuánto vas a sembrar?'),
              TextField(
                controller: _areaSembradaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: areaTerreno > 0 ? '${_fmtArea(areaTerreno)} (todo el terreno)' : '0',
                  prefixIcon: const Icon(Icons.square_foot_rounded),
                  suffixText: _unidadCorta(unidad, _areaSembrada(elegido)),
                ),
              ),
              if (areaTerreno > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'El terreno tiene ${_fmtArea(areaTerreno)} ${_unidadCorta(unidad, areaTerreno)}. Déjalo vacío si siembras todo.',
                    style: text.bodySmall,
                  ),
                ),
              const SizedBox(height: 22),
            ],

            // 4. Inicio
            StepTitle(number: paso++, title: '¿Cuándo empieza?'),
            GlassCard(
              radius: 18,
              onTap: _elegirInicio,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.event_rounded, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Inicio de la campaña', style: text.labelSmall),
                        Text(DateFormat("EEEE d 'de' MMMM y", 'es').format(_inicio), style: text.titleSmall),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_calendar_rounded, size: 20, color: AppColors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Aviso(
              icon: Icons.spa_rounded,
              text: 'La fecha de siembra no se pide aquí. Cuando siembres, registra la labor «Siembra» en el Cuaderno '
                  'y la campaña pasa a la etapa de crecimiento.',
            ),
            const SizedBox(height: 22),

            // 5. Alquiler (solo terreno alquilado)
            if (hayTerreno && _esAlquilado(elegido)) ...[
              StepTitle(number: paso++, title: 'Alquiler para esta campaña (opcional)'),
              AmountInput(
                controller: _alquilerCtrl,
                onChanged: () => setState(() {}),
                caption: 'PAGO POR EL TERRENO',
                quickAmounts: const [100, 500, 1000, 2000],
              ),
              const SizedBox(height: 10),
              OptionTiles<bool>(
                options: const [
                  (true, 'Ya pagué', Icons.check_circle_rounded),
                  (false, 'Debo', Icons.pending_actions_rounded),
                ],
                selected: _alquilerPagado,
                onSelected: (v) => setState(() => _alquilerPagado = v),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text('Se guarda como gasto de la campaña.', style: text.bodySmall),
              ),
              const SizedBox(height: 22),
            ],

            // 6. Nombre
            StepTitle(number: paso++, title: 'Nombre de la campaña'),
            TextField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                _nombreEditado = _nombreCtrl.text.trim().isNotEmpty;
                setState(() {});
              },
              decoration: const InputDecoration(hintText: 'Ej. Tomate · La Pampa 2026', prefixIcon: Icon(Icons.edit_rounded)),
            ),
            const SizedBox(height: 18),
            RecordSummary(text: _resumen(elegido)),
          ],
        ),
        bottomNavigationBar: RecordSaveBar(label: 'Crear campaña', saving: _saving, onSave: () => _guardar(elegido)),
      ),
    );
  }

  String _resumen(Terreno? t) {
    final cultivo = _cultivoFinal.isEmpty ? 'Sin cultivo' : _cultivoFinal;
    final variedad = _variedadCtrl.text.trim();
    final terreno = _terrenoNombre(t);
    final area = _areaSembrada(t);
    final unidad = _unidadCorta(_terrenoUnidad(t), area);
    final b = StringBuffer(variedad.isEmpty ? cultivo : '$cultivo ($variedad)');
    if (terreno.isNotEmpty) b.write(' en $terreno');
    if (area > 0) b.write(', ${_fmtArea(area)} $unidad');
    b.write('. Empieza el ${DateFormat("d 'de' MMMM", 'es').format(_inicio)}.');
    final alquiler = AmountInput.parse(_alquilerCtrl);
    if (_esAlquilado(t) && alquiler > 0) {
      b.write(' Alquiler ${formatSoles(alquiler)} ${_alquilerPagado ? 'pagado' : 'por pagar'}.');
    }
    return b.toString();
  }

  Widget _nuevoTerrenoForm(TextTheme text) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _terrenoNombreCtrl,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => _refrescar(null),
            decoration: const InputDecoration(hintText: 'Nombre del terreno. Ej. La Pampa', prefixIcon: Icon(Icons.landscape_rounded)),
          ),
          const SizedBox(height: 12),
          OptionTiles<String>(
            options: const [
              ('propio', 'Propio', Icons.home_rounded),
              ('alquilado', 'Alquilado', Icons.handshake_rounded),
            ],
            selected: _tenencia,
            onSelected: (v) => setState(() => _tenencia = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _terrenoAreaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Área', prefixIcon: Icon(Icons.square_foot_rounded)),
                ),
              ),
              const SizedBox(width: 8),
              MiniChip(label: 'Hectáreas', large: true, selected: _unidad == 'hectarea', onTap: () => setState(() => _unidad = 'hectarea')),
              const SizedBox(width: 6),
              MiniChip(label: 'Topos', large: true, selected: _unidad == 'topo', onTap: () => setState(() => _unidad = 'topo')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text('La unidad queda fija para comparar campañas.', style: text.bodySmall),
          ),
          const SizedBox(height: 14),
          _UbicacionCard(
            lat: _lat,
            lng: _lng,
            precision: _precision,
            buscando: _buscandoGps,
            onMarcar: _marcarUbicacion,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _referenciaCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Referencia (opcional). Ej. Sección D, junto al canal', prefixIcon: Icon(Icons.signpost_outlined)),
          ),
        ],
      ),
    );
  }
}

class _TerrenoTile extends StatelessWidget {
  final Terreno terreno;
  final bool selected;
  final VoidCallback onTap;

  const _TerrenoTile({required this.terreno, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final detalle = [
      terreno.areaDisplay,
      terreno.esAlquilado ? 'Alquilado' : 'Propio',
      if (terreno.tieneUbicacion) 'Con ubicación',
    ].join(' · ');
    return _SelectableCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          _IconBox(icon: terreno.esAlquilado ? Icons.handshake_rounded : Icons.home_rounded, selected: selected),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(terreno.nombre, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(detalle, style: text.bodySmall),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: selected ? AppColors.accent : AppColors.textSubtle,
          ),
        ],
      ),
    );
  }
}

class _NuevoTerrenoTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _NuevoTerrenoTile({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _SelectableCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          _IconBox(icon: Icons.add_location_alt_rounded, selected: selected),
          const SizedBox(width: 12),
          Expanded(child: Text('Nuevo terreno', style: Theme.of(context).textTheme.titleSmall)),
          Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: selected ? AppColors.accent : AppColors.textSubtle,
          ),
        ],
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _SelectableCard({required this.selected, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent.withValues(alpha: 0.10) : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? AppColors.accent : AppColors.cardBorder),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _IconBox({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: selected ? AppColors.accent.withValues(alpha: 0.18) : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.accent),
    );
  }
}

/// Ubicación del terreno con el GPS del teléfono (sin mapas inventados:
/// solo las coordenadas reales y un botón para abrirlas en Google Maps).
class _UbicacionCard extends StatelessWidget {
  final double? lat;
  final double? lng;
  final double? precision;
  final bool buscando;
  final VoidCallback onMarcar;

  const _UbicacionCard({required this.lat, required this.lng, required this.precision, required this.buscando, required this.onMarcar});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final marcada = lat != null && lng != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.track.withValues(alpha: AppColors.palette.isDark ? 0.35 : 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(marcada ? Icons.location_on_rounded : Icons.location_searching_rounded, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(marcada ? 'Ubicación marcada' : 'Ubicación del terreno', style: text.titleSmall),
                    Text(
                      marcada
                          ? '${formatoCoordenadas(lat!, lng!)}${precision == null ? '' : ' · ±${precision!.round()} m'}'
                          : 'Párate en el terreno. Funciona sin internet.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AgroActionButton(
                  label: buscando ? 'Buscando señal…' : (marcada ? 'Volver a marcar' : 'Marcar ubicación aquí'),
                  icon: Icons.my_location_rounded,
                  height: 46,
                  onPressed: buscando ? () {} : onMarcar,
                ),
              ),
              if (marcada) ...[
                const SizedBox(width: 8),
                GlassCircleButton(icon: Icons.map_outlined, tooltip: 'Ver en el mapa', size: 46, onPressed: () => abrirEnMapa(lat!, lng!)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Aviso({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
