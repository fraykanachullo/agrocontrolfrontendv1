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
import '../../../cuaderno/data/datasources/evidencia_local_datasource.dart';
import '../../domain/entities/cosecha.dart';
import '../liquidacion_model.dart';

/// Línea editable: una calidad con sus javas vendidas y su precio.
class _Linea {
  final CalidadCarga calidad;
  final TextEditingController vendidoCtrl;
  final TextEditingController precioCtrl = TextEditingController();

  _Linea(this.calidad) : vendidoCtrl = TextEditingController(text: '${calidad.anotado}');

  int get vendido => (int.tryParse(vendidoCtrl.text) ?? 0).clamp(0, calidad.anotado);
  int get merma => calidad.anotado - vendido;
  double get precio => AmountInput.parse(precioCtrl);
  double get subtotal => vendido * precio;

  void dispose() {
    vendidoCtrl.dispose();
    precioCtrl.dispose();
  }
}

/// Registrar la liquidación del comisionista (RF-COS-14 a RF-COS-17):
/// vendido y precio por calidad, merma, deducciones, forma de cobro y comprobante.
class LiquidacionScreen extends ConsumerStatefulWidget {
  final Cosecha cosecha;

  const LiquidacionScreen({super.key, required this.cosecha});

  @override
  ConsumerState<LiquidacionScreen> createState() => _LiquidacionScreenState();
}

class _LiquidacionScreenState extends ConsumerState<LiquidacionScreen> {
  late final List<_Linea> _lineas = calidadesDe(widget.cosecha).map(_Linea.new).toList();
  final _comisionCtrl = TextEditingController();
  final _fleteCtrl = TextEditingController();
  final _descargaCtrl = TextEditingController();
  final _rellenoCtrl = TextEditingController();
  final _otrosCtrl = TextEditingController();
  String _formaCobro = formasCobro.first.$1;
  bool _cobrado = false;
  File? _comprobante;
  bool _saving = false;

  Cosecha get _c => widget.cosecha;
  String get _envase => _c.unidadEmpaque ?? 'java';

  int get _anotado => _lineas.fold(0, (s, l) => s + l.calidad.anotado);
  int get _vendido => _lineas.fold(0, (s, l) => s + l.vendido);
  int get _merma => _anotado - _vendido;
  double get _mermaPct => _anotado == 0 ? 0 : _merma / _anotado * 100;
  double get _bruto => _lineas.fold(0, (s, l) => s + l.subtotal);
  double get _comision => _bruto * AmountInput.parse(_comisionCtrl) / 100;
  double get _flete => AmountInput.parse(_fleteCtrl);
  double get _descarga => AmountInput.parse(_descargaCtrl);
  double get _relleno => AmountInput.parse(_rellenoCtrl);
  double get _otros => AmountInput.parse(_otrosCtrl);
  double get _deducciones => _comision + _flete + _descarga + _relleno + _otros;
  double get _neto => _bruto - _deducciones;

