import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../cosechas/domain/entities/cosecha.dart';
import '../domain/entities/campana.dart';

/// Cierre formal de campaña (RF-CAM-05).
///
/// Bloquea el cierre si quedan despachos sin liquidar (RN-05) o cobros
/// pendientes (RF-03); si no, pide confirmación, marca la campaña como
/// cerrada y refresca los indicadores.
Future<void> closeCampanaFlow(BuildContext context, WidgetRef ref, Campana campana) async {
  final messenger = ScaffoldMessenger.of(context);

  await ref.read(cosechasProvider.notifier).loadData(campana.id);
  final cosechas = ref.read(cosechasProvider);
  final pendientes = cosechas.pendientes.length;
  final porCobrar = cosechas.entregadas.where((c) => c.etapa == EtapaDespacho.liquidado).length;
  final transacciones = await ref.read(campanaLocalDatasourceProvider).listTransacciones(campana.id);
  final ingresosPorCobrar = transacciones.where((t) => t['estado_pago'] == 'por_cobrar').length;
  if (!context.mounted) return;

  String plural(int n, String palabra) => '$n $palabra${n == 1 ? '' : 's'}';
  final motivos = [
    if (pendientes > 0) '• ${plural(pendientes, 'despacho')} sin liquidar (regístralo en Cosechas).',
    if (porCobrar > 0) '• ${plural(porCobrar, 'despacho')} liquidado${porCobrar == 1 ? '' : 's'} sin cobrar (marca "Ya cobré").',
    if (ingresosPorCobrar > 0) '• ${plural(ingresosPorCobrar, 'ingreso')} por cobrar en el Cuaderno.',
  ];

  if (motivos.isNotEmpty) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.lock_clock_outlined, color: AppColors.warning),
        title: const Text('Aún no se puede cerrar'),
        content: Text('Primero resuelve:\n${motivos.join('\n')}'),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Entendido'))],
      ),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cerrar campaña'),
      content: Text('¿Cerrar "${campana.nombre}"? El balance quedará congelado y ya no podrás registrar movimientos.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Cerrar campaña', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    final balance = ref.read(dashboardDataProvider).value?['balance'] as double?;
    await ref.read(campanaLocalDatasourceProvider).updateCampana(campana.id, {
      'estado': 'cerrada',
      'fecha_cierre': DateTime.now().toIso8601String(),
      'balance_neto_final': ?balance,
    });
    await ref.read(campanaListProvider.notifier).loadCampanas();
    ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);
    messenger.showSnackBar(SnackBar(content: Text('${campana.nombre} cerrada')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
  }
}
