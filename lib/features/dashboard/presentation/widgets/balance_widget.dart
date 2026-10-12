import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';

class BalanceWidget extends ConsumerWidget {
  final int campanaId;

  const BalanceWidget({super.key, required this.campanaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campana = ref.watch(activeCampanaProvider);
    if (campana == null || campana.isClosed) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryFixedDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Balance en Tiempo Real',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              _CloseCampaignButton(campanaId: campanaId),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloseCampaignButton extends ConsumerStatefulWidget {
  final int campanaId;
  const _CloseCampaignButton({required this.campanaId});

  @override
  ConsumerState<_CloseCampaignButton> createState() => _CloseCampaignButtonState();
}

class _CloseCampaignButtonState extends ConsumerState<_CloseCampaignButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _onCloseCampaign,
        icon: _isLoading
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.lock_outline, size: 16),
        label: const Text('Cerrar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }

  Future<void> _onCloseCampaign() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 48),
        title: const Text('Cerrar Campaña'),
        content: const Text(
          '¿Estás seguro de cerrar esta campaña? '
          'No podrás registrar más actividades ni transacciones.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.dio.post(
        '/v1/campanas/${widget.campanaId}/cerrar',
      );

      if (response.statusCode == 200 && mounted) {
        ref.invalidate(campanaListProvider);
        ref.read(campanaListProvider.notifier).loadCampanas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaña cerrada exitosamente')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String msg = 'Error al cerrar campaña';
      if (e is DioException && e.response?.statusCode == 409) {
        final errors = e.response?.data['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          final parts = <String>[];
          final cobrar = errors['cuentas_por_cobrar'] as int? ?? 0;
          final envios = errors['envios_pendientes_liquidacion'] as int? ?? 0;
          if (cobrar > 0) parts.add('$cobrar cuentas por cobrar');
          if (envios > 0) parts.add('$envios envíos sin liquidar');
          msg = 'Pendientes: ${parts.join(", ")}';
        } else {
          msg = e.response?.data['message'] ?? msg;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
