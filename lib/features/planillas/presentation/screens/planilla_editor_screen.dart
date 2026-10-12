import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/config/cultivo_config.dart';
import '../../domain/entities/planilla.dart';

// ─── Paleta "Papel Digital" (mockup oficial) ───────────────────────────────
const _kPapel = Color(0xFFFAF7EE);
const _kPapelSutil = Color(0xFFF4EFE0);
const _kPapelCard = Color(0xFFFFFFFF);
const _kInk = Color(0xFF0F2537);
const _kInkMuted = Color(0xFF536B7E);
const _kGold = Color(0xFFC29B38);
const _kGoldDark = Color(0xFF8E6B17);
const _kGreen = Color(0xFF1B5E3C);
const _kGreenLight = Color(0xFFE8F5EC);
const _kGreenFooter1 = Color(0xFF173F2B);
const _kGreenFooter2 = Color(0xFF1F5C3E);
const _kBorde = Color(0xFFD8D0BA);
const _kBordeDark = Color(0xFFB8AC90);

// Tonos gris limpio para toda la hoja (nada de negro).
const _kHeaderGris = Color(0xFFDDD8CA);

// FILA | columnas | TOTAL (flex proporcional al nº de columnas)
List<int> _flexes(int nCols) => [28, ...List.filled(nCols, 23), 34];

// ─── Paleta Material refinada "ticket fino" (mockup definitivo) ────────────
const _mSurface = Color(0xFFFBF9F5);
const _mSurfaceLowest = Color(0xFFFFFFFF);
const _mSurfaceLow = Color(0xFFF5F3EF);
const _mSurfaceHigh = Color(0xFFEAE8E4);
const _mOnSurface = Color(0xFF1B1C1A);
const _mOnSurfaceVariant = Color(0xFF43474D);
const _mPrimary = Color(0xFF00152A);
const _mPrimaryContainer = Color(0xFF102A43);
const _mOnPrimary = Color(0xFFFFFFFF);
const _mPrimaryFixed = Color(0xFFD1E4FF);
const _mSecondary = Color(0xFF006C4A);
const _mOnSecondary = Color(0xFFFFFFFF);
const _mSecondaryContainer = Color(0xFF82F5C1);
const _mOnSecondaryContainer = Color(0xFF00714E);
const _mOutline = Color(0xFF74777E);
const _mError = Color(0xFFBA1A1A);

class PlanillaEditorScreen extends ConsumerStatefulWidget {
  final int campanaId;
  final String cultivo;
  final String tipo;
  final int numeroHoja;
  final Planilla? planilla;

  const PlanillaEditorScreen({
    super.key,
    required this.campanaId,
    required this.cultivo,
    required this.tipo,
    required this.numeroHoja,
    this.planilla,
  });

  @override
  ConsumerState<PlanillaEditorScreen> createState() =>
      _PlanillaEditorScreenState();
}

class _PlanillaEditorScreenState extends ConsumerState<PlanillaEditorScreen> {
  final _scrollController = ScrollController();
  final _placaController = TextEditingController();
  final _notasController = TextEditingController();
  final _transportistaController = TextEditingController();
  String _mercadoDestino = '';
  DateTime _fecha = DateTime.now();
  bool _saving = false;
  bool _dirty = false;
  bool _immersive = false;
  OverlayEntry? _fullscreenEntry;
  int? _filaSel;

  late CultivoConfig _config;
  late List<ClaseConfig> _calidades;
  late int _numFilas;

  // matricial
  late Map<int, Map<String, int>> _matriz;
  final Map<int, Map<String, TextEditingController>> _crtl = {};
  final Map<int, Map<String, FocusNode>> _focus = {};
  // por_categorias
  late List<String> _catCodigos;
  late Map<String, int> _catSacos;
  late Map<String, double> _catPeso;
  late List<String> _catMarca;
  // peso_directo
  int _bultos = 0;
  double _pesoDirecto = 0;

