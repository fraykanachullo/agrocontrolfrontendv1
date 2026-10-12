import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/entities/campana.dart';

/// Cierre formal de campaña (RF-CAM-05).
///
/// Bloquea el cierre si quedan despachos sin liquidar (RN-05); si no, pide
/// confirmación, marca la campaña como cerrada y refresca los indicadores.
Future<void> closeCampanaFlow(BuildContext context, WidgetRef ref, Campana campana) async {
  final messenger = ScaffoldMessenger.of(context);

  await ref.read(cosechasProvider.notifier).loadData(campana.id);
  final pendientes = ref.read(cosechasProvider).pendientes;
  if (!context.mounted) return;

  if (pendientes.isNotEmpty) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.lock_clock_outlined, color: AppColors.warning),
        title: const Text('Aún no se puede cerrar'),
        content: Text(
          'Hay ${pendientes.length} despacho${pendientes.length == 1 ? '' : 's'} sin liquidar. '
          'Registra su liquidación en Cosechas para poder cerrar la campaña.',
        ),
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
