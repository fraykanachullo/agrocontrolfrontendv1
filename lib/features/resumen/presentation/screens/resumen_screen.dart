import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../../campanas/domain/entities/campana.dart';
import '../../../campanas/presentation/campaign_actions.dart';
import '../../../campanas/presentation/campaign_display.dart';
import '../../../cosechas/domain/entities/cosecha.dart';

final _amount = NumberFormat('#,##0.00', 'es_419');
final _count = NumberFormat('#,##0', 'es_419');

String _soles(double v) => 'S/ ${_amount.format(v)}';

/// Cifras del resumen derivadas de los datos de la campaña.
class _Figures {
  final double gastos;
  final double ingresosDirectos;
  final double ventasNetas;
  final double descuentos;
  final int bultos;
  final int ventas;
  final String unidad;

  const _Figures({
    required this.gastos,
    required this.ingresosDirectos,
    required this.ventasNetas,
    required this.descuentos,
    required this.bultos,
    required this.ventas,
    required this.unidad,
  });

  factory _Figures.from(Map<String, dynamic>? data, List<Cosecha> liquidadas) {
    final ventasNetas = liquidadas.fold<double>(0, (s, c) => s + (c.montoNetoFinal ?? c.montoNetoCalculado));
    final totalIngresos = (data?['total_ingresos'] as double?) ?? 0;
    return _Figures(
      gastos: (data?['total_gastos'] as double?) ?? 0,
      ingresosDirectos: (totalIngresos - ((data?['ingresos_ventas'] as double?) ?? 0)).clamp(0, double.infinity),
      ventasNetas: ventasNetas,
      descuentos: liquidadas.fold<double>(0, (s, c) => s + (c.descuentosLogistica ?? 0)),
      bultos: liquidadas.fold<int>(0, (s, c) => s + c.cantidadUnidades),
      ventas: liquidadas.length,
      unidad: liquidadas.map((c) => c.unidadEmpaque).whereType<String>().firstOrNull ?? 'bulto',
    );
  }

  double get ventasBrutas => ventasNetas + descuentos;
  double get ingresos => ventasNetas + ingresosDirectos;
  double get utilidad => ingresos - gastos;
  double? get rentabilidad => gastos > 0 ? utilidad / gastos * 100 : null;
  double? get retornoPorSol => gastos > 0 ? ingresos / gastos : null;
  double? get costoPorBulto => bultos > 0 ? gastos / bultos : null;
  double? get ventaPorBulto => bultos > 0 ? ventasNetas / bultos : null;
}

class ResumenScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const ResumenScreen({super.key, required this.campaignId});

  @override
  ConsumerState<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends ConsumerState<ResumenScreen> {
  @override
  void initState() {
    super.initState();
    final id = int.tryParse(widget.campaignId);
    if (id != null) Future.microtask(() => ref.read(cosechasProvider.notifier).loadData(id));
  }

  @override
  Widget build(BuildContext context) {
    final campana = ref.watch(activeCampanaProvider);
    if (campana == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final cosechas = ref.watch(cosechasProvider);
    final f = _Figures.from(ref.watch(dashboardDataProvider).value, cosechas.entregadas);
    List<(String, double)> rows(List<Map<String, dynamic>>? data, String key) => [
          for (final m in data ?? const <Map<String, dynamic>>[])
            (_label(m[key] as String?), (m['total'] as num).toDouble()),
        ];
    final categorias = rows(ref.watch(gastosPorCategoriaProvider).value, 'categoria');
    final etapas = rows(ref.watch(gastosPorEtapaProvider).value, 'etapa');

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        _Header(campana: campana),
        const SizedBox(height: 16),
        _VerdictCard(campana: campana, f: f),
        if (cosechas.pendientes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _PendingNotice(count: cosechas.pendientes.length),
        ],
        const SizedBox(height: 24),
        const SectionHeader(title: 'Desglose de la campaña'),
        _Breakdown(f: f),
        const SizedBox(height: 24),
        SectionHeader(title: 'Métricas por ${f.unidad}'),
        _UnitMetrics(f: f, campana: campana),
        const SizedBox(height: 24),
        const SectionHeader(title: '¿En qué se va la plata?'),
        _ExpenseBars(rows: categorias, total: f.gastos),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Gasto por etapa del cultivo'),
        _ExpenseBars(rows: etapas, total: f.gastos),
        const SizedBox(height: 24),
        AgroActionButton(
          label: 'Compartir resumen por WhatsApp',
          icon: Icons.share_rounded,
          primary: true,
          height: 56,
          onPressed: () => _share(campana, f),
        ),
        const SizedBox(height: 10),
        AgroActionButton(
          label: 'Ver historial completo',
          icon: Icons.calendar_month_rounded,
          height: 54,
          onPressed: () => context.go('/c/${campana.id}/historial'),
        ),
        const SizedBox(height: 10),
        if (campana.isActive)
          TextButton.icon(
            onPressed: () => closeCampanaFlow(context, ref, campana),
            icon: Icon(Icons.lock_outline_rounded, color: AppColors.error),
            label: Text('Cerrar campaña', style: TextStyle(color: AppColors.error)),
          )
        else
          TextButton.icon(
            onPressed: () => context.push('/nueva-campana'),
            icon: const Icon(Icons.eco_rounded),
            label: const Text('Iniciar nueva campaña'),
          ),
      ],
    );
  }

  Future<void> _share(Campana campana, _Figures f) {
    final text = StringBuffer()
      ..writeln('🌱 *${campana.nombre}* (${campana.cultivo}, ${campana.extensionDisplay})')
      ..writeln()
      ..writeln('Ingresos: ${_soles(f.ingresos)}')
      ..writeln('Gastos: ${_soles(f.gastos)}')
      ..writeln('*Utilidad neta: ${f.utilidad < 0 ? '-' : ''}${_soles(f.utilidad.abs())}*');
    if (f.rentabilidad != null) text.writeln('Rentabilidad: ${f.rentabilidad!.toStringAsFixed(1)}%');
    if (f.bultos > 0) text.writeln('${_count.format(f.bultos)} ${f.unidad}s vendidos');
    text
      ..writeln()
      ..write('Enviado desde AgroControl');
    return SharePlus.instance.share(ShareParams(text: text.toString()));
  }
}

// ═══════════════════════════════════════════════
//  Secciones
// ═══════════════════════════════════════════════

class _Header extends StatelessWidget {
  final Campana campana;

  const _Header({required this.campana});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = campana.isClosed ? AppColors.textMuted : AppColors.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                campana.isClosed ? 'RESULTADO FINAL' : 'RESULTADO PARCIAL',
                style: text.labelSmall?.copyWith(color: AppColors.accent, letterSpacing: 1.2, fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(campana.isClosed ? Icons.check_circle_rounded : Icons.timelapse_rounded, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    campana.isClosed ? 'Campaña cerrada' : 'Campaña en curso',
                    style: text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('${cropEmoji(campana.cultivo)} ${campana.nombre}', style: text.headlineSmall),
        const SizedBox(height: 2),
        Text(
          [
            campana.cultivo,
            campana.extensionDisplay,
            if (campana.fechaInicio != null) 'desde ${DateFormat('d MMM yyyy', 'es').format(campana.fechaInicio!)}',
          ].join(' · '),
          style: text.bodySmall,
        ),
      ],
    );
  }
}

/// Veredicto: ¿me fue bien o mal?
class _VerdictCard extends StatelessWidget {
  final Campana campana;
  final _Figures f;

  const _VerdictCard({required this.campana, required this.f});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sinVentas = f.ingresos == 0;
    final gano = f.utilidad >= 0;

