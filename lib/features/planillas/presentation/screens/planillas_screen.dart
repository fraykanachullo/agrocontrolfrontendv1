import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/planilla.dart';
import '../planilla_routes.dart';

/// Hojas de anotación de la campaña: las que siguen abiertas y las ya
/// enviadas como despacho.
class PlanillasScreen extends ConsumerWidget {
  final String campaignId;
  final String cultivo;

  const PlanillasScreen({super.key, required this.campaignId, required this.cultivo});

  int get _campanaId => int.tryParse(campaignId) ?? 0;

  Future<void> _abrir(BuildContext context, WidgetRef ref, {Planilla? planilla}) async {
    await openPlanilla(
      context,
      campanaId: _campanaId,
      cultivo: planilla?.cultivo ?? cultivo,
      numeroHoja: (planilla?.payload['numero_hoja'] as int?) ?? ref.read(planillasProvider).planillas.length + 1,
      planilla: planilla,
    );
    ref.read(planillasProvider.notifier).loadData(_campanaId);
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref, Planilla p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar hoja'),
        content: const Text('Es una hoja que aún no se envió. Se borra del teléfono.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Eliminar', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true && p.id != null) await ref.read(planillasProvider.notifier).deletePlanilla(p.id!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final hojas = ref.watch(planillasProvider).planillas;
    final cerrada = ref.watch(activeCampanaProvider)?.isClosed ?? false;
    final abiertas = hojas.where((p) => p.estado != 'enviada').toList();
    final enviadas = hojas.where((p) => p.estado == 'enviada').toList();

    Widget lista(String titulo, List<Planilla> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: '$titulo (${items.length})'),
            for (final p in items) ...[
              _HojaCard(
                hoja: p,
                onTap: () => _abrir(context, ref, planilla: p),
                // Una hoja enviada ya es un despacho: no se borra (RN-04).
                onEliminar: p.estado == 'enviada' || cerrada ? null : () => _eliminar(context, ref, p),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
          ],
        );

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
                  Text('Hojas de anotación', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (hojas.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.grid_on_rounded, color: AppColors.textSubtle, size: 32),
                    const SizedBox(height: 8),
                    Text('Aún no hay hojas', style: text.bodyMedium),
                    Text('Cada despacho al mercado lleva su hoja de anotación', style: text.bodySmall, textAlign: TextAlign.center),
                  ],
                ),
              ),
            if (abiertas.isNotEmpty) lista('Por enviar', abiertas),
            if (enviadas.isNotEmpty) lista('Enviadas como despacho', enviadas),
          ],
        ),
        bottomNavigationBar: cerrada
            ? null
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: AgroActionButton(
                  label: 'Nueva hoja',
                  icon: Icons.add_rounded,
                  primary: true,
                  height: 56,
                  onPressed: () => _abrir(context, ref),
                ),
              ),
      ),
    );
  }
}

class _HojaCard extends StatelessWidget {
  final Planilla hoja;
  final VoidCallback onTap;
  final VoidCallback? onEliminar;

  const _HojaCard({required this.hoja, required this.onTap, this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = hoja;
    final enviada = p.estado == 'enviada';
    final fecha = DateTime.tryParse(p.fecha);
    final envase = (p.payload['envase'] as String?) ?? 'java';
    final numero = ((p.payload['numero_hoja'] as int?) ?? 0).toString().padLeft(3, '0');
    final filas = (p.payload['filas'] as List?)?.length ?? 0;
    final color = enviada ? AppColors.accent : AppColors.warning;

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
            child: Icon(enviada ? Icons.local_shipping_rounded : Icons.edit_note_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoja $numero${(p.mercado ?? '').isEmpty ? '' : ' · ${p.mercado}'}',
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    if (fecha != null) DateFormat('EEE d MMM', 'es').format(fecha),
                    '$filas filas',
                    if ((p.notas ?? '').isNotEmpty) 'con notas',
                  ].join(' · '),
                  style: text.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(enviada ? 'Enviada' : 'Por enviar', style: text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${p.totalUnidades}', style: AppTheme.display(fontSize: 20, color: AppColors.text)),
              Text('${envase}s', style: text.labelSmall),
            ],
          ),
          if (onEliminar != null)
            IconButton(
              tooltip: 'Eliminar',
              onPressed: onEliminar,
              icon: Icon(Icons.delete_outline_rounded, color: AppColors.textSubtle),
            ),
        ],
      ),
    );
  }
}
