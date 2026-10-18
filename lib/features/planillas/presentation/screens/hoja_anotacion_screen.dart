import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../../cuaderno/data/datasources/evidencia_local_datasource.dart';
import '../../domain/entities/planilla.dart';
import '../../domain/entities/plantilla_cultivo.dart';

const _mercadosSugeridos = ['Lima', 'Arequipa', 'Santa Anita', 'Río Seco'];

/// Hoja de anotación de un despacho (RF-COS-06 a RF-COS-12): cuadrícula
/// filas del camión × calidades, con totales automáticos.
class HojaAnotacionScreen extends ConsumerStatefulWidget {
  final int campanaId;
  final String cultivo;
  final int numeroHoja;
  final Planilla? planilla;

  /// Calidades, filas y envase del cultivo para una hoja nueva.
  final PlantillaCultivo plantilla;

  const HojaAnotacionScreen({
    super.key,
    required this.campanaId,
    required this.cultivo,
    required this.numeroHoja,
    required this.plantilla,
    this.planilla,
  });

  @override
  ConsumerState<HojaAnotacionScreen> createState() => _HojaAnotacionScreenState();
}

class _HojaAnotacionScreenState extends ConsumerState<HojaAnotacionScreen> {
  late List<Calidad> _calidades;
  late List<List<int>> _celdas; // [fila][calidad]
  final List<(List<Calidad>, List<List<int>>)> _historial = [];

  DateTime _fecha = DateTime.now();
  String _destino = '';
  String _chofer = '';
  String _placa = '';
  String _comisionista = '';
  String _notas = '';
  String? _foto;

  (int fila, int col)? _sel;
  bool _escribiendo = false; // el primer dígito reemplaza el valor de la celda
  bool _dirty = false;
  bool _saving = false;

  bool get _enviada => widget.planilla?.estado == 'enviada';
  String get _envase => widget.plantilla.envase;

  @override
  void initState() {
    super.initState();
    final p = widget.planilla;
    final payload = p?.payload ?? const <String, dynamic>{};

    final guardadas = (payload['calidades'] as List<dynamic>?)?.map((c) => (codigo: c['codigo'] as String, nombre: c['nombre'] as String)).toList();
    _calidades = guardadas ?? List.of(widget.plantilla.calidades);

    final filas = (payload['filas'] as List<dynamic>?) ?? const [];
    _celdas = filas.isEmpty
        ? List.generate(widget.plantilla.filas, (_) => List.filled(_calidades.length, 0))
        : [
            for (final f in filas) [for (final c in _calidades) (((f as Map)['calidades'] as Map?)?[c.codigo] as num?)?.toInt() ?? 0],
          ];

    if (p != null) {
      _fecha = DateTime.tryParse(p.fecha) ?? DateTime.now();
      _destino = p.mercado ?? '';
      _chofer = p.transportista ?? '';
      _placa = payload['placa'] as String? ?? '';
      _comisionista = payload['comisionista'] as String? ?? '';
      _notas = p.notas ?? '';
      _foto = payload['foto'] as String?;
    }
  }

  // ── Cálculos ──

  int _totalFila(int f) => _celdas[f].fold(0, (s, v) => s + v);
  int _totalCol(int c) => _celdas.fold(0, (s, fila) => s + fila[c]);
  int get _total => _celdas.fold(0, (s, fila) => s + fila.fold(0, (a, v) => a + v));

  // ── Edición ──

  void _snapshot() {
    _historial.add((List.of(_calidades), [for (final f in _celdas) List.of(f)]));
    if (_historial.length > 50) _historial.removeAt(0);
    _dirty = true;
  }

  void _deshacer() {
    if (_historial.isEmpty) return;
    final (cal, celdas) = _historial.removeLast();
    setState(() {
      _calidades = cal;
      _celdas = celdas;
      _sel = null;
    });
  }

  void _seleccionar(int fila, int col) {
    if (_enviada) return;
    HapticFeedback.selectionClick();
    setState(() {
      _sel = (fila, col);
      _escribiendo = false;
    });
  }

  void _setCelda(int value) {
    final sel = _sel;
    if (sel == null) return;
    _snapshot();
    setState(() => _celdas[sel.$1][sel.$2] = value.clamp(0, 9999));
  }

  void _digito(int d) {
    final sel = _sel;
    if (sel == null) return;
    final actual = _celdas[sel.$1][sel.$2];
    final nuevo = _escribiendo ? int.parse('$actual$d') : d;
    if (nuevo > 9999) return;
    _setCelda(nuevo);
    _escribiendo = true;
  }

