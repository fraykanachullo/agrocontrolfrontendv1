import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/despacho_aviso_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../../planillas/domain/entities/planilla.dart';
import '../../../planillas/presentation/planilla_routes.dart';
import '../../domain/entities/cosecha.dart';
import '../liquidacion_model.dart';
import '../widgets/sale_sheets.dart';
import 'liquidacion_screen.dart';

/// Detalle de un despacho o venta (RF-COS-13): datos, trazabilidad, carga
/// por calidad, evidencias y, si ya se liquidó, el resumen de la liquidación.
/// Corregir una venta ya liquidada: la venta en campo con su hoja simple; el
/// despacho, reabriendo la liquidación con los precios y descuentos guardados.
Future<void> corregirVenta(BuildContext context, Cosecha c) {
  if (c.tipoVenta == 'parcela') return showCorregirVentaCampo(context, c);
  return Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => LiquidacionScreen(cosecha: c)));
}

class DespachoScreen extends ConsumerWidget {
  final Cosecha cosecha;

  const DespachoScreen({super.key, required this.cosecha});

  /// Marca un paso del ciclo con la hora actual, con opción de deshacer.
  Future<void> _marcar(BuildContext context, WidgetRef ref, Cosecha c, EtapaDespacho paso, String hecho) async {
    final notifier = ref.read(cosechasProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    await notifier.marcarPaso(c.campanaId, c.id!, paso, DateTime.now());
    ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
    HapticFeedback.mediumImpact();
    messenger.showSnackBar(SnackBar(
      content: Text(hecho),
      action: SnackBarAction(
        label: 'Deshacer',
        onPressed: () async {
          await notifier.marcarPaso(c.campanaId, c.id!, paso, null);
          ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
        },
      ),
    ));
  }

  /// Botones del siguiente paso: el logístico (salida, llegada) arriba y la
  /// liquidación o el cobro como acción principal.
  Widget? _acciones(BuildContext context, WidgetRef ref, Cosecha c) {
    final etapa = c.etapa;
    if (etapa == EtapaDespacho.cobrado) return null;

    final siguiente = switch (etapa) {
      EtapaDespacho.anotado => AgroActionButton(
          label: 'Salió el camión',
          icon: Icons.local_shipping_rounded,
          onPressed: () => _marcar(context, ref, c, EtapaDespacho.enTransito, 'Despacho en camino'),
        ),
      EtapaDespacho.enTransito => AgroActionButton(
          label: 'Llegó al mercado',
          icon: Icons.storefront_rounded,
          onPressed: () => _marcar(context, ref, c, EtapaDespacho.recibido, 'Carga recibida en el mercado'),
        ),
      _ => null,
    };
    final principal = etapa == EtapaDespacho.liquidado
        ? AgroActionButton(
            label: 'Ya cobré ${formatSoles(c.montoNetoFinal ?? 0)}',
            icon: Icons.payments_rounded,
            primary: true,
            height: 56,
            onPressed: () => _marcar(context, ref, c, EtapaDespacho.cobrado, 'Despacho cobrado'),
          )
        : AgroActionButton(
            label: 'Registrar liquidación',
            icon: Icons.rate_review_rounded,
            primary: true,
            height: 56,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LiquidacionScreen(cosecha: c))),
          );

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (siguiente != null) ...[siguiente, const SizedBox(height: 8)],
          principal,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Versión vigente del despacho (cambia al liquidarlo).
    final cosechas = ref.watch(cosechasProvider);
    final c = [...cosechas.pendientes, ...cosechas.entregadas].where((x) => x.id == cosecha.id).firstOrNull ?? cosecha;
    final hoja = ref.watch(planillasProvider).planillas.where((p) => p.payload['despacho_id'] == c.id).firstOrNull;
    final campana = ref.watch(activeCampanaProvider);
    final view = _DespachoView(c, hoja, campana?.nombre, ref.watch(diasAvisoDespachoProvider));
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
                  Expanded(
                    child: Text(
                      view.enCampo ? 'Detalle de la venta' : 'Detalle del despacho',
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (c.isLiquidado) ...[
                    GlassCircleButton(
                      icon: Icons.edit_outlined,
                      tooltip: view.enCampo ? 'Corregir venta' : 'Corregir liquidación',
                      onPressed: () => corregirVenta(context, c),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Icon(c.isSynced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
                      size: 20, color: c.isSynced ? AppColors.accent : AppColors.warning),
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            view.encabezado(context),
            const SizedBox(height: 14),
            view.trazabilidad(context),
            const SizedBox(height: 14),
            view.carga(context),
            if (hoja?.payload['foto'] is String) ...[
              const SizedBox(height: 14),
              _FotoCard(titulo: 'Foto de la carga', ruta: hoja!.payload['foto'] as String),
            ],
            if (view.comisionista.isNotEmpty) ...[
              const SizedBox(height: 14),
              view.comisionistaCard(context),
            ],
            if (view.liquidado) ...[
              const SizedBox(height: 22),
              SectionHeader(title: view.enCampo ? 'Detalle de la venta' : 'Liquidación'),
              view.liquidacion(context),
            ],
          ],
        ),
        bottomNavigationBar: _acciones(context, ref, c),
      ),
    );
  }
}

