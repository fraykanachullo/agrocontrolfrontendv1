import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../domain/entities/planilla.dart';
import '../widgets/planilla_template_sheet.dart';
import 'planilla_editor_screen.dart';

class PlanillasScreen extends ConsumerWidget {
  final String campaignId;
  final String cultivo;

  const PlanillasScreen({
    super.key,
    required this.campaignId,
    required this.cultivo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campanaId = int.tryParse(campaignId) ?? 0;
    ref.watch(planillasProvider);
    final state = ref.watch(planillasProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notas / Planillas de Carga'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(planillasProvider.notifier).loadData(campanaId),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.planillas.isEmpty
          ? _buildEmpty(context, ref, campanaId)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: state.planillas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _planillaCard(context, ref, campanaId, state.planillas[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nuevaPlanilla(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Crear Note / Planilla'),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref, int campanaId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFFDF8EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin planillas todavía',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Cree su primera hoja de carga para reemplazar la planilla de papel en campo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _nuevaPlanilla(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Crear Note / Planilla'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planillaCard(
    BuildContext context,
    WidgetRef ref,
    int campanaId,
    Planilla p,
  ) {
    return Material(
      color: const Color(0xFFFDF8EC),
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirEditor(context, ref, campanaId, planilla: p),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconoPara(p.tipo),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.tipoLabel,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'N° ${p.numeroHojaText()} · ${p.cultivo} · ${p.fecha}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'editar') {
                        _abrirEditor(context, ref, campanaId, planilla: p);
                      }
                      if (v == 'eliminar') {
                        _eliminar(context, ref, campanaId, p);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar / Continuar'),
                      ),
                      PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                    ],
                  ),
                ],
              ),
              const Divider(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${p.totalUnidades} ${_unidadL(p.tipo)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${p.totalPeso.toStringAsFixed(p.totalPeso == 0 ? 0 : 2)} kg',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  Text(
                    p.estado == 'compartida' ? '· compartida' : '· guardada',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
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

  IconData _iconoPara(String tipo) => switch (tipo) {
    'matricial' => Icons.grid_on,
    'por_categorias' => Icons.category_outlined,
    _ => Icons.monitor_weight_outlined,
  };

  String _unidadL(String tipo) => switch (tipo) {
    'matricial' => 'javas',
    'por_categorias' => 'sacos',
    _ => 'bultos',
  };

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    int campanaId,
    Planilla p,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar planilla'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmado == true && p.id != null) {
      await ref.read(planillasProvider.notifier).deletePlanilla(p.id!);
    }
  }

  Future<void> _abrirEditor(
    BuildContext context,
    WidgetRef ref,
    int campanaId, {
    Planilla? planilla,
  }) async {
    final numero = planilla?.numeroHojaParse() ?? (_planillasCount(ref) + 1);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanillaEditorScreen(
          campanaId: campanaId,
          cultivo: planilla?.cultivo ?? cultivo,
          tipo: planilla?.tipo ?? 'matricial',
          numeroHoja: numero,
          planilla: planilla,
        ),
      ),
    );
  }

  int _planillasCount(WidgetRef ref) {
    return ref.read(planillasProvider).planillas.length;
  }

  Future<void> _nuevaPlanilla(BuildContext context, WidgetRef ref) async {
    final campanaId = int.tryParse(campaignId) ?? 0;
    final t = await showPlanillaTemplatePicker(context);
    if (t == null || !context.mounted) return;
    final numero = _planillasCount(ref) + 1;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanillaEditorScreen(
          campanaId: campanaId,
          cultivo: cultivo,
          tipo: t,
          numeroHoja: numero,
        ),
      ),
    );
    ref.read(planillasProvider.notifier).loadData(campanaId);
  }
}

extension on Planilla {
  String numeroHojaText() {
    final n = payload['numero_hoja'] as int? ?? 0;
    return n.toString().padLeft(4, '0');
  }

  int numeroHojaParse() => payload['numero_hoja'] as int? ?? 0;
}