  void _borrarDigito() {
    final sel = _sel;
    if (sel == null) return;
    final s = '${_celdas[sel.$1][sel.$2]}';
    _setCelda(s.length <= 1 ? 0 : int.parse(s.substring(0, s.length - 1)));
    _escribiendo = true;
  }

  /// Avanza a la siguiente celda: derecha y luego a la fila de abajo.
  void _siguiente() {
    final sel = _sel;
    if (sel == null) return;
    var (f, c) = sel;
    if (c < _calidades.length - 1) {
      c++;
    } else if (f < _celdas.length - 1) {
      f++;
      c = 0;
    } else {
      setState(() => _sel = null);
      return;
    }
    _seleccionar(f, c);
  }

  void _agregarFila() {
    _snapshot();
    setState(() => _celdas.add(List.filled(_calidades.length, 0)));
  }

  Future<void> _opcionesFila(int f) async {
    if (_enviada) return;
    final borrar = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: Text('Eliminar fila ${f + 1}', style: TextStyle(color: AppColors.error)),
              subtitle: Text('${_totalFila(f)} bultos'),
              onTap: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    if (borrar != true) return;
    _snapshot();
    setState(() {
      _celdas.removeAt(f);
      _sel = null;
    });
  }

  Future<void> _agregarCalidad() async {
    final nueva = await _dialogoCalidad(titulo: 'Nueva calidad');
    if (nueva == null || _calidades.any((c) => c.codigo == nueva.codigo)) return;
    _snapshot();
    setState(() {
      _calidades.add(nueva);
      for (final fila in _celdas) {
        fila.add(0);
      }
    });
  }

  /// Toque largo sobre una columna: renombrar, mover o quitar la calidad.
  Future<void> _opcionesCalidad(int c) async {
    if (_enviada) return;
    final calidad = _calidades[c];
    final accion = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('${calidad.codigo} · ${calidad.nombre}', style: Theme.of(ctx).textTheme.titleSmall),
              subtitle: Text('${_totalCol(c)} en esta columna'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Cambiar símbolo o nombre'),
              onTap: () => Navigator.of(ctx).pop('editar'),
            ),
            if (c > 0)
              ListTile(
                leading: const Icon(Icons.arrow_back_rounded),
                title: const Text('Mover a la izquierda'),
                onTap: () => Navigator.of(ctx).pop('izquierda'),
              ),
            if (c < _calidades.length - 1)
              ListTile(
                leading: const Icon(Icons.arrow_forward_rounded),
                title: const Text('Mover a la derecha'),
                onTap: () => Navigator.of(ctx).pop('derecha'),
              ),
            if (_calidades.length > 1)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: Text('Quitar columna', style: TextStyle(color: AppColors.error)),
                subtitle: _totalCol(c) > 0 ? Text('Se borran sus ${_totalCol(c)} anotadas') : null,
                onTap: () => Navigator.of(ctx).pop('quitar'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || accion == null) return;
    switch (accion) {
      case 'editar':
        final editada = await _dialogoCalidad(titulo: 'Editar calidad', inicial: calidad);
        if (editada == null || _calidades.indexed.any((e) => e.$1 != c && e.$2.codigo == editada.codigo)) return;
        _snapshot();
        setState(() => _calidades[c] = editada);
      case 'izquierda' || 'derecha':
        final d = accion == 'izquierda' ? c - 1 : c + 1;
        _snapshot();
        setState(() {
          _calidades.insert(d, _calidades.removeAt(c));
          for (final fila in _celdas) {
            fila.insert(d, fila.removeAt(c));
          }
          _sel = null;
        });
      case 'quitar':
        _snapshot();
        setState(() {
          _calidades.removeAt(c);
          for (final fila in _celdas) {
            fila.removeAt(c);
          }
          _sel = null;
        });
    }
  }

  /// Diálogo de símbolo y nombre de una calidad (nueva o editada).
  Future<Calidad?> _dialogoCalidad({required String titulo, Calidad? inicial}) =>
      showDialog<Calidad>(context: context, builder: (_) => _CalidadDialog(titulo: titulo, inicial: inicial));

  Future<void> _editarNotas() async {
    final valor = await showTextInputDialog(
      context,
      title: 'Notas de la hoja',
      initial: _notas,
      hint: 'Ej. 3 javas rotas en la fila 7, el camión salió tarde',
      maxLines: 6,
    );
    if (valor == null) return;
    setState(() {
      _notas = valor;
      _dirty = true;
    });
  }