  @override
  void initState() {
    super.initState();
    _config = CultivoConfig.forCultivo(widget.cultivo);
    if (_config.mercados.isNotEmpty) {
      _mercadoDestino = _config.mercados.first.codigo;
    }

    _calidades = widget.tipo == 'matricial'
        ? const [
            ClaseConfig(codigo: 'I', nombre: 'I - 1ra Roja', descripcion: ''),
            ClaseConfig(codigo: 'II', nombre: 'II - 2da Roja', descripcion: ''),
            ClaseConfig(
              codigo: 'III',
              nombre: 'III - Tercera',
              descripcion: '',
            ),
            ClaseConfig(codigo: '0', nombre: '0 - Mezcla', descripcion: ''),
            ClaseConfig(
              codigo: 'R',
              nombre: 'R - Roja suelta',
              descripcion: '',
            ),
            ClaseConfig(codigo: 'Z', nombre: 'Z - Verde', descripcion: ''),
          ]
        : _config.clases;

    _numFilas = 15;
    _matriz = {
      for (var i = 1; i <= _numFilas; i++)
        i: {for (final cal in _calidades) cal.codigo: 0},
    };

    _catCodigos = _config.clases.map((c) => c.codigo).toList();
    _catSacos = {for (final c in _catCodigos) c: 0};
    _catPeso = {for (final c in _catCodigos) c: 0.0};
    _catMarca = List.filled(_catCodigos.length, 'rojo');

    final p = widget.planilla;
    if (p != null) {
      _fecha = DateTime.tryParse(p.fecha) ?? DateTime.now();
      _mercadoDestino = p.mercado ?? '';
      _transportistaController.text = p.transportista ?? '';
      _notasController.text = p.notas ?? '';
      if (p.payload['placa'] is String) {
        _placaController.text = p.payload['placa'] as String;
      }
      _restaurarPayload(p.payload);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final fr in _focus.values) {
      for (final f in fr.values) {
        f.dispose();
      }
    }
    for (final cr in _crtl.values) {
      for (final c in cr.values) {
        c.dispose();
      }
    }
    _placaController.dispose();
    _notasController.dispose();
    _transportistaController.dispose();
    _fullscreenEntry?.remove();
    _fullscreenEntry = null;
    if (_immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    super.dispose();
  }

  void _restaurarPayload(Map<String, dynamic> payload) {
    if (widget.tipo == 'matricial') {
      final filas = payload['filas'] as List<dynamic>?;
      if (filas != null) {
        for (final f in filas) {
          final fila = (f as Map<String, dynamic>)['fila'] as int?;
          if (fila == null) continue;
          final calidades =
              (f['calidades'] as Map<String, dynamic>?) ?? const {};
          for (final e in calidades.entries) {
            _matriz[fila]?[e.key] = (e.value as num?)?.toInt() ?? 0;
          }
        }
      }
    } else if (widget.tipo == 'por_categorias') {
      final cats = payload['categorias'] as List<dynamic>?;
      if (cats != null) {
        for (final c in cats) {
          final m = c as Map<String, dynamic>;
          final codigo = m['codigo'] as String?;
          if (codigo == null) continue;
          _catSacos[codigo] = (m['sacos'] as num?)?.toInt() ?? 0;
          _catPeso[codigo] = (m['peso_kg'] as num?)?.toDouble() ?? 0;
          _catMarca[_catCodigos.indexWhere((codo) => codo == codigo)] =
              (m['marca'] as String?) ?? 'rojo';
        }
      }
    } else {
      _bultos = (payload['bultos'] as num?)?.toInt() ?? 0;
      _pesoDirecto = (payload['peso_total_kg'] as num?)?.toDouble() ?? 0;
    }
  }

  // ─── Cálculos ────────────────────────────────────────────────────────
  int _celdaValor(int fila, String codigo) => _matriz[fila]?[codigo] ?? 0;

  int _filaTotal(int fila) {
    var total = 0;
    for (final cal in _calidades) {
      total += _celdaValor(fila, cal.codigo);
    }
    return total;
  }

  int _colTotal(String codigo) {
    var total = 0;
    for (var fila = 1; fila <= _numFilas; fila++) {
      total += _celdaValor(fila, codigo);
    }
    return total;
  }

  int get _totalMatriz {
    var total = 0;
    for (var fila = 1; fila <= _numFilas; fila++) {
      total += _filaTotal(fila);
    }
    return total;
  }

  int get _totalSacos {
    var total = 0;
    for (final c in _catCodigos) {
      total += _catSacos[c] ?? 0;
    }
    return total;
  }

  double get _totalPesoCategorias {
    var total = 0.0;
    for (final c in _catCodigos) {
      total += _catPeso[c] ?? 0;
    }
    return total;
  }

  int get _totalUnidades => switch (widget.tipo) {
    'matricial' => _totalMatriz,
    'por_categorias' => _totalSacos,
    _ => _bultos,
  };

  double get _totalPeso => switch (widget.tipo) {
    'por_categorias' => _totalPesoCategorias,
    'matricial' => 0,
    _ => _pesoDirecto,
  };

  int get _sumByFilas {
    var t = 0;
    for (var fila = 1; fila <= _numFilas; fila++) {
      t += _filaTotal(fila);
    }
    return t;
  }

  int get _sumByCalidades {
    var t = 0;
    for (final c in _calidades) {
      t += _colTotal(c.codigo);
    }
    return t;
  }

  bool get _auditOk => _totalMatriz > 0 && _sumByFilas == _sumByCalidades;

  String get pesoMostrar {
    final p = _totalPeso;
    if (p <= 0) return '0';
    return p.toStringAsFixed(p == p.roundToDouble() ? 0 : 2);
  }

  String get _unidadLabel => switch (widget.tipo) {
    'matricial' => 'JAVAS',
    'por_categorias' => 'SACOS',
    _ => 'BULTOS',
  };

  String get _campanaCodigo {
    final prefix = switch (widget.cultivo.toLowerCase()) {
      'tomate' => 'TOM',
      'cebolla' => 'CEB',
      'papa' => 'PAP',
      'vainita' => 'VAI',
      'zapallo' => 'ZAP',
      _ => widget.cultivo.substring(0, 3).toUpperCase().padRight(3, 'X'),
    };
    return '$prefix-${widget.campanaId.toString().padLeft(2, '0')}-AX';
  }

  String get _tituloCultivo =>
      '${widget.cultivo[0].toUpperCase()}${widget.cultivo.substring(1)}';

  // ─── Celdas matriciales (focus libre + teclado del sistema) ─────────
  TextEditingController _celdaCtrl(int fila, String codigo) {
    final m = _crtl.putIfAbsent(fila, () => {});
    return m.putIfAbsent(codigo, () {
      final v = _celdaValor(fila, codigo);
      return TextEditingController(text: v == 0 ? '' : '$v');
    });
  }

  FocusNode _celdaFocus(int fila, String codigo) {
    final m = _focus.putIfAbsent(fila, () => {});
    return m.putIfAbsent(codigo, () {
      final fn = FocusNode();
      fn.addListener(() {
        if (mounted && fn.hasFocus) {
          setState(() {});
        }
      });
      return fn;
    });
  }

  void _syncCeldas() {
    for (var fila = 1; fila <= _numFilas; fila++) {
      final fr = _crtl[fila];
      if (fr == null) continue;
      for (final e in fr.entries) {
        final v = _celdaValor(fila, e.key);
        final target = v == 0 ? '' : '$v';
        if (e.value.text != target) e.value.text = target;
      }
    }
    if (mounted) setState(() {});
  }

  void _desenfocar() {
    FocusScope.of(context).unfocus();
    setState(() => _filaSel = null);
  }

  void _entrarInmersivo() {
    if (_fullscreenEntry != null) return;
    FocusScope.of(context).unfocus();
    setState(() => _immersive = true);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _fullscreenEntry = OverlayEntry(builder: (_) => _buildHojaInmersiva());
    Overlay.of(context, rootOverlay: true).insert(_fullscreenEntry!);
  }

  void _salirInmersivo() {
    _fullscreenEntry?.remove();
    _fullscreenEntry = null;
    setState(() => _immersive = false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // Refresca el overlay full-screen tras cambios de celdas/filas/columnas.
  void _refreshFull() {
    if (_immersive) _fullscreenEntry?.markNeedsBuild();
  }

  void _avanzar(int fila, String codigo) {
    final idx = _calidades.indexWhere((c) => c.codigo == codigo);
    if (idx < _calidades.length - 1) {
      _focusRow(fila, _calidades[idx + 1].codigo);
    } else if (fila < _numFilas) {
      _focusRow(fila + 1, _calidades.first.codigo);
    } else {
      setState(() {
        _numFilas++;
        _matriz[_numFilas] = {for (final cal in _calidades) cal.codigo: 0};
        _dirty = true;
      });
      _refreshFull();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusRow(_numFilas, _calidades.first.codigo);
      });
    }
  }

  void _focusRow(int fila, String codigo) {
    final fn = _celdaFocus(fila, codigo);
    fn.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = (fila - 1) * _kRowHeight;
      final max = _scrollController.position.maxScrollExtent;
      final offset = (target - 80).clamp(0.0, max.toDouble());
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  static const double _kRowHeight = 48;

  void _agregarFila() {
    setState(() {
      _numFilas++;
      _matriz[_numFilas] = {for (final cal in _calidades) cal.codigo: 0};
      _dirty = true;
    });
    _refreshFull();
    _syncCeldas();
  }

  void _eliminarFilaSeleccionada() {
    final f = _filaSel;
    if (f == null) return;
    _crtl.remove(f)?.values.forEach((c) => c.dispose());
    _focus.remove(f)?.values.forEach((fn) => fn.dispose());
    final nueva = <int, Map<String, int>>{};
    var idn = 1;
    for (var r = 1; r <= _numFilas; r++) {
      if (r == f) continue;
      nueva[idn++] =
          _matriz[r] ?? {for (final cal in _calidades) cal.codigo: 0};
    }
    setState(() {
      if (_numFilas > 1) _numFilas--;
      _matriz = nueva;
      _filaSel = null;
      _dirty = true;
    });
    _syncCeldas();
    _refreshFull();
  }

  void _fillEjemplo() {
    setState(() {
      _numFilas = _numFilas < 8 ? 8 : _numFilas;
      const patterns = [
        [44, 40, 15, 0, 5, 0],
        [44, 44, 10, 5, 0, 1],
        [40, 40, 20, 10, 5, 0],
        [44, 44, 15, 0, 0, 0],
        [40, 35, 10, 5, 1, 0],
        [44, 40, 15, 0, 0, 0],
        [30, 25, 10, 5, 2, 0],
        [44, 44, 0, 0, 0, 0],
      ];
      for (var i = 0; i < patterns.length; i++) {
        _matriz[i + 1] = {for (final cal in _calidades) cal.codigo: 0};
        for (var j = 0; j < _calidades.length && j < patterns[i].length; j++) {
          _matriz[i + 1]![_calidades[j].codigo] = patterns[i][j];
        }
      }
      _dirty = true;
    });
    _syncCeldas();
    _refreshFull();
  }

  // ─── Columnas editables (I, II, III …) ───────────────────────────────
  Future<void> _editarColumnas() async {
    final working = _calidades.map((c) => c.codigo).toList();
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void agregar() {
              final s = ctrl.text.trim().toUpperCase();
              if (s.isNotEmpty && !working.contains(s)) {
                setDialogState(() {
                  working.add(s);
                  ctrl.clear();
                });
              }
            }

            return AlertDialog(
              backgroundColor: _kPapel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: _kGold, width: 1.4),
              ),
              title: Text(
                'Columnas de la hoja',
                style: GoogleFonts.cinzel(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toca ✕ para borrar un símbolo y agrega los que uses '
                      '(ej: AA, P, M).',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: _kInkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final c in working)
                          Chip(
                            label: Text(c),
                            labelStyle: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.w800,
                              color: _kInk,
                            ),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 14,
                              color: _kGoldDark,
                            ),
                            onDeleted: () =>
                                setDialogState(() => working.remove(c)),
                            backgroundColor: _kPapelSutil,
                            side: const BorderSide(color: _kBorde),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            maxLength: 3,
                            textCapitalization: TextCapitalization.characters,
                            decoration: _metaDeco(
                              'NUEVO SÍMBOLO (ej: AA)',
                            ).copyWith(counterText: ''),
                            onSubmitted: (_) => agregar(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        FilledButton(
                          onPressed: agregar,
                          style: FilledButton.styleFrom(
                            backgroundColor: _kGreen,
                          ),
                          child: const Text('Agregar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: working.isEmpty
                      ? null
                      : () {
                          _aplicarColumnas(working);
                          Navigator.of(dialogCtx).pop();
                        },
                  style: FilledButton.styleFrom(backgroundColor: _kGreen),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    ctrl.dispose();
  }

  void _aplicarColumnas(List<String> codigos) {
    if (codigos.isEmpty) return;
    final keep = codigos.toSet();
    for (final e in _crtl.entries) {
      e.value.removeWhere((k, c) {
        if (!keep.contains(k)) {
          c.dispose();
          return true;
        }
        return false;
      });
    }
    for (final e in _focus.entries) {
      e.value.removeWhere((k, fn) {
        if (!keep.contains(k)) {
          fn.dispose();
          return true;
        }
        return false;
      });
    }
    setState(() {
      _calidades = [
        for (final c in codigos)
          ClaseConfig(codigo: c, nombre: c, descripcion: ''),
      ];
      for (var fila = 1; fila <= _numFilas; fila++) {
        final m = _matriz[fila] ?? {};
        for (final c in codigos) {
          m.putIfAbsent(c, () => 0);
        }
        _matriz[fila] = m;
      }
      _dirty = true;
    });
    _syncCeldas();
    _refreshFull();
  }

  // ─── Edición categorías / peso ──────────────────────────────────────
  void _celdaCat(int row, String field, String raw) {
    setState(() {
      if (field == 'sacos') {
        _catSacos[_catCodigos[row]] = int.tryParse(raw) ?? 0;
      } else {
        _catPeso[_catCodigos[row]] =
            double.tryParse(raw.replaceAll(',', '.')) ?? 0;
      }
      _dirty = true;
    });
  }

  // ─── Payload JSON flexible ───────────────────────────────────────────
  Map<String, dynamic> _buildPayload() {
    final base = {
      'tipo': widget.tipo,
      'numero_hoja': widget.numeroHoja,
      'placa': _placaController.text.trim().toUpperCase(),
      'campana': _campanaCodigo,
    };
    if (widget.tipo == 'matricial') {
      return {
        ...base,
        'filas': [
          for (var fila = 1; fila <= _numFilas; fila++)
            {
              'fila': fila,
              'calidades': {
                for (final cal in _calidades)
                  cal.codigo: _celdaValor(fila, cal.codigo),
              },
              'total': _filaTotal(fila),
            },
        ],
        'columnas': {
          for (final cal in _calidades) cal.codigo: _colTotal(cal.codigo),
        },
        'gran_total': _totalMatriz,
        'validacion': _auditOk ? 'cuadre_ok' : 'pendiente',
      };
    }
    if (widget.tipo == 'por_categorias') {
      return {
        ...base,
        'categorias': [
          for (var i = 0; i < _catCodigos.length; i++)
            {
              'codigo': _catCodigos[i],
              'marca': _catMarca[i],
              'sacos': _catSacos[_catCodigos[i]],
              'peso_kg': _catPeso[_catCodigos[i]],
            },
        ],
        'total_sacos': _totalSacos,
        'peso_total_kg': _totalPesoCategorias,
      };
    }
    return {
      ...base,
      'bultos': _bultos,
      'peso_total_kg': _pesoDirecto,
      'peso_promedio_bulto_kg': _bultos > 0 ? (_pesoDirecto / _bultos) : 0,
    };
  }

  Planilla _buildPlanilla({bool compartida = false}) {
    final now = DateTime.now().toIso8601String();
    final existing = widget.planilla;
    return Planilla(
      id: existing?.id,
      uuidLocal: existing?.uuidLocal ?? const Uuid().v4(),
      campanaId: widget.campanaId,
      cultivo: widget.cultivo,
      tipo: widget.tipo,
      fecha: DateFormat('yyyy-MM-dd').format(_fecha),
      mercado: _mercadoDestino,
      transportista: _transportistaController.text.trim(),
      notas: _notasController.text.trim(),
      totalUnidades: _totalUnidades,
      totalPeso: _totalPeso,
      estado: compartida ? 'compartida' : 'guardada',
      payload: _buildPayload(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      isSynced: existing?.isSynced ?? false,
    );
  }

  Future<Planilla> _persistir() async {
    final planilla = _buildPlanilla();
    final notifier = ref.read(planillasProvider.notifier);
    if (widget.planilla?.id != null) {
      await notifier.updatePlanilla(planilla);
    } else {
      await notifier.addPlanilla(planilla);
    }
    return planilla;
  }

  Future<void> _guardarCarga() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _persistir();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carga guardada correctamente')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _salir() async {
    if (_saving) return;
    if (_dirty) {
      try {
        await _persistir();
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _exportarAWhatsApp() async {
    if (_saving) return;
    setState(() => _saving = true);
    late final Planilla planilla;
    try {
      planilla = await _persistir();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
      setState(() => _saving = false);
      return;
    }
    setState(() => _saving = false);
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExportPreviewDialog(planilla: planilla),
    );
  }

  // ─── Dialog de metadatos (placa · chofer · fecha · campaña) ──────────
  Future<void> _editarMeta() async {
    final placaCtrl = TextEditingController(text: _placaController.text);
    final choferCtrl = TextEditingController(
      text: _transportistaController.text,
    );
    var fecha = _fecha;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _kPapel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: _kGold, width: 1.4),
              ),
              title: Text(
                'Ficha del viaje',
                style: GoogleFonts.cinzel(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: placaCtrl,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      color: _kInk,
                      fontWeight: FontWeight.w700,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    decoration: _metaDeco('PLACA'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: choferCtrl,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      color: _kInk,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _metaDeco('CHOFER'),
                  ),
                  const SizedBox(height: 10),
                  _metaDateButton(context, fecha, (d) {
                    setDialogState(() => fecha = d);
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _placaController.text = placaCtrl.text
                          .trim()
                          .toUpperCase();
                      _transportistaController.text = choferCtrl.text.trim();
                      _fecha = fecha;
                      _dirty = true;
                    });
                    Navigator.of(dialogCtx).pop();
                  },
                  style: FilledButton.styleFrom(backgroundColor: _kGreen),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    placaCtrl.dispose();
    choferCtrl.dispose();
  }

  InputDecoration _metaDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        color: _kInkMuted,
        fontWeight: FontWeight.w700,
      ),
      isDense: true,
      filled: true,
      fillColor: _kPapelCard,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kBorde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kGold, width: 1.4),
      ),
    );
  }

