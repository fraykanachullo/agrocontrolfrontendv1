import 'package:flutter/material.dart';
import '../../../../core/providers/app_providers.dart' show CampanaResumen;
import '../../../../core/providers/topo_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_pieces.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/campana.dart';
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