  @override
  void dispose() {
    for (final l in _lineas) {
      l.dispose();
    }
    for (final c in [_comisionCtrl, _fleteCtrl, _descargaCtrl, _rellenoCtrl, _otrosCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _foto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 75, maxWidth: 1600);
    if (picked == null) return;
    final saved = await EvidenciaLocalDatasource().copyToEvidencias(picked.path);
    if (mounted) setState(() => _comprobante = saved);
  }

  Future<void> _guardar() async {
    if (_lineas.any((l) => l.vendido > 0 && l.precio <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta el precio de alguna calidad vendida')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final sinDetalle = _c.detalles.isEmpty;
      await ref.read(cosechasProvider.notifier).liquidarCosecha(
        _c.campanaId,
        _c.id!,
        detallesPrecios: [
          if (!sinDetalle)
            for (final l in _lineas) {'categoria': l.calidad.clave, 'precio_venta': l.precio},
        ],
        precioUnitarioGlobal: sinDetalle ? _lineas.first.precio : null,
        descuentosLogistica: _deducciones,
        vendidos: {for (final l in _lineas) l.calidad.clave: l.vendido},
        detalle: {
          'vendidos': {for (final l in _lineas) l.calidad.clave: l.vendido},
          'bruto': _bruto,
          'descuentos': {
            'comision_pct': AmountInput.parse(_comisionCtrl),
            'comision': _comision,
            'flete': _flete,
            'descarga': _descarga,
            'relleno': _relleno,
            'otros': _otros,
          },
          'forma_cobro': _formaCobro,
          'comprobante': ?_comprobante?.path,
        },
        cobrado: _cobrado,
      );
      ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
      HapticFeedback.mediumImpact();
      navigator.pop(true);
      messenger.showSnackBar(SnackBar(
        content: Text('Liquidación guardada: ${formatSoles(_neto)}${_cobrado ? '' : ' por cobrar'}'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                  Text('Registrar liquidación', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _encabezado(text),
            const SizedBox(height: 12),
            PhotoPickerTile(
              photo: _comprobante,
              title: 'Liquidación del comisionista',
              hint: 'Foto del papel o mensaje que te envió',
              onPick: _foto,
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Cierre de calidades'),
            _calidades(text),
            const SizedBox(height: 18),
            SectionHeader(title: 'Deducciones comerciales', actionLabel: _deducciones > 0 ? '-${formatSoles(_deducciones)}' : null),
            _deduccionesCard(text),
            const SizedBox(height: 18),
            _ticket(text),
            const SizedBox(height: 18),
            const SectionHeader(title: '¿Cómo te pagan?'),
            OptionTiles<String>(options: formasCobro, selected: _formaCobro, onSelected: (v) => setState(() => _formaCobro = v)),
            const SizedBox(height: 18),
            const SectionHeader(title: '¿Ya recibiste el dinero?'),
            OptionTiles<bool>(
              options: const [
                (false, 'Aún no', Icons.hourglass_top_rounded),
                (true, 'Sí, ya cobré', Icons.check_circle_rounded),
              ],
              selected: _cobrado,
              onSelected: (v) => setState(() => _cobrado = v),
              colorOf: (v) => v ? AppColors.positive : AppColors.warning,
            ),
            if (!_cobrado)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text('Queda "por cobrar" hasta que marques que llegó el pago.', style: text.bodySmall),
              ),
          ],
        ),
        bottomNavigationBar: RecordSaveBar(label: 'Guardar liquidación', saving: _saving, onSave: _guardar, total: _neto),
      ),
    );
  }

  Widget _encabezado(TextTheme text) {
    final campana = ref.watch(activeCampanaProvider);
    final comisionista = ref
            .watch(planillasProvider)
            .planillas
            .where((p) => p.payload['despacho_id'] == _c.id)
            .map((p) => p.payload['comisionista'] as String?)
            .firstOrNull ??
        '';

    Widget dato(String label, String value, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelSmall?.copyWith(fontSize: 10)),
              Text(value, style: AppTheme.display(fontSize: 13, color: color)),
            ],
          ),
        );

    return GlassCard(
      highlight: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DESPACHO #${(_c.id ?? 0).toString().padLeft(3, '0')}',
                  style: text.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.accent),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
                child: Text('$_anotado ${_envase}s enviadas', style: text.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(campana?.nombre ?? 'Despacho', style: text.titleLarge),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.storefront_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  [if (comisionista.isNotEmpty) comisionista, _c.mercadoDestino].join(' · '),
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.track.withValues(alpha: AppColors.palette.isDark ? 0.25 : 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                dato('Vendido', '$_vendido ${_envase}s', AppColors.accent),
                dato('Merma', '$_merma (${_mermaPct.toStringAsFixed(1)}%)', _merma > 0 ? AppColors.warning : AppColors.text),
                dato('Comprobante', _comprobante == null ? 'Sin foto' : 'Adjunto', _comprobante == null ? AppColors.textSubtle : AppColors.positive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calidades(TextTheme text) {
    InputDecoration deco(String? prefix) => InputDecoration(
          isDense: true,
          prefixText: prefix,
          hintText: '0',
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        );

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Calidad', style: text.labelSmall)),
              SizedBox(width: 36, child: Text('Anot.', textAlign: TextAlign.center, style: text.labelSmall)),
              SizedBox(width: 58, child: Text('Vend.', textAlign: TextAlign.center, style: text.labelSmall)),
              SizedBox(width: 78, child: Text('Precio', textAlign: TextAlign.center, style: text.labelSmall)),
              SizedBox(width: 74, child: Text('Subtotal', textAlign: TextAlign.end, style: text.labelSmall)),
            ],
          ),
          const Divider(height: 16),
          for (final l in _lineas)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l.calidad.nombre} (${l.calidad.simbolo})', style: text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          l.merma > 0 ? '⚠ ${l.merma} de merma' : 'Sin merma',
                          style: text.labelSmall?.copyWith(fontSize: 10, color: l.merma > 0 ? AppColors.warning : AppColors.textSubtle),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text('${l.calidad.anotado}', textAlign: TextAlign.center, style: AppTheme.display(fontSize: 13, color: AppColors.textMuted)),
                  ),
                  SizedBox(
                    width: 58,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: TextField(
                        controller: l.vendidoCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: AppTheme.display(fontSize: 14, color: AppColors.accent),
                        decoration: deco(null),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: TextField(
                        controller: l.precioCtrl,
                        textAlign: TextAlign.end,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        style: AppTheme.display(fontSize: 14, color: AppColors.text),
                        decoration: deco('S/'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 74,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(formatSoles(l.subtotal), style: AppTheme.display(fontSize: 13, color: AppColors.positive)),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(_merma > 0 ? Icons.warning_amber_rounded : Icons.verified_outlined, size: 20, color: _merma > 0 ? AppColors.warning : AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _merma == 0
                        ? 'Se vendió todo lo anotado'
                        : '$_merma ${_envase}s de merma total (${_mermaPct.toStringAsFixed(1)}%)',
                    style: text.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deduccionesCard(TextTheme text) {
    Widget fila(String label, String caption, TextEditingController ctrl, {String? prefix, String? suffix, String? hint, double? valor}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.titleSmall),
                    Text(valor != null && valor > 0 ? '= ${formatSoles(valor)} · $caption' : caption, style: text.labelSmall),
                  ],
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: ctrl,
                  textAlign: TextAlign.end,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: InputDecoration(isDense: true, prefixText: prefix, suffixText: suffix, hintText: hint ?? '0'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        );

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        children: [
          fila('Comisión', 'Sobre la venta bruta', _comisionCtrl, suffix: ' %', hint: '8', valor: _comision),
          fila('Flete', 'Pago al chofer o al camión', _fleteCtrl, prefix: 'S/ '),
          fila('Descarga y estiba', 'Cuadrilla del mercado', _descargaCtrl, prefix: 'S/ '),
          fila('Relleno / reposición', '${_envase[0].toUpperCase()}${_envase.substring(1)}s para rellenar o rotas', _rellenoCtrl, prefix: 'S/ '),
          fila('Otros', 'Cualquier otro descuento', _otrosCtrl, prefix: 'S/ '),
        ],
      ),
    );
  }

  /// Recibo con muescas laterales y línea perforada.
  Widget _ticket(TextTheme text) {
    final neto = formatSoles(_neto.abs());
    final dot = neto.lastIndexOf('.');
    final fondo = AppColors.background;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassCard(
          highlight: true,
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text('Recibo de liquidación', style: text.titleSmall),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Venta bruta ($_vendido ${_envase}s)', style: text.bodyMedium)),
                  Text('+${formatSoles(_bruto)}', style: AppTheme.display(fontSize: 15, color: AppColors.text)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: Text('Deducciones', style: text.bodyMedium?.copyWith(color: AppColors.expense))),
                  Text('-${formatSoles(_deducciones)}', style: AppTheme.display(fontSize: 15, color: AppColors.expense)),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) => Row(
                  children: [
                    for (var i = 0; i < c.maxWidth ~/ 10; i++)
                      Container(width: 6, height: 2, margin: const EdgeInsets.only(right: 4), color: AppColors.outlineVariant),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'NETO A RECIBIR',
                      style: text.labelMedium?.copyWith(color: AppColors.textMuted, letterSpacing: 1.2, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${_neto < 0 ? '-' : ''}${neto.substring(0, dot)}'),
                        TextSpan(text: neto.substring(dot), style: AppTheme.display(fontSize: 18, color: AppColors.textMuted)),
                      ],
                    ),
                    style: AppTheme.display(fontSize: 28, color: _neto < 0 ? AppColors.expense : AppColors.positive),
                  ),
                ],
              ),
              if (_vendido > 0 && _bruto > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Neto por $_envase vendida: ${formatSoles(_neto / _vendido)}', style: text.labelSmall),
                ),
            ],
          ),
        ),
        // Muescas del recibo a la altura de la línea perforada.
        for (final left in [true, false])
          Positioned(
            top: 108,
            left: left ? -10 : null,
            right: left ? null : -10,
            child: Container(width: 20, height: 20, decoration: BoxDecoration(color: fondo, shape: BoxShape.circle)),
          ),
      ],
    );
  }
}
