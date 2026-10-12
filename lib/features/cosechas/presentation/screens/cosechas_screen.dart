import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../planillas/presentation/screens/planillas_screen.dart';
import '../../../planillas/presentation/planilla_routes.dart';
import '../../../planillas/presentation/widgets/planilla_template_sheet.dart';
import '../widgets/pending_shipment_card.dart';

class CosechasScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const CosechasScreen({super.key, required this.campaignId});

  @override
  ConsumerState<CosechasScreen> createState() => _CosechasScreenState();
}

class _CosechasScreenState extends ConsumerState<CosechasScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final campanaId = int.tryParse(widget.campaignId);
      if (campanaId != null) {
        ref.read(cosechasProvider.notifier).loadData(campanaId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final campanaId = int.tryParse(widget.campaignId) ?? 0;
    final cosechas = ref.watch(cosechasProvider);
    final cultivo = ref.watch(activeCampanaProvider)?.cultivo ?? 'papa';
    final nPlanillas = ref.watch(planillasProvider).planillas.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _crearPlanilla(campanaId, cultivo),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Crear Note / Planilla'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cosechas y Despachos',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            _buildPlanillasTile(campanaId, cultivo, nPlanillas),
            const SizedBox(height: 16),

            _buildTabs(),
            const SizedBox(height: 24),

            if (_selectedTab == 0) ...[
              PendingShipmentCard(
                pendientes: cosechas.pendientes,
                campanaId: campanaId,
                cultivo: cultivo,
              ),
            ] else ...[
              if (cosechas.entregadas.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: AppColors.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sin despachos entregados',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...cosechas.entregadas.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
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
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${c.cantidadUnidades} ${c.unidadEmpaque ?? (c.tipoCalculoEfectivo == "por_unidad" ? "javas" : "sacos")}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      '${c.mercadoDestino} • ${c.conductor}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (c.montoNetoFinal != null)
                                Text(
                                  'S/${c.montoNetoFinal!.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                            ],
                          ),
                          if (c.clases.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              height: 1,
                              color: AppColors.surfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            ...c.clases.map((cl) {
                              final nombre = cl.clase == 'sacos'
                                  ? 'Sacos de malla'
                                  : cl.clase;
                              final detalle = cl.pesoKg != null
                                  ? '${cl.cantidad.toInt()} sacos × ${cl.pesoKg!.toStringAsFixed(1)}kg × S/${cl.precioUnitario.toStringAsFixed(2)}'
                                  : '${cl.cantidad.toInt()} javas × S/${cl.precioUnitario.toStringAsFixed(2)}';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$nombre: $detalle',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      'S/${cl.subtotal.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (c.descuentosLogistica != null &&
                                c.descuentosLogistica! > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Descuento flete',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.error),
                                    ),
                                    Text(
                                      '-S/${c.descuentosLogistica!.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanillasTile(int campanaId, String cultivo, int nPlanillas) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _verPlanillas(campanaId, cultivo),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notas / Planillas de Carga',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nPlanillas == 0
                          ? 'Digitalice la planilla manuscrita de campo'
                          : '$nPlanillas hoja(s) de carga registradas · Abrir',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _crearPlanilla(int campanaId, String cultivo) async {
    final tipo = await showPlanillaTemplatePicker(context);
    if (tipo == null || !mounted) return;
    final numero = ref.read(planillasProvider).planillas.length + 1;
    await openPlanilla(
      context,
      campanaId: campanaId,
      cultivo: cultivo,
      tipo: tipo,
      numeroHoja: numero,
    );
  }

  void _verPlanillas(int campanaId, String cultivo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PlanillasScreen(campaignId: widget.campaignId, cultivo: cultivo),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          _buildTab(0, 'Envíos Pendientes'),
          _buildTab(1, 'Liquidados'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