/// Construye las secciones del detalle a partir del despacho y su hoja.
class _DespachoView {
  final Cosecha c;
  final Planilla? hoja;
  final String? campanaNombre;
  final int diasAviso;
  final List<CalidadCarga> calidades;

  _DespachoView(this.c, this.hoja, this.campanaNombre, this.diasAviso) : calidades = calidadesDe(c);

  bool get liquidado => c.isLiquidado;
  bool get enCampo => c.enCampo;
  String get envase => c.unidadEmpaque ?? 'java';
  int get anotado => calidades.fold(0, (s, l) => s + l.anotado);
  String get comisionista => (hoja?.payload['comisionista'] as String?) ?? '';

  Widget encabezado(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final partes = c.conductor.split(' · ');
    final placa = (hoja?.payload['placa'] as String?)?.isNotEmpty == true
        ? hoja!.payload['placa'] as String
        : (partes.length > 1 ? partes[1] : '');

    Widget dato(IconData icon, String label, String value) => Expanded(
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: AppColors.accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.labelSmall?.copyWith(fontSize: 10)),
                    Text(value.isEmpty ? '—' : value, style: text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
                          child: Text('#D-${(c.id ?? 0).toString().padLeft(3, '0')}', style: AppTheme.display(fontSize: 12, color: AppColors.textMuted)),
                        ),
                        const SizedBox(width: 6),
                        ShipmentStatusPill(cosecha: c),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(campanaNombre ?? 'Despacho', style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.storefront_outlined, size: 15, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(enCampo ? 'Venta en campo' : c.mercadoDestino,
                              style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(16)),
                child: Icon(enCampo ? Icons.scale_rounded : Icons.local_shipping_rounded, color: AppColors.accent, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.track.withValues(alpha: AppColors.palette.isDark ? 0.25 : 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                dato(Icons.person_outline_rounded, enCampo ? 'Comprador' : 'Chofer', partes.first),
                const SizedBox(width: 8),
                enCampo
                    ? dato(Icons.inventory_2_outlined, 'Carga', '$anotado ${envase}s')
                    : dato(Icons.pin_outlined, 'Placa', placa.toUpperCase()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget trazabilidad(BuildContext context) {
    final text = Theme.of(context).textTheme;
    String fecha(String? iso) {
      final d = DateTime.tryParse(iso ?? '');
      return d == null ? '' : DateFormat('EEE d MMM · HH:mm', 'es').format(d);
    }

    final cobro = nombreFormaCobro(c.liquidacion['forma_cobro'] as String?);
    final etapa = c.etapa;
    final dias = c.diasSinNoticias;
    final demorado = c.demorado(diasAviso);
    final mercado = c.mercadoDestino.isEmpty ? 'el mercado' : c.mercadoDestino;
    final neto = formatSoles(c.montoNetoFinal ?? 0);

    // Paso hecho si la etapa ya lo alcanzó; el siguiente es el que se espera.
    _Estado estado(EtapaDespacho e) => e.index <= etapa.index
        ? _Estado.hecho
        : (e.index == etapa.index + 1 ? _Estado.actual : _Estado.pendiente);

    final pasos = enCampo
        ? [
            _Paso('Vendido en campo', fecha(c.fechaEnvio), '$anotado ${envase}s', _Estado.hecho),
            etapa == EtapaDespacho.cobrado
                ? _Paso('Cobrado', fecha(c.fechaCobro), 'Pago recibido', _Estado.hecho)
                : _Paso('Cobrado', '', 'El comprador debe $neto', _Estado.actual),
          ]
        : [
            _Paso('Anotado en campo', fecha(c.fechaEnvio), '$anotado ${envase}s cargadas', _Estado.hecho),
            _Paso(
              'Salió el camión',
              fecha(c.fechaSalida),
              estado(EtapaDespacho.enTransito) == _Estado.hecho ? 'Rumbo a $mercado' : 'Márcalo cuando el camión salga',
              estado(EtapaDespacho.enTransito),
              alerta: demorado && etapa == EtapaDespacho.anotado,
            ),
            _Paso(
              'Llegó al mercado',
              fecha(c.fechaRecepcion),
              switch (estado(EtapaDespacho.recibido)) {
                _Estado.hecho => 'Recibido en $mercado',
                _ when demorado => 'Lleva $dias días sin noticias. Llama al comisionista',
                _ when dias != null && etapa == EtapaDespacho.enTransito => 'Lleva $dias día${dias == 1 ? '' : 's'} en camino',
                _ => 'Cuando el comisionista confirme que llegó',
              },
              estado(EtapaDespacho.recibido),
              alerta: demorado && etapa == EtapaDespacho.enTransito,
            ),
            _Paso(
              'Liquidado por el comisionista',
              fecha(c.fechaLiquidacion),
              liquidado ? 'Neto: $neto${c.liquidacion.isEmpty ? '' : ' · $cobro'}' : 'Registra los precios y descuentos que te envíe',
              estado(EtapaDespacho.liquidado),
            ),
            _Paso(
              'Cobrado',
              fecha(c.fechaCobro),
              etapa == EtapaDespacho.cobrado
                  ? 'Pago recibido${c.liquidacion.isEmpty ? '' : ' · $cobro'}'
                  : (liquidado ? 'Esperando el pago de $neto' : 'Cuando recibas el dinero'),
              estado(EtapaDespacho.cobrado),
            ),
          ];
    final hechos = pasos.where((p) => p.estado == _Estado.hecho).length;

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(child: Text('Trazabilidad', style: text.titleSmall)),
              Text('Paso ${(hechos + (hechos < pasos.length ? 1 : 0)).clamp(1, pasos.length)} de ${pasos.length}', style: text.labelSmall),
            ],
          ),
          const SizedBox(height: 14),
          for (final (i, p) in pasos.indexed) _PasoTile(paso: p, ultimo: i == pasos.length - 1),
        ],
      ),
    );
  }