    final (Color color, IconData icon, String titulo, String mensaje) = switch ((sinVentas, gano)) {
      (true, _) => (
          AppColors.warning,
          Icons.hourglass_top_rounded,
          'AÚN SIN VENTAS',
          'El resultado se irá formando con cada venta y liquidación. Por ahora llevas invertido ${_soles(f.gastos)}.',
        ),
      (false, true) => (
          AppColors.positive,
          Icons.sentiment_satisfied_alt_rounded,
          campana.isClosed ? '¡BUENA CAMPAÑA!' : 'VAS GANANDO',
          'Por cada S/ 1 invertido recuperaste S/ ${f.retornoPorSol?.toStringAsFixed(2) ?? '—'}.',
        ),
      (false, false) => (
          AppColors.expense,
          Icons.sentiment_dissatisfied_rounded,
          campana.isClosed ? 'CAMPAÑA EN PÉRDIDA' : 'AÚN EN PÉRDIDA',
          'Faltan ${_soles(f.utilidad.abs())} para recuperar lo invertido.',
        ),
    };

    return GlassCard(
      highlight: true,
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10)],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(titulo, style: text.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w800))),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(mensaje, style: text.bodyMedium),
          const SizedBox(height: 14),
          Text('UTILIDAD NETA', style: text.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${f.utilidad < 0 ? '-' : ''}${_soles(f.utilidad.abs())}',
              style: AppTheme.display(fontSize: 34, color: sinVentas ? AppColors.text : color),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                icon: Icons.percent_rounded,
                label: 'Rentabilidad',
                value: f.rentabilidad == null ? '—' : '${f.rentabilidad!.toStringAsFixed(1)}%',
              ),
              _Chip(
                icon: Icons.paid_outlined,
                label: 'Retorno',
                value: f.retornoPorSol == null ? '—' : '${f.retornoPorSol!.toStringAsFixed(2)}x',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Chip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.accent),
          const SizedBox(width: 5),
          Text('$label: ', style: text.labelMedium),
          Text(value, style: AppTheme.display(fontSize: 13, color: AppColors.text)),
        ],
      ),
    );
  }
}

class _PendingNotice extends StatelessWidget {
  final int count;

  const _PendingNotice({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count despacho${count == 1 ? '' : 's'} por liquidar: el resultado todavía puede cambiar.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Desglose tipo recibo: ventas brutas − descuentos − inversión = utilidad.
class _Breakdown extends StatelessWidget {
  final _Figures f;

  const _Breakdown({required this.f});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _Line(
            icon: Icons.storefront_outlined,
            title: 'Ventas de cosecha',
            subtitle: f.ventas == 0
                ? 'Sin ventas liquidadas'
                : '${f.ventas} venta${f.ventas == 1 ? '' : 's'} · ${_count.format(f.bultos)} ${f.unidad}s',
            amount: f.ventasBrutas,
          ),
          if (f.ingresosDirectos > 0)
            _Line(
              icon: Icons.savings_outlined,
              title: 'Ingresos directos',
              subtitle: 'Ventas menores y otros ingresos',
              amount: f.ingresosDirectos,
            ),
          _Line(
            icon: Icons.handshake_outlined,
            title: 'Comisión y flete',
            subtitle: 'Descontado en las liquidaciones',
            amount: -f.descuentos,
          ),
          _Line(
            icon: Icons.agriculture_outlined,
            title: 'Inversión en campo',
            subtitle: 'Jornales, insumos, maquinaria…',
            amount: -f.gastos,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Te queda', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
                Text(
                  '${f.utilidad < 0 ? '-' : ''}${_soles(f.utilidad.abs())}',
                  style: AppTheme.display(fontSize: 18, color: f.utilidad < 0 ? AppColors.expense : AppColors.positive),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;

  const _Line({required this.icon, required this.title, required this.subtitle, required this.amount});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final negative = amount < 0;
    final color = negative ? AppColors.expense : AppColors.positive;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.13), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                Text(subtitle, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(
            '${negative ? '- ' : '+ '}${_soles(amount.abs())}',
            style: AppTheme.display(fontSize: 14, color: amount == 0 ? AppColors.textMuted : color),
          ),
        ],
      ),
    );
  }
}

/// Métricas unitarias 2×2: costo, venta, margen y rendimiento por bulto.
class _UnitMetrics extends StatelessWidget {
  final _Figures f;
  final Campana campana;