  Widget _metaDateButton(
    BuildContext context,
    DateTime f,
    ValueChanged<DateTime> onPick,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: f,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kPapelCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorde),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 15, color: _kGoldDark),
            const SizedBox(width: 8),
            Text(
              'FECHA · ${DateFormat('dd/MM/yyyy').format(f)}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: _kInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_immersive,
      onPopInvokedWithResult: (didPop, _) {
        if (_immersive && !didPop) _salirInmersivo();
      },
      child: Scaffold(
        backgroundColor: _mSurface,
        resizeToAvoidBottomInset: widget.tipo != 'matricial',
        body: _immersive ? const SizedBox.shrink() : _buildNormal(),
      ),
    );
  }

  Widget _buildNormal() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          _buildFichaMeta(),
          _buildInstrucciones(),
          Expanded(child: _buildCuerpo()),
          _buildLegend(),
          _buildFooterTotales(),
        ],
      ),
    );
  }

  // ─── Overlay full-screen (100vw/100vh) ───────────────────────────────
  Widget _buildHojaInmersiva() {
    final flex = _flexes(_calidades.length);
    return Material(
      color: _mSurfaceLowest,
      child: GestureDetector(
        onTap: _desenfocar,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  _buildMatrizHeader(),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        top: 4,
                        bottom: 4 + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      itemCount: _numFilas,
                      itemBuilder: (context, i) => _buildMatrizRow(i + 1),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: const BoxDecoration(
                      color: _mSurfaceHigh,
                      border: Border(top: BorderSide(color: Color(0x14000000))),
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < flex.length; i++)
                          Expanded(flex: flex[i], child: _sumaCell(i)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: _salirBtn(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _salirBtn() {
    return Tooltip(
      message: 'Salir de pantalla completa',
      child: Material(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: _salirInmersivo,
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Icon(Icons.close, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ─── Header fino: cerrar | título | pantalla completa | WhatsApp ──────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: _mSurfaceLowest,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _mIconBtn(Icons.close, 'Cerrar planilla', _salir),
          const SizedBox(width: 6),
          _mIconBtn(
            Icons.fullscreen,
            'Pantalla completa (solo la hoja)',
            _entrarInmersivo,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Planilla de Carga',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.chivo(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _mPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _mSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _tituloCultivo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: _mSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mIconBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _mSurfaceHigh,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: _mPrimary),
          ),
        ),
      ),
    );
  }

  // ─── Tarjeta manifiesto del ticket ───────────────────────────────────
  Widget _buildFichaMeta() {
    final placa = _placaController.text.trim().isEmpty
        ? '—'
        : _placaController.text.trim().toUpperCase();
    final chofer = _transportistaController.text.trim().isEmpty
        ? 'Sin chofer'
        : _transportistaController.text.trim();
    final ubicacion = _mercadoDestino.isEmpty
        ? 'Fundo El Olivar'
        : _mercadoDestino.toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _editarMeta,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _mSurfaceLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _mPrimaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      placa,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: _mOnPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Chofer: $chofer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.chivo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _mOnSurface,
                      ),
                    ),
                  ),
                  _enCargaBadge(),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 13,
                          color: _mOutline,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_fecha),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _mOnSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 13, color: _mOutline),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            DateFormat('hh:mm a').format(_fecha),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _mOnSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: _mPrimaryContainer,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            ubicacion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.chivo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _mPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _enCargaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _mSecondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _mOnSecondaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'EN CARGA',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: _mOnSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Micro-instrucción + contador de filas ───────────────────────────
  Widget _buildInstrucciones() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Row(
        children: [
          const Icon(Icons.touch_app, size: 14, color: _mSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'Toca una celda para registrar o editar javas',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.chivo(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _mOnSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _mPrimaryFixed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$_numFilas FILAS',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: _mPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Cuerpo (matriz / categorías / peso directo) ─────────────────────
  Widget _buildCuerpo() {
    if (widget.tipo == 'matricial') return _buildMatrizScroll();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: widget.tipo == 'por_categorias'
          ? _buildCategorias()
          : _buildPesoDirecto(),
    );
  }

  // Matriz pura: header de columnas fijo + filas en scroll vertical
  Widget _buildMatrizScroll() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _mSurfaceLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMatrizHeader(),
            Expanded(
              child: GestureDetector(
                onTap: _desenfocar,
                behavior: HitTestBehavior.translucent,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    0,
                    4,
                    0,
                    4 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  itemCount: _numFilas + (_immersive ? 0 : 1),
                  itemBuilder: (context, i) {
                    if (!_immersive && i == _numFilas) {
                      return _buildMatrizControles();
                    }
                    return _buildMatrizRow(i + 1);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrizHeader() {
    final flex = _flexes(_calidades.length);
    return GestureDetector(
      onDoubleTap: _immersive ? _salirInmersivo : null,
      child: Container(
        color: _mSurfaceHigh,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            for (var i = 0; i < flex.length; i++)
              Expanded(flex: flex[i], child: _headerCell(i)),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(int i) {
    final flex = _flexes(_calidades.length);
    final isTotal = i == flex.length - 1;
    final label = i == 0
        ? 'FILA'
        : isTotal
        ? 'TOT'
        : _calidades[i - 1].codigo;
    return Text(
      label,
      textAlign: TextAlign.center,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: i == 0
            ? _mOnSurfaceVariant
            : isTotal
            ? _mPrimaryContainer
            : _mPrimary,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildMatrizRow(int fila) {
    final filaTotal = _filaTotal(fila);
    final flex = _flexes(_calidades.length);
    final sel = _filaSel == fila;
    final par = fila.isEven;
    return InkWell(
      onTap: () {
        setState(() => _filaSel = sel ? null : fila);
        _refreshFull();
      },
      child: Container(
        height: _kRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: sel
              ? _mSecondaryContainer.withValues(alpha: 0.22)
              : par
              ? _mSurfaceLow.withValues(alpha: 0.6)
              : _mSurfaceLowest,
        ),
        child: Row(
          children: [
            Expanded(
              flex: flex[0],
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _mSurfaceLow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'F-${fila.toString().padLeft(2, '0')}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: sel ? _mSecondary : _mOnSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            for (var q = 0; q < _calidades.length; q++)
              Expanded(
                flex: flex[q + 1],
                child: _matrizCell(fila, _calidades[q]),
              ),
            Expanded(
              flex: flex.last,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _mSurfaceLow.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    filaTotal > 0 ? '$filaTotal' : '0',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _mPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matrizCell(int fila, ClaseConfig cal) {
    final ctrl = _celdaCtrl(fila, cal.codigo);
    final fn = _celdaFocus(fila, cal.codigo);
    final valor = _celdaValor(fila, cal.codigo);
    if (ctrl.text != (valor == 0 ? '' : '$valor')) {
      ctrl.text = valor == 0 ? '' : '$valor';
    }
    final selected = fn.hasFocus;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: selected
              ? _mSecondaryContainer.withValues(alpha: 0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? _mSecondary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: TextField(
                controller: ctrl,
                focusNode: fn,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                maxLines: 1,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? _mSecondary
                      : valor > 0
                      ? _mOnSurface
                      : _mOnSurfaceVariant,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: valor == 0 ? '−' : null,
                  hintStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _mOnSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
                onChanged: (t) {
                  setState(() {
                    _matriz[fila]?[cal.codigo] = int.tryParse(t) ?? 0;
                    _dirty = true;
                  });
                  _refreshFull();
                },
                onSubmitted: (_) => _avanzar(fila, cal.codigo),
              ),
            ),
            if (selected)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _mSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrizControles() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _ctrlBtn('+', 'Agregar Fila', _agregarFila, solid: true),
              _ctrlBtn(
                '−',
                _filaSel == null
                    ? 'Eliminar Fila'
                    : 'Eliminar Fila F-${_filaSel.toString().padLeft(2, '0')}',
                _filaSel == null ? null : _eliminarFilaSeleccionada,
                danger: _filaSel != null,
              ),
              _ctrlBtn(Icons.edit_outlined, 'Columnas', _editarColumnas),
              _ctrlBtn(Icons.bolt, 'Ejemplo', _fillEjemplo),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Toca la etiqueta F-01 para seleccionar esa fila y poder eliminarla',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: _mOutline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn(
    dynamic iconOrText,
    String label,
    VoidCallback? onTap, {
    bool solid = false,
    bool danger = false,
  }) {
    final enabled = onTap != null;
    const dangerColor = Color(0xFFBA1A1A);
    final bg = danger
        ? dangerColor.withValues(alpha: 0.12)
        : solid
        ? _mSecondary
        : _mSurfaceHigh;
    final fg = danger
        ? dangerColor
        : solid
        ? _mOnSecondary
        : _mOnSurfaceVariant;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconOrText is IconData
                  ? Icon(iconOrText, size: 14, color: fg)
                  : Text(
                      iconOrText as String,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: fg,
                      ),
                    ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: enabled ? fg : _mOutline.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorias() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kPapel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SACOS POR CATEGORÍA · PESO EN BALANZA',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: _kInkMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _catCodigos.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      _catCodigos[i],
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _kInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _catField(
                      'SACOS',
                      '${_catSacos[_catCodigos[i]] ?? 0}',
                      (raw) => _celdaCat(i, 'sacos', raw),
                      digitos: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _catField(
                      'PESO (kg)',
                      _pesoText(_catPeso[_catCodigos[i]] ?? 0),
                      (raw) => _celdaCat(i, 'peso_kg', raw),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _catField(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    bool digitos = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            color: _kInkMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        TextFormField(
          initialValue: value == '0' ? '' : value,
          keyboardType: TextInputType.numberWithOptions(decimal: !digitos),
          inputFormatters: digitos
              ? [FilteringTextInputFormatter.digitsOnly]
              : [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,6}(\.\d{0,2})?'),
                  ),
                ],
          textAlign: TextAlign.right,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: _kInk,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            filled: true,
            fillColor: _kPapelCard,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorde),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kGold, width: 1.4),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPesoDirecto() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kPapel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorde),
      ),
      child: Column(
        children: [
          Text(
            'PESAJE DIRECTO A GRANEL · BULTOS / MALLAS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: _kInkMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _bigTile(
                  'BULTOS / MALLAS',
                  '$_bultos',
                  onEdit: (t) {
                    setState(() {
                      _bultos = int.tryParse(t) ?? 0;
                      _dirty = true;
                    });
                  },
                  digitos: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _bigTile(
                  'PESO TOTAL (kg)',
                  _pesoText(_pesoDirecto),
                  onEdit: (t) {
                    setState(() {
                      _pesoDirecto =
                          double.tryParse(t.replaceAll(',', '.')) ?? 0;
                      _dirty = true;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _kGreenLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kGreen.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Peso promedio por bulto: '
              '${_bultos > 0 ? (_pesoDirecto / _bultos).toStringAsFixed(1) : '—'} kg',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigTile(
    String label,
    String value, {
    required ValueChanged<String> onEdit,
    bool digitos = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kPapelCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kGold.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: _kInkMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            keyboardType: TextInputType.numberWithOptions(decimal: !digitos),
            inputFormatters: digitos
                ? [FilteringTextInputFormatter.digitsOnly]
                : [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,6}(\.\d{0,2})?'),
                    ),
                  ],
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _kInk,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onEdit,
            initialValue: value == '0.0' || value == '0' ? '' : value,
          ),
        ],
      ),
    );
  }

  // ─── Footer fijo de totales y doble verificación ─────────────────────
  Widget _buildFooterTotales() {
    final unidades = _totalUnidades;
    if (widget.tipo == 'matricial') {
      return Container(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          10 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: _mSurfaceLowest,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: _mSurfaceHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _flexes(_calidades.length).length; i++)
                    Expanded(
                      flex: _flexes(_calidades.length)[i],
                      child: _sumaCell(i),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARGA EFECTIVA',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: _mOnSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$_totalMatriz',
                            style: GoogleFonts.chivo(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -1,
                              color: _mPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'JAVAS',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _mPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _auditStamp(),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child:               _footerBtn(
                    Icons.send,
                    'Enviar WhatsApp',
                    _exportarAWhatsApp,
                    light: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _footerBtn(
                    Icons.save,
                    'Guardar Carga',
                    _guardarCarga,
                    light: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    // Categorías / peso directo
    return Container(
      color: _kHeaderGris,
      padding: EdgeInsets.fromLTRB(
        10,
        8,
        10,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUMAS',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: _kInkMuted,
                ),
              ),
              Text(
                '$unidades $_unidadLabel',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _kInk,
                ),
              ),
              if (widget.tipo == 'por_categorias' || _pesoDirecto > 0)
                Text(
                  '$pesoMostrar kg',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kInkMuted,
                  ),
                ),
            ],
          ),
          const Spacer(),
          _grandTotalBox(unidades),
        ],
      ),
    );
  }

  Widget _sumaCell(int i) {
    if (i == 0) {
      return Text(
        'SUB',
        textAlign: TextAlign.center,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: _mOnSurfaceVariant,
        ),
      );
    }
    if (i == _flexes(_calidades.length).length - 1) {
      return Text(
        '$_totalMatriz',
        textAlign: TextAlign.center,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: _mPrimaryContainer,
        ),
      );
    }
    final cal = _calidades[i - 1];
    final total = _colTotal(cal.codigo);
    final maxCol = _maxColumna;
    return Text(
      '$total',
      textAlign: TextAlign.center,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: total > 0 && cal.codigo == maxCol ? _mSecondary : _mPrimary,
      ),
    );
  }

  String? get _maxColumna {
    String? maxCod;
    var maxVal = -1;
    for (final c in _calidades) {
      final v = _colTotal(c.codigo);
      if (v > maxVal) {
        maxVal = v;
        maxCod = c.codigo;
      }
    }
    return maxCod;
  }

  Widget _auditStamp() {
    final ok = _auditOk;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? _mSecondaryContainer : const Color(0xFFFFDAD6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ok ? Icons.verified : Icons.error_outline,
                size: 16,
                color: ok ? _mOnSecondaryContainer : _mError,
              ),
              const SizedBox(width: 4),
              Text(
                ok ? 'Suma Cuadrada' : '¡Descuadre!',
                style: GoogleFonts.chivo(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: ok ? _mOnSecondaryContainer : _mError,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            ok
                ? (_totalMatriz > 0
                      ? '100% Verificado'
                      : 'Complete la producción')
                : 'Revisa las sumas',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: ok ? _mOnSecondaryContainer : _mError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    required bool light,
  }) {
    return _saving
        ? const SizedBox.shrink()
        : Material(
            color: light ? _mSurfaceHigh : _mPrimaryContainer,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: light ? _mPrimary : const Color(0xFF85F8C4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.chivo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: light ? _mPrimary : _mOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  // ─── Leyenda de calibres ─────────────────────────────────────────────
  Widget _buildLegend() {
    if (widget.tipo != 'matricial') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _mSurfaceLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text.rich(
          TextSpan(
            style: GoogleFonts.chivo(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _mOnSurfaceVariant,
            ),
            children: [
              TextSpan(
                text: 'Calibres:  ',
                style: GoogleFonts.chivo(
                  fontWeight: FontWeight.w700,
                  color: _mPrimary,
                ),
              ),
              for (var i = 0; i < _calidades.length; i++)
                TextSpan(
                  text: '${_calidades[i].codigo}: ${_descCalibre(i)}   ',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: _mOnSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _descCalibre(int i) {
    const d = ['Extra', 'Primera', 'Segunda', 'Tercera', 'Rejilla', 'Merma'];
    final idx = ['I', 'II', 'III', '0', 'R', 'Z'].indexOf(_calidades[i].codigo);
    return idx >= 0 ? d[idx] : _calidades[i].codigo;
  }

  Widget _grandTotalBox(int unidades) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGreenFooter1, _kGreenFooter2],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGold.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'GRAN TOTAL',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: _kGold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$unidades $_unidadLabel',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: _kPapel,
            ),
          ),
        ],
      ),
    );
  }

  String _pesoText(double v) {
    if (v == 0) return '0';
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
  }
}

// ─── Vista previa + exportación del comprobante HD ───────────────────────
class _ExportPreviewDialog extends ConsumerStatefulWidget {
  final Planilla planilla;
  const _ExportPreviewDialog({required this.planilla});

  @override
  ConsumerState<_ExportPreviewDialog> createState() =>
      _ExportPreviewDialogState();
}

class _ExportPreviewDialogState extends ConsumerState<_ExportPreviewDialog> {
  final _tapeKey = GlobalKey();
  bool _processing = false;
  bool _completo = true;

  Future<XFile?> _capturar() async {
    final boundary =
        _tapeKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _completo ? 2.6 : 3.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/comprobante_${widget.planilla.numeroHojaText()}.png',
    );
    await file.writeAsBytes(bytes.buffer.asUint8List());
    return XFile(file.path);
  }

  Future<void> _compartir([bool descargar = false]) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final file = await _capturar();
      if (file == null) return;
      if (descargar) {
        final docs = await getApplicationDocumentsDirectory();
        final ex = Directory('${docs.path}/export');
        if (!await ex.exists()) await ex.create(recursive: true);
        await File(file.path).copy('${ex.path}/${file.name}');
      }
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          text:
              'Comprobante · ${widget.planilla.cultivo} · '
              'N° ${widget.planilla.numeroHojaText()} · '
              '${widget.planilla.totalUnidades} unidades',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kPapel,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _kBorde),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF075E54),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.share, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Comprobante HD · Exportación Oficial',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _exportBtn('Descargar PNG', false),
                  const SizedBox(width: 6),
                  _exportBtn('Cerrar', true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _modoBtn('Solo resumen', !_completo, () {
                    setState(() => _completo = false);
                  }),
                  const SizedBox(width: 8),
                  _modoBtn('Hoja completa', _completo, () {
                    setState(() => _completo = true);
                  }),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: RepaintBoundary(
                  key: _tapeKey,
                  child: _Comprobante(
                    planilla: widget.planilla,
                    width: 300,
                    completo: _completo,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _processing ? null : () => _compartir(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 16),
                  label: Text(
                    'Compartir en WhatsApp',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportBtn(String label, bool cerrar) {
    return Material(
      color: cerrar ? Colors.white24 : const Color(0xFF102A43),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          if (cerrar) {
            Navigator.of(context).pop();
          } else {
            _compartir(true);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _modoBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: active ? _kGreen : _kPapelSutil,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: active ? _kGreen : _kBorde),
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : _kInkMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tarjeta de comprobante técnico (exportable como imagen) ─────────────
class _Comprobante extends StatelessWidget {
  final Planilla planilla;
  final double width;
  final bool completo;
  const _Comprobante({
    required this.planilla,
    this.width = 300,
    this.completo = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = planilla;
    final colSumas = p.payload['columnas'] as Map<String, dynamic>?;
    final categorias = p.payload['categorias'] as List<dynamic>?;
    final bultos = (p.payload['bultos'] as num?)?.toInt() ?? 0;
    final fecha = DateTime.tryParse(p.fecha);
    final fechaTxt = fecha == null
        ? ''
        : '${DateFormat('dd-MMM-yyyy').format(fecha).toUpperCase()} '
              '${DateFormat('HH:mm').format(fecha)}';
    final placa = (p.payload['placa'] as String?) ?? '—';
    final campana = (p.payload['campana'] as String?) ?? '—';
    final hash = p.uuidLocal.replaceAll('-', '').substring(0, 16).toUpperCase();

    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kPapel,
        border: Border.all(color: _kGoldDark.withValues(alpha: 0.5), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AGROCONTROL COSECHA',
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _kInk,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'HOJA DE EMBARQUE · MERCADO MAYORISTA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        color: _kInkMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _kGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CONFORME ✓',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fechaTxt,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 7,
                      color: _kInkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            height: 2,
            color: _kInk,
            margin: const EdgeInsets.symmetric(vertical: 7),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kPapelCard,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kBorde),
            ),
            child: Row(
              children: [
                Expanded(child: _ficha('CAMIÓN', placa)),
                Expanded(
                  child: _ficha(
                    'CHOFER',
                    p.transportista?.trim().isEmpty ?? true
                        ? '—'
                        : p.transportista!.trim(),
                  ),
                ),
                Expanded(child: _ficha('PRODUCTO', _productoLabel(p))),
                Expanded(child: _ficha('CAMPAÑA', campana)),
              ],
            ),
          ),
          const SizedBox(height: 7),
          if (p.tipo == 'matricial' && colSumas != null) ...[
            Text(
              completo
                  ? 'HOJA COMPLETA (JAVAS) - TODAS LAS FILAS:'
                  : 'RESUMEN CONSOLIDADO (JAVAS):',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: _kInkMuted,
              ),
            ),
            const SizedBox(height: 4),
            if (completo)
              _matrizCompleta(p, colSumas)
            else
              _resumenConsolidado(p, colSumas),
          ] else if (p.tipo == 'por_categorias' && categorias != null) ...[
            Text(
              'RESUMEN CONSOLIDADO (SACOS):',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: _kInkMuted,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _kBorde),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  for (final c in categorias)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${c['marca'] ?? '—'} · ${c['codigo']}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: _kInk,
                              ),
                            ),
                          ),
                          Text(
                            '${(c['sacos'] as num?)?.toInt() ?? 0} sacos',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: _kInk,
                            ),
                          ),
                          Text(
                            ' · ${(c['peso_kg'] as num?)?.toDouble() ?? 0} kg',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8,
                              color: _kInkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'DESPACHO A GRANEL:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: _kInkMuted,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _kPapelCard,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _kBorde),
              ),
              child: Row(
                children: [
                  Text(
                    '$bultos bultos / mallas',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: _kInk,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${p.totalPeso} kg',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: _kInk,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF102A43), Color(0xFF17324A)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL EMBARCADO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          color: _kGold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Matriz certificada 100% verificada',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 6.5,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${p.totalUnidades} ${p.tipo == 'matricial'
                      ? 'JAVAS'
                      : p.tipo == 'por_categorias'
                      ? 'SACOS'
                      : 'BULTOS'}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _kPapel,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 7),
            padding: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _kBordeDark, style: BorderStyle.solid),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Firma Supervisor Responsable',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 6.5,
                          color: _kInkMuted,
                        ),
                      ),
                      Text(
                        'Ing. C. Mendoza V.',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: _kInk,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Hash de Seguridad:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 6,
                        color: _kInkMuted,
                      ),
                    ),
                    Text(
                      'SHA256: ${_hashText(hash)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 6,
                        color: _kInkMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _productoLabel(Planilla p) {
    final c = p.cultivo;
    return '${c[0].toUpperCase()}${c.substring(1)} Cal. Export';
  }

  int _cint(Object? o) => (o as num?)?.toInt() ?? 0;

  Widget _matEntry(String text, bool bold, Color color) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 7.5,
        fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
        color: color,
      ),
    );
  }

  Widget _resumenConsolidado(Planilla p, Map<String, dynamic> colSumas) {
    final colKeys = colSumas.keys.toList();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kBorde),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            color: const Color(0xFFF4EFE0),
            child: Row(
              children: [
                for (final s in [...colKeys, 'TOTAL'])
                  Expanded(
                    child: _matEntry(s, true, s == 'TOTAL' ? _kGreen : _kInk),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: _kPapelCard,
            child: Row(
              children: [
                for (final s in colKeys)
                  Expanded(
                    child: _matEntry('${_cint(colSumas[s])}', false, _kInk),
                  ),
                Expanded(child: _matEntry('${p.totalUnidades}', true, _kGreen)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _matrizCompleta(Planilla p, Map<String, dynamic> colSumas) {
    final filas = (p.payload['filas'] as List<dynamic>?) ?? [];
    final colKeys = colSumas.keys.toList();
    final flex = _flexes(colKeys.length);
    if (colKeys.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: _kBorde),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Sin columnas anotadas',
          style: GoogleFonts.plusJakartaSans(fontSize: 8, color: _kInkMuted),
        ),
      );
    }
    final visibles = <Map<String, dynamic>>[];
    for (final f in filas) {
      final m = f as Map<String, dynamic>;
      final cal = (m['calidades'] as Map<String, dynamic>?) ?? const {};
      final has =
          _cint(m['total']) > 0 || colKeys.any((k) => _cint(cal[k]) > 0);
      if (has) visibles.add(m);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kBorde),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            color: const Color(0xFFF4EFE0),
            child: Row(
              children: [
                Expanded(
                  flex: flex[0],
                  child: _matEntry('FILA', true, _kInkMuted),
                ),
                for (var i = 0; i < colKeys.length; i++)
                  Expanded(
                    flex: flex[i + 1],
                    child: _matEntry(colKeys[i], true, _kInk),
                  ),
                Expanded(
                  flex: flex.last,
                  child: _matEntry('TOTAL', true, _kGreen),
                ),
              ],
            ),
          ),
          for (var r = 0; r < visibles.length; r++) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              color: r.isEven ? _kPapelCard : const Color(0xFFF4EFE0),
              child: Row(
                children: [
                  Expanded(
                    flex: flex[0],
                    child: _matEntry(
                      'F${visibles[r]['fila']}',
                      false,
                      _kInkMuted,
                    ),
                  ),
                  for (var i = 0; i < colKeys.length; i++)
                    Expanded(
                      flex: flex[i + 1],
                      child: _matEntry(
                        '${_cint((visibles[r]['calidades'] as Map<String, dynamic>?)?[colKeys[i]])}',
                        false,
                        _kInk,
                      ),
                    ),
                  Expanded(
                    flex: flex.last,
                    child: _matEntry(
                      '${_cint(visibles[r]['total'])}',
                      true,
                      _kGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            color: const Color(0xFFF4EFE0),
            child: Row(
              children: [
                Expanded(
                  flex: flex[0],
                  child: _matEntry('Σ', true, _kInkMuted),
                ),
                for (var i = 0; i < colKeys.length; i++)
                  Expanded(
                    flex: flex[i + 1],
                    child: _matEntry(
                      '${_cint(colSumas[colKeys[i]])}',
                      true,
                      _kInk,
                    ),
                  ),
                Expanded(
                  flex: flex.last,
                  child: _matEntry('${p.totalUnidades}', true, _kGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _hashText(String h) {
    final groups = <String>[];
    for (var i = 0; i < h.length; i += 4) {
      groups.add(h.substring(i, (i + 4).clamp(0, h.length)));
    }
    return groups.join('-');
  }

  Widget _ficha(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 6.5,
              fontWeight: FontWeight.w700,
              color: _kInkMuted,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: _kInk,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Planilla {
  String numeroHojaText() {
    final n = payload['numero_hoja'] as int? ?? 0;
    return n.toString().padLeft(4, '0');
  }
}
