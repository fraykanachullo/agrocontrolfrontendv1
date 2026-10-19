import 'package:flutter/material.dart';
import '../../../../core/providers/app_providers.dart' show CampanaResumen;
import '../../../../core/providers/topo_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/campana.dart';
import '../../../resumen/presentation/widgets/tendencia_campana.dart';
import '../campaign_display.dart';

/// Comparativo entre campañas (Diseño v2 §3): por cultivo o por año, con la
/// utilidad por hectárea para comparar áreas distintas.
class ComparativoCampanas extends StatefulWidget {
  final List<Campana> campanas;
  final Map<int, CampanaResumen> resumenes;
  final double m2PorTopo;

  const ComparativoCampanas({super.key, required this.campanas, required this.resumenes, required this.m2PorTopo});

  @override
  State<ComparativoCampanas> createState() => _ComparativoCampanasState();
}

class _ComparativoCampanasState extends State<ComparativoCampanas> {
  bool _porCultivo = true;

  String _clave(Campana c) => _porCultivo
      ? c.cultivo
      : '${(c.fechaInicio ?? c.createdAt ?? DateTime.now()).year}';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final grupos = <String, List<Campana>>{};
    for (final c in widget.campanas) {
      grupos.putIfAbsent(_clave(c), () => []).add(c);
    }
    final filas = [
      for (final MapEntry(key: clave, value: lista) in grupos.entries)
        _Grupo.de(clave, lista, widget.resumenes, widget.m2PorTopo),
    ]..sort((a, b) => _porCultivo
        ? (b.utilidadPorHa ?? double.negativeInfinity).compareTo(a.utilidadPorHa ?? double.negativeInfinity)
        : b.clave.compareTo(a.clave));
    final mejor = filas.where((g) => g.conVentas).fold<_Grupo?>(
          null,
          (m, g) => m == null || (g.utilidadPorHa ?? 0) > (m.utilidadPorHa ?? 0) ? g : m,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TendenciaGeneral(),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Ganancia por campaña'),
        GananciaPorCampana(campanas: widget.campanas, resumenes: widget.resumenes),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Por cultivo o por año'),
        Row(
          children: [
            MiniChip(label: 'Por cultivo', large: true, selected: _porCultivo, onTap: () => setState(() => _porCultivo = true)),
            const SizedBox(width: 8),
            MiniChip(label: 'Por año', large: true, selected: !_porCultivo, onTap: () => setState(() => _porCultivo = false)),
          ],
        ),
        const SizedBox(height: 6),
        Text('Utilidad por hectárea: compara campañas de distinto tamaño.', style: text.bodySmall),
        const SizedBox(height: 12),
        for (final g in filas) ...[
          _GrupoCard(grupo: g, porCultivo: _porCultivo, mejor: _porCultivo && identical(g, mejor) && filas.length > 1),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Totales de un grupo de campañas.
class _Grupo {
  final String clave;
  final int campanas;
  final int enCurso;
  final double hectareas;
  final double gastos;
  final double ingresos;

  const _Grupo(this.clave, this.campanas, this.enCurso, this.hectareas, this.gastos, this.ingresos);

  factory _Grupo.de(String clave, List<Campana> lista, Map<int, CampanaResumen> resumenes, double m2PorTopo) {
    var ha = 0.0, gastos = 0.0, ingresos = 0.0;
    for (final c in lista) {
      ha += aHectareas(c.extension, c.tipoExtension, m2PorTopo);
      gastos += resumenes[c.id]?.gastos ?? 0;
      ingresos += resumenes[c.id]?.ingresos ?? 0;
    }
    return _Grupo(clave, lista.length, lista.where((c) => !c.isClosed).length, ha, gastos, ingresos);
  }

  double get utilidad => ingresos - gastos;
  bool get conVentas => ingresos > 0;
  double? get utilidadPorHa => hectareas > 0 && conVentas ? utilidad / hectareas : null;
  double? get rentabilidad => gastos > 0 && conVentas ? utilidad / gastos * 100 : null;
}

class _GrupoCard extends StatelessWidget {
  final _Grupo grupo;
  final bool porCultivo;
  final bool mejor;

  const _GrupoCard({required this.grupo, required this.porCultivo, required this.mejor});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final g = grupo;
    final color = !g.conVentas ? AppColors.textMuted : (g.utilidad < 0 ? AppColors.expense : AppColors.positive);
    String soles(double v) => '${v < 0 ? '-' : ''}${formatSoles(v.abs())}';

    return GlassCard(
      radius: 20,
      highlight: mejor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(porCultivo ? cropEmoji(g.clave) : '📅', style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.clave, style: text.titleSmall),
                    Text(
                      [
                        '${g.campanas} campaña${g.campanas == 1 ? '' : 's'}',
                        '${g.hectareas.toStringAsFixed(2)} ha',
                        if (g.enCurso > 0) '${g.enCurso} en curso',
                      ].join(' · '),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (mejor)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.positive.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                  child: Text('Rinde más', style: text.labelSmall?.copyWith(color: AppColors.positive, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Cifra(label: 'Utilidad', valor: g.conVentas ? soles(g.utilidad) : 'Sin ventas', color: color),
              _Cifra(label: 'Por hectárea', valor: g.utilidadPorHa == null ? '—' : soles(g.utilidadPorHa!), color: color),
              _Cifra(
                label: 'Rentabilidad',
                valor: g.rentabilidad == null ? '—' : '${g.rentabilidad!.toStringAsFixed(0)}%',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Invertido ${formatSoles(g.gastos)} · Vendido ${formatSoles(g.ingresos)}', style: text.labelSmall),
        ],
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;

  const _Cifra({required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: AppTheme.display(fontSize: 15, color: color)),
          ),
        ],
      ),
    );
  }
}

/// Ganancia (o pérdida) de cada campaña en barras que parten de cero:
/// a la derecha en verde lo que ganó, a la izquierda en naranja lo que perdió.
/// Solo cuenta lo cobrado; lo que deben se indica aparte.
class GananciaPorCampana extends StatelessWidget {
  final List<Campana> campanas;
  final Map<int, CampanaResumen> resumenes;

  const GananciaPorCampana({super.key, required this.campanas, required this.resumenes});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final filas = [
      for (final c in campanas)
        if (resumenes[c.id] case final r? when r.gastos > 0 || r.ingresos > 0) (c, r),
    ]..sort((a, b) => b.$2.utilidad.compareTo(a.$2.utilidad));

    if (filas.isEmpty) {
      return GlassCard(
        radius: 22,
        padding: const EdgeInsets.all(18),
        child: Text('Cuando registres gastos y ventas, aquí verás qué campaña te fue mejor.', style: text.bodyMedium),
      );
    }

    final maxGanancia = filas.map((f) => f.$2.utilidad).fold<double>(0, (m, u) => u > m ? u : m);
    final maxPerdida = filas.map((f) => -f.$2.utilidad).fold<double>(0, (m, u) => u > m ? u : m);
    final rango = maxGanancia + maxPerdida;
    // Dónde cae el cero: al borde izquierdo si ninguna perdió.
    final cero = rango == 0 ? 0.0 : maxPerdida / rango;
    final mejor = filas.first.$2.utilidad > 0 ? filas.first.$1.id : null;

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            children: [
              _Clave(color: AppColors.chartIngreso, label: 'Ganó'),
              if (maxPerdida > 0) _Clave(color: AppColors.chartGasto, label: 'Perdió'),
            ],
          ),
          const SizedBox(height: 12),
          for (final (c, r) in filas) ...[
            _FilaGanancia(
              campana: c,
              resumen: r,
              cero: cero,
              fraccion: rango == 0 ? 0 : r.utilidad.abs() / rango,
              mejor: c.id == mejor && filas.length > 1,
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _FilaGanancia extends StatelessWidget {
  final Campana campana;
  final CampanaResumen resumen;
  final double cero;
  final double fraccion;
  final bool mejor;

  const _FilaGanancia({required this.campana, required this.resumen, required this.cero, required this.fraccion, required this.mejor});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final u = resumen.utilidad;
    final gana = u >= 0;
    final color = gana ? AppColors.chartIngreso : AppColors.chartGasto;
    const radio = Radius.circular(4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(cropEmoji(campana.cultivo), style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(child: Text(campana.nombre, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (mejor) ...[
              Icon(Icons.emoji_events_rounded, size: 16, color: AppColors.warning),
              const SizedBox(width: 4),
            ],
            Icon(gana ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: color),
            Text(
              '${gana ? '+' : '-'}${formatSoles(u.abs())}',
              style: AppTheme.display(fontSize: 15, color: AppColors.text),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final x0 = w * cero;
            final largo = (w * fraccion).clamp(u == 0 ? 0.0 : 3.0, w);
            return SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.track.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Positioned(
                    left: gana ? x0 : x0 - largo,
                    width: largo,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        // Extremo redondeado del lado del dato; recto en el cero.
                        borderRadius: gana
                            ? const BorderRadius.horizontal(right: radio)
                            : const BorderRadius.horizontal(left: radio),
                      ),
                    ),
                  ),
                  if (cero > 0)
                    Positioned(left: x0 - 0.5, width: 1, top: -2, bottom: -2, child: ColoredBox(color: AppColors.textSubtle)),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          [
            'Ingresos ${formatSoles(resumen.ingresos)}',
            'Gastos ${formatSoles(resumen.gastos)}',
            if (resumen.porCobrar > 0) 'te deben ${formatSoles(resumen.porCobrar)}',
          ].join(' · '),
          style: text.labelSmall,
        ),
      ],
    );
  }
}

class _Clave extends StatelessWidget {
  final Color color;
  final String label;

  const _Clave({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