  Widget carga(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colores = [AppColors.accent, AppColors.info, AppColors.warning, AppColors.textMuted, AppColors.expense, AppColors.textSubtle];
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(child: Text(c.detalles.isEmpty ? 'Carga' : 'Carga y calidades', style: text.titleSmall)),
              if (hoja != null) Text('${(hoja!.payload['filas'] as List?)?.length ?? 0} filas', style: text.labelSmall),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(enCampo ? 'Carga vendida' : 'Carga despachada', style: text.labelSmall),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '$anotado', style: AppTheme.display(fontSize: 26, color: AppColors.accent)),
                            TextSpan(text: ' ${envase}s', style: text.labelLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (c.pesoTotalKg != null && c.pesoTotalKg! > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Peso en balanza', style: text.labelSmall),
                      Text('${NumberFormat('#,##0', 'es_419').format(c.pesoTotalKg)} kg', style: text.titleSmall),
                    ],
                  ),
              ],
            ),
          ),
          if (c.detalles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (i, l) in calidades.indexed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: colores[i % colores.length], shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('${l.nombre} (${l.simbolo}): ', style: text.labelMedium?.copyWith(color: AppColors.text)),
                        Text('${l.anotado}', style: AppTheme.display(fontSize: 13, color: colores[i % colores.length])),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (hoja != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => openPlanilla(
                context,
                campanaId: hoja!.campanaId,
                cultivo: hoja!.cultivo,
                numeroHoja: (hoja!.payload['numero_hoja'] as int?) ?? 0,
                planilla: hoja,
              ),
              icon: const Icon(Icons.grid_on_rounded, size: 18),
              label: const Text('Ver hoja de anotación completa'),
            ),
          ],
        ],
      ),
    );
  }

  Widget comisionistaCard(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.handshake_outlined, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comisionista en destino', style: text.labelSmall),
                Text(comisionista, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                Text(c.mercadoDestino, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Resumen de una liquidación guardada: calidades, deducciones y neto.
  Widget liquidacion(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final d = (c.liquidacion['descuentos'] as Map?)?.map((k, v) => MapEntry('$k', (v as num).toDouble())) ?? const {};
    final vendido = calidades.fold<int>(0, (s, l) => s + l.vendidoEfectivo);
    final merma = anotado - vendido;
    final bruto = (c.montoNetoFinal ?? 0) + (c.descuentosLogistica ?? 0);
    final comprobante = c.liquidacion['comprobante'] as String?;

    Widget linea(String label, double valor, {bool negativo = false, bool fuerte = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(label, style: fuerte ? text.titleSmall : text.bodyMedium)),
              Text(
                '${negativo ? '-' : ''}${formatSoles(valor)}',
                style: AppTheme.display(fontSize: fuerte ? 20 : 14, color: negativo ? AppColors.expense : (fuerte ? AppColors.positive : AppColors.text)),
              ),
            ],
          ),
        );

    return Column(
      children: [
        GlassCard(
          radius: 20,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text('Calidad', style: text.labelSmall)),
                  SizedBox(width: 44, child: Text('Anot.', textAlign: TextAlign.center, style: text.labelSmall)),
                  SizedBox(width: 44, child: Text('Vend.', textAlign: TextAlign.center, style: text.labelSmall)),
                  SizedBox(width: 72, child: Text('Precio', textAlign: TextAlign.end, style: text.labelSmall)),
                  SizedBox(width: 82, child: Text('Subtotal', textAlign: TextAlign.end, style: text.labelSmall)),
                ],
              ),
              const Divider(height: 16),
              for (final l in calidades)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(l.nombre, style: text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      SizedBox(width: 44, child: Text('${l.anotado}', textAlign: TextAlign.center, style: AppTheme.display(fontSize: 13, color: AppColors.textMuted))),
                      SizedBox(
                        width: 44,
                        child: Text('${l.vendidoEfectivo}',
                            textAlign: TextAlign.center,
                            style: AppTheme.display(fontSize: 13, color: l.merma > 0 ? AppColors.warning : AppColors.accent)),
                      ),
                      SizedBox(width: 72, child: Text(l.precio == null ? '—' : formatSoles(l.precio!), textAlign: TextAlign.end, style: AppTheme.display(fontSize: 13, color: AppColors.text))),
                      SizedBox(
                        width: 82,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(formatSoles(l.subtotal), style: AppTheme.display(fontSize: 13, color: AppColors.positive)),
                        ),
                      ),
                    ],
                  ),
                ),
              if (merma > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '⚠ $merma ${envase}s de merma (${(merma / anotado * 100).toStringAsFixed(1)}%)',
                    style: text.labelMedium?.copyWith(color: AppColors.warning),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          highlight: true,
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              linea('Venta bruta ($vendido ${envase}s)', bruto),
              if (d.isEmpty && (c.descuentosLogistica ?? 0) > 0) linea('Deducciones', c.descuentosLogistica!, negativo: true),
              if ((d['comision'] ?? 0) > 0)
                linea('Comisión${(d['comision_pct'] ?? 0) > 0 ? ' (${_num(d['comision_pct']!)}%)' : ''}', d['comision']!, negativo: true),
              if ((d['flete'] ?? 0) > 0) linea('Flete', d['flete']!, negativo: true),
              if ((d['descarga'] ?? 0) > 0) linea('Descarga y estiba', d['descarga']!, negativo: true),
              if ((d['relleno'] ?? 0) > 0) linea('Relleno / reposición', d['relleno']!, negativo: true),
              if ((d['otros'] ?? 0) > 0) linea('Otros', d['otros']!, negativo: true),
              const Divider(height: 18),
              linea(enCampo ? 'Total cobrado' : (c.etapa == EtapaDespacho.cobrado ? 'Neto recibido' : 'Neto por cobrar'), c.montoNetoFinal ?? 0, fuerte: true),
              if (c.liquidacion['forma_cobro'] != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Cobro: ${nombreFormaCobro(c.liquidacion['forma_cobro'] as String?)}', style: text.labelSmall),
                ),
            ],
          ),
        ),
        if (comprobante != null) ...[
          const SizedBox(height: 12),
          _FotoCard(titulo: 'Comprobante del comisionista', ruta: comprobante),
        ],
      ],
    );
  }

  static String _num(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
}