  const _UnitMetrics({required this.f, required this.campana});

  @override
  Widget build(BuildContext context) {
    final costo = f.costoPorBulto;
    final venta = f.ventaPorBulto;
    final margen = (costo != null && venta != null) ? venta - costo : null;
    final unidadArea = campana.tipoExtension == 'hectarea' ? 'ha' : 'topo';
    final rendimiento = (f.bultos > 0 && campana.extension > 0) ? f.bultos / campana.extension : null;
    String money(double? v) => v == null ? '—' : _soles(v);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        _MetricCard(
          icon: Icons.inventory_2_outlined,
          label: 'Costo por ${f.unidad}',
          value: money(costo),
          caption: 'Tu precio de equilibrio',
        ),
        _MetricCard(
          icon: Icons.point_of_sale_outlined,
          label: 'Venta promedio',
          value: money(venta),
          caption: 'Neto por ${f.unidad}',
          color: AppColors.positive,
        ),
        _MetricCard(
          icon: Icons.savings_outlined,
          label: 'Margen',
          value: margen == null ? '—' : '${margen < 0 ? '-' : '+'}${_soles(margen.abs())}',
          caption: 'Ganancia por ${f.unidad}',
          color: margen == null ? null : (margen < 0 ? AppColors.expense : AppColors.positive),
        ),
        _MetricCard(
          icon: Icons.scale_outlined,
          label: 'Rendimiento',
          value: rendimiento == null ? '—' : _count.format(rendimiento),
          caption: '${f.unidad}s por $unidadArea',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color? color;

  const _MetricCard({required this.icon, required this.label, required this.value, required this.caption, this.color});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: text.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Icon(icon, size: 17, color: AppColors.textSubtle),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: AppTheme.display(fontSize: 20, color: color ?? AppColors.text)),
              ),
              Text(caption, style: text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

String _label(String? raw) {
  final value = (raw == null || raw.isEmpty) ? 'general' : raw;
  return value[0].toUpperCase() + value.substring(1);
}

/// Barras horizontales de gasto (por categoría o por etapa).
class _ExpenseBars extends StatelessWidget {
  final List<(String, double)> rows;
  final double total;

  const _ExpenseBars({required this.rows, required this.total});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (rows.isEmpty || total <= 0) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Text('Aún no hay gastos registrados.', style: text.bodySmall, textAlign: TextAlign.center),
      );
    }

    final colors = [
      AppColors.accent,
      AppColors.info,
      AppColors.warning,
      AppColors.tertiary,
      AppColors.expense,
      AppColors.textMuted,
    ];

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final (i, (label, amount)) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            _Bar(label: label, amount: amount, share: amount / total, color: colors[i % colors.length]),
          ],
        ],
      ),
    );
  }

}

class _Bar extends StatelessWidget {
  final String label;
  final double amount;
  final double share;
  final Color color;

  const _Bar({required this.label, required this.amount, required this.share, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text(_soles(amount), style: AppTheme.display(fontSize: 13, color: AppColors.text)),
            const SizedBox(width: 8),
            SizedBox(
              width: 42,
              child: Text('${(share * 100).toStringAsFixed(0)}%', textAlign: TextAlign.end, style: text.labelSmall),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: share.clamp(0.0, 1.0),
            minHeight: 8,
            color: color,
            backgroundColor: AppColors.track,
          ),
        ),
      ],
    );
  }
}