  Future<void> _editarDato(String titulo, String actual, ValueChanged<String> onSave, {List<String> sugerencias = const []}) async {
    final valor = await showTextInputDialog(
      context,
      title: titulo,
      initial: actual,
      capitalization: TextCapitalization.words,
      suggestions: sugerencias,
    );
    if (valor == null) return;
    setState(() {
      onSave(valor);
      _dirty = true;
    });
  }

  Future<void> _tomarFoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 75, maxWidth: 1600);
    if (picked == null) return;
    final saved = await EvidenciaLocalDatasource().copyToEvidencias(picked.path);
    setState(() {
      _foto = saved.path;
      _dirty = true;
    });
  }

  // ── Guardado ──

  Map<String, dynamic> _payload({int? despachoId}) => {
    // Enlace al despacho creado al cerrar la hoja (para su pantalla de detalle).
    'despacho_id': ?(despachoId ?? widget.planilla?.payload['despacho_id'] as int?),
    'numero_hoja': widget.planilla?.payload['numero_hoja'] ?? widget.numeroHoja,
    'placa': _placa.toUpperCase(),
    'comisionista': _comisionista,
    'envase': widget.plantilla.envase,
    'foto': ?_foto,
    'calidades': [
      for (final c in _calidades) {'codigo': c.codigo, 'nombre': c.nombre},
    ],
    'filas': [
      for (var f = 0; f < _celdas.length; f++)
        {
          'fila': f + 1,
          'calidades': {for (var c = 0; c < _calidades.length; c++) _calidades[c].codigo: _celdas[f][c]},
          'total': _totalFila(f),
        },
    ],
    'columnas': {for (var c = 0; c < _calidades.length; c++) _calidades[c].codigo: _totalCol(c)},
    'gran_total': _total,
  };

  Future<void> _persistir({String? estado, int? despachoId}) async {
    final now = DateTime.now().toIso8601String();
    final existing = widget.planilla;
    final planilla = Planilla(
      id: existing?.id,
      uuidLocal: existing?.uuidLocal ?? const Uuid().v4(),
      campanaId: widget.campanaId,
      cultivo: widget.cultivo,
      tipo: 'matricial',
      fecha: DateFormat('yyyy-MM-dd').format(_fecha),
      mercado: _destino,
      transportista: _chofer,
      notas: _notas.isEmpty ? null : _notas,
      totalUnidades: _total,
      estado: estado ?? existing?.estado ?? 'guardada',
      payload: _payload(despachoId: despachoId),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final notifier = ref.read(planillasProvider.notifier);
    if (existing?.id != null) {
      await notifier.updatePlanilla(planilla);
    } else {
      await notifier.addPlanilla(planilla);
    }
    _dirty = false;
  }

  Future<bool> _salir() async {
    if (_dirty && !_enviada && _total > 0) await _persistir();
    return true;
  }

  /// Cierra la hoja: crea el despacho "por liquidar" con el detalle por
  /// fila y calidad (RF-COS-10) y deja la hoja como enviada.
  Future<void> _cerrarYEnviar() async {
    if (_total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La hoja está vacía')));
      return;
    }
    if (_destino.isEmpty) {
      await _editarDato('¿A qué mercado va?', _destino, (v) => _destino = v, sugerencias: _mercadosSugeridos);
      if (_destino.isEmpty) return;
    }
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar hoja y enviar'),
        content: Text(
          '$_total ${_envase}s a $_destino.\n\n'
          '${[for (var c = 0; c < _calidades.length; c++)
            if (_totalCol(c) > 0) '${_calidades[c].codigo}: ${_totalCol(c)}'].join(' · ')}\n\n'
          'Se creará el despacho como "por liquidar".',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Revisar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Enviar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final despachoId = await ref
          .read(cosechasProvider.notifier)
          .addCosecha(
            widget.campanaId,
            tipoVenta: 'mercado',
            modoCosecha: 'matricial_filas',
            // Se liquida por java (precio × bultos), no por kilo.
            tipoCalculoVenta: 'por_unidad',
            unidadEmpaque: widget.plantilla.envase,
            cantidadUnidades: _total,
            totalBultos: _total,
            conductor: [_chofer, if (_placa.isNotEmpty) _placa.toUpperCase()].where((s) => s.isNotEmpty).join(' · '),
            mercadoDestino: _destino,
            fechaEnvio: DateTime(_fecha.year, _fecha.month, _fecha.day, DateTime.now().hour, DateTime.now().minute).toIso8601String(),
            // Por columna y luego por fila: así las calidades conservan su orden.
            detalles: [
              for (var c = 0; c < _calidades.length; c++)
                for (var f = 0; f < _celdas.length; f++)
                  if (_celdas[f][c] > 0)
                    {'categoria': _calidades[c].nombre, 'simbolo': _calidades[c].codigo, 'posicion_fila': f + 1, 'cantidad_bultos': _celdas[f][c]},
            ],
          );
      await _persistir(estado: 'enviada', despachoId: despachoId);
      ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
      HapticFeedback.mediumImpact();
      navigator.pop(true);
      messenger.showSnackBar(SnackBar(content: Text('Despacho de $_total ${_envase}s a $_destino registrado')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _compartir() {
    String pad(Object v, int w) => '$v'.padLeft(w);
    final cols = _calidades.map((c) => pad(c.codigo, 3)).join(' ');
    final b = StringBuffer()
      ..writeln('📋 *Hoja ${widget.numeroHoja} · ${DateFormat('EEEE d MMM', 'es').format(_fecha)}*')
      ..writeln(
        [
          if (_destino.isNotEmpty) 'Destino: $_destino',
          if (_chofer.isNotEmpty) 'Chofer: $_chofer',
          if (_placa.isNotEmpty) 'Placa: ${_placa.toUpperCase()}',
        ].join(' · '),
      )
      ..writeln('```')
      ..writeln('Fila $cols  Tot');
    for (var f = 0; f < _celdas.length; f++) {
      if (_totalFila(f) == 0) continue;
      final vals = _celdas[f].map((v) => pad(v == 0 ? '·' : v, 3)).join(' ');
      b.writeln('${pad(f + 1, 4)} $vals ${pad(_totalFila(f), 4)}');
    }
    b
      ..writeln('Tot. ${[for (var c = 0; c < _calidades.length; c++) pad(_totalCol(c), 3)].join(' ')} ${pad(_total, 4)}')
      ..writeln('```')
      ..write('*Total: $_total ${_envase}s*');
    return SharePlus.instance.share(ShareParams(text: b.toString()));
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _salir()) navigator.pop(true);
      },
      child: AgroBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _appBar(),
          body: GestureDetector(
            onTap: () => setState(() => _sel = null),
            behavior: HitTestBehavior.translucent,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _contexto(),
                if (_enviada) ...[const SizedBox(height: 12), _avisoEnviada()],
                const SizedBox(height: 14),
                if (!_enviada) _barraAcciones(),
                const SizedBox(height: 10),
                _matriz(),
                const SizedBox(height: 14),
                PhotoPickerTile(
                  photo: _foto == null ? null : File(_foto!),
                  title: 'Foto de la carga',
                  hint: 'Precinto, estiba o la hoja de papel',
                  onPick: (_) => _tomarFoto(),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _sel != null ? _teclado() : _pie(),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    final text = Theme.of(context).textTheme;
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              GlassCircleButton(icon: Icons.arrow_back_rounded, tooltip: 'Volver', onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Hoja de anotación', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Hoja N.º ${widget.numeroHoja} · ${widget.cultivo}', style: text.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 5),
                    Text(
                      '${_celdas.length} filas',
                      style: text.labelSmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contexto() {
    final text = Theme.of(context).textTheme;
    final fecha = toBeginningOfSentenceCase(DateFormat('EEEE d MMM', 'es').format(_fecha));
    return GlassCard(
      highlight: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESPACHO · ${widget.cultivo.toUpperCase()}',
            style: text.labelSmall?.copyWith(color: AppColors.accent, letterSpacing: 1.2, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: _enviada
                ? null
                : () async {
                    final d = await showDatePicker(context: context, initialDate: _fecha, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (d != null) setState(() => _fecha = d);
                  },
            child: Text('$fecha${_destino.isEmpty ? '' : ' · a $_destino'}', style: text.titleLarge),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Dato(
                  icon: Icons.storefront_outlined,
                  label: 'Destino',
                  value: _destino,
                  onTap: _enviada ? null : () => _editarDato('Mercado de destino', _destino, (v) => _destino = v, sugerencias: _mercadosSugeridos),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Dato(
                  icon: Icons.handshake_outlined,
                  label: 'Comisionista',
                  value: _comisionista,
                  onTap: _enviada ? null : () => _editarDato('Comisionista', _comisionista, (v) => _comisionista = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Dato(
                  icon: Icons.badge_outlined,
                  label: 'Chofer',
                  value: _chofer,
                  onTap: _enviada ? null : () => _editarDato('Chofer', _chofer, (v) => _chofer = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Dato(
                  icon: Icons.pin_outlined,
                  label: 'Placa',
                  value: _placa.toUpperCase(),
                  onTap: _enviada ? null : () => _editarDato('Placa del camión', _placa, (v) => _placa = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Dato(icon: Icons.sticky_note_2_outlined, label: 'Notas', value: _notas, onTap: _enviada ? null : _editarNotas),
        ],
      ),
    );
  }

  Widget _avisoEnviada() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.task_alt_rounded, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hoja enviada: el despacho ya está en Cosechas esperando su liquidación.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barraAcciones() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _BotonBarra(icon: Icons.add_rounded, label: 'Fila', onTap: _agregarFila),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BotonBarra(icon: Icons.view_column_outlined, label: 'Calidad', onTap: _agregarCalidad),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BotonBarra(icon: Icons.undo_rounded, label: 'Deshacer', onTap: _historial.isEmpty ? null : _deshacer),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Mantén presionada una calidad o el número de fila para editarla o quitarla.',
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _matriz() {
    final text = Theme.of(context).textTheme;
    const anchoFila = 40.0;
    const anchoTotal = 52.0;

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Las calidades reparten el ancho disponible (mínimo 44 por celda;
          // si no entran, la tabla se desliza a los lados).
          final libre = constraints.maxWidth - anchoFila - anchoTotal;
          final anchoCelda = (libre / _calidades.length).clamp(44.0, 80.0);
          final anchoTabla = anchoFila + anchoTotal + anchoCelda * _calidades.length;

          final tabla = SizedBox(
            width: anchoTabla,
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: anchoFila,
                      child: Text('Fila', textAlign: TextAlign.center, style: text.labelSmall),
                    ),
                    for (final (i, c) in _calidades.indexed)
                      GestureDetector(
                        onLongPress: () => _opcionesCalidad(i),
                        child: SizedBox(
                          width: anchoCelda,
                          child: Column(
                            children: [
                              Text(c.codigo, style: AppTheme.display(fontSize: 15, color: AppColors.accent)),
                              Text(c.nombre, style: text.labelSmall?.copyWith(fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(
                      width: anchoTotal,
                      child: Text('Total', textAlign: TextAlign.center, style: text.labelSmall),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (var f = 0; f < _celdas.length; f++) _filaWidget(f, anchoFila, anchoCelda, anchoTotal),
              ],
            ),
          );

          return anchoTabla > constraints.maxWidth ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: tabla) : tabla;
        },
      ),
    );
  }

  Widget _filaWidget(int f, double anchoFila, double anchoCelda, double anchoTotal) {
    // El total por fila es libre (depende del camión): solo ayuda a revisar el orden.
    final total = _totalFila(f);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: () => _opcionesFila(f),
            child: SizedBox(
              width: anchoFila,
              child: Text(
                (f + 1).toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: AppTheme.display(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          ),
          for (var c = 0; c < _calidades.length; c++)
            SizedBox(
              width: anchoCelda,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _Celda(valor: _celdas[f][c], seleccionada: _sel == (f, c), onTap: () => _seleccionar(f, c)),
              ),
            ),
          SizedBox(
            width: anchoTotal,
            child: Container(
              height: 40,
              margin: const EdgeInsets.only(left: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Text(total == 0 ? '–' : '$total', style: AppTheme.display(fontSize: 15, color: AppColors.text)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pie() {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.palette.navBackground,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _calidades.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${_calidades[c].codigo}: ', style: text.labelSmall),
                        TextSpan(
                          text: '${_totalCol(c)}',
                          style: AppTheme.display(fontSize: 13, color: AppColors.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL DE LA CARGA', style: text.labelSmall?.copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w700)),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$_total',
                            style: AppTheme.display(fontSize: 26, color: AppColors.accent),
                          ),
                          TextSpan(text: ' ${_envase}s', style: text.labelMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GlassCircleButton(icon: Icons.share_rounded, tooltip: 'Compartir por WhatsApp', size: 50, onPressed: _compartir),
              ],
            ),
            if (!_enviada) ...[
              const SizedBox(height: 10),
              AgroActionButton(
                label: _saving ? 'Enviando…' : 'Cerrar hoja y enviar despacho',
                icon: Icons.task_alt_rounded,
                primary: true,
                height: 54,
                onPressed: _saving ? () {} : _cerrarYEnviar,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Teclado numérico grande para llenar celdas sin el teclado del sistema.
  Widget _teclado() {
    final text = Theme.of(context).textTheme;
    final (f, c) = _sel!;
    Widget tecla(Widget child, VoidCallback onTap, {bool accent = false, int flex = 1}) => Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: accent ? AppColors.accent : AppColors.accentSoft,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: SizedBox(height: 52, child: Center(child: child)),
          ),
        ),
      ),
    );
    Widget numero(int d) => tecla(Text('$d', style: AppTheme.display(fontSize: 22, color: AppColors.text)), () => _digito(d));

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.palette.navBackground,
        border: Border(top: BorderSide(color: AppColors.cardBorderStrong)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Text('Fila ${f + 1} · ${_calidades[c].codigo} ${_calidades[c].nombre}', style: text.titleSmall),
                  const Spacer(),
                  Text('${_celdas[f][c]}', style: AppTheme.display(fontSize: 22, color: AppColors.accent)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                numero(1),
                numero(2),
                numero(3),
                tecla(Icon(Icons.backspace_outlined, color: AppColors.textMuted), _borrarDigito),
              ],
            ),
            Row(
              children: [
                numero(4),
                numero(5),
                numero(6),
                tecla(Text('−1', style: AppTheme.display(fontSize: 18, color: AppColors.text)), () {
                  _setCelda(_celdas[f][c] - 1);
                  _escribiendo = false;
                }),
              ],
            ),
            Row(
              children: [
                numero(7),
                numero(8),
                numero(9),
                tecla(Text('+1', style: AppTheme.display(fontSize: 18, color: AppColors.text)), () {
                  _setCelda(_celdas[f][c] + 1);
                  _escribiendo = false;
                }),
              ],
            ),
            Row(
              children: [
                tecla(Text('Listo', style: text.labelLarge), () => setState(() => _sel = null)),
                numero(0),
                tecla(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Siguiente',
                        style: text.labelLarge?.copyWith(color: AppColors.onAccent, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: AppColors.onAccent, size: 18),
                    ],
                  ),
                  _siguiente,
                  accent: true,
                  flex: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Piezas
// ═══════════════════════════════════════════════

class _Celda extends StatelessWidget {
  final int valor;
  final bool seleccionada;
  final VoidCallback onTap;

  const _Celda({required this.valor, required this.seleccionada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: seleccionada
              ? AppColors.accent.withValues(alpha: 0.22)
              : (valor > 0 ? AppColors.accentSoft : AppColors.track.withValues(alpha: AppColors.palette.isDark ? 0.25 : 0.45)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: seleccionada ? AppColors.accent : Colors.transparent, width: 1.5),
        ),
        child: Text(valor == 0 ? '' : '$valor', style: AppTheme.display(fontSize: 15, color: AppColors.text)),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _Dato({required this.icon, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.labelSmall?.copyWith(fontSize: 10)),
                    Text(
                      value.isEmpty ? 'Agregar' : value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(color: value.isEmpty ? AppColors.textSubtle : AppColors.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonBarra extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BotonBarra({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(label, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Símbolo y nombre de una calidad. Es dueño de sus controladores para no
/// usarlos ya liberados mientras se cierra.
class _CalidadDialog extends StatefulWidget {
  final String titulo;
  final Calidad? inicial;

  const _CalidadDialog({required this.titulo, this.inicial});

  @override
  State<_CalidadDialog> createState() => _CalidadDialogState();
}

class _CalidadDialogState extends State<_CalidadDialog> {
  late final _codigo = TextEditingController(text: widget.inicial?.codigo);
  late final _nombre = TextEditingController(text: widget.inicial?.nombre);

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    super.dispose();
  }

  void _aceptar() {
    final codigo = _codigo.text.trim().toUpperCase();
    final nombre = _nombre.text.trim();
    Navigator.of(context).pop(codigo.isEmpty ? null : (codigo: codigo, nombre: nombre.isEmpty ? codigo : nombre));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _codigo,
            autofocus: true,
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Símbolo (ej. V)'),
          ),
          TextField(
            controller: _nombre,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nombre (ej. Verdes)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(onPressed: _aceptar, child: Text(widget.inicial == null ? 'Agregar' : 'Guardar')),
      ],
    );
  }
}