// ═══════════════════════════════════════════════
//  Piezas
// ═══════════════════════════════════════════════

class _FotoCard extends StatelessWidget {
  final String titulo;
  final String ruta;

  const _FotoCard({required this.titulo, required this.ruta});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final file = File(ruta);
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library_outlined, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(titulo, style: text.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: file.existsSync()
                ? GestureDetector(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(child: InteractiveViewer(child: Image.file(file))),
                    ),
                    child: Image.file(file, height: 150, width: double.infinity, fit: BoxFit.cover),
                  )
                : Container(
                    height: 80,
                    color: AppColors.accentSoft,
                    alignment: Alignment.center,
                    child: Text('La foto ya no está en el teléfono', style: text.bodySmall),
                  ),
          ),
        ],
      ),
    );
  }
}

enum _Estado { hecho, actual, pendiente }

class _Paso {
  final String titulo;
  final String cuando;
  final String detalle;
  final _Estado estado;
  final bool alerta;

  const _Paso(this.titulo, this.cuando, this.detalle, this.estado, {this.alerta = false});
}

class _PasoTile extends StatelessWidget {
  final _Paso paso;
  final bool ultimo;

  const _PasoTile({required this.paso, required this.ultimo});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = paso.alerta ? AppColors.warning : AppColors.accent;
    final hecho = paso.estado == _Estado.hecho;
    final actual = paso.estado == _Estado.actual;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: hecho ? color : AppColors.accentSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: hecho || actual ? color : AppColors.outlineVariant),
                    boxShadow: actual ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12)] : null,
                  ),
                  child: hecho
                      ? Icon(Icons.check_rounded, size: 16, color: AppColors.onAccent)
                      : actual
                          ? Center(child: Container(width: 11, height: 11, decoration: BoxDecoration(color: color, shape: BoxShape.circle)))
                          : Icon(Icons.more_horiz_rounded, size: 15, color: AppColors.textSubtle),
                ),
                if (!ultimo)
                  Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 2), color: hecho ? color : AppColors.outlineVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: ultimo ? 0 : 14),
              padding: actual ? const EdgeInsets.all(10) : EdgeInsets.zero,
              decoration: actual ? BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)) : null,
              child: Opacity(
                opacity: paso.estado == _Estado.pendiente ? 0.6 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            paso.titulo,
                            style: text.titleSmall?.copyWith(
                              color: actual ? color : AppColors.text,
                              fontWeight: actual ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (paso.cuando.isNotEmpty)
                          Text(paso.cuando, style: text.labelSmall?.copyWith(color: hecho || actual ? color : AppColors.textSubtle)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(paso.detalle, style: text.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Píldora de estado de un despacho o venta según su etapa.
class ShipmentStatusPill extends ConsumerWidget {
  final Cosecha cosecha;

  const ShipmentStatusPill({super.key, required this.cosecha});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demorado = cosecha.demorado(ref.watch(diasAvisoDespachoProvider));
    final (label, icon, color) = switch (cosecha.etapa) {
      _ when demorado => ('Demorado', Icons.warning_amber_rounded, AppColors.error),
      EtapaDespacho.anotado => ('Anotado', Icons.edit_note_rounded, AppColors.textMuted),
      EtapaDespacho.enTransito => ('En camino', Icons.local_shipping_rounded, AppColors.info),
      EtapaDespacho.recibido => ('En el mercado', Icons.storefront_rounded, AppColors.info),
      EtapaDespacho.liquidado => ('Por cobrar', Icons.schedule_rounded, AppColors.warning),
      EtapaDespacho.cobrado => ('Cobrado', Icons.task_alt_rounded, AppColors.positive),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
