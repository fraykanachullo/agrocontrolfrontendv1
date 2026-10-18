import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass.dart';
import '../domain/entities/campana.dart';

/// Presentación compartida de una campaña: emoji del cultivo y etapa visible.

String cropEmoji(String cultivo) {
  final c = cultivo.toLowerCase();
  if (c.contains('tomate')) return '🍅';
  if (c.contains('cebolla')) return '🧅';
  if (c.contains('ajo')) return '🧄';
  if (c.contains('vainita')) return '🫛';
  if (c.contains('papa')) return '🥔';
  if (c.contains('maíz') || c.contains('maiz')) return '🌽';
  if (c.contains('palto') || c.contains('aguacate')) return '🥑';
  if (c.contains('uva')) return '🍇';
  return '🌱';
}

/// Etapa visible de la campaña según sus hitos: siembra (cuaderno),
/// primera cosecha y cierre.
enum CampaignStage {
  inicio('Preparación', Icons.flag_outlined),
  crecimiento('Crecimiento', Icons.eco_outlined),
  cosecha('Cosecha', Icons.agriculture_outlined),
  cierre('Cierre', Icons.task_alt_rounded);

  final String label;
  final IconData icon;
  const CampaignStage(this.label, this.icon);

  static CampaignStage of(Campana campana, {required bool hasHarvests}) {
    if (campana.isClosed) return cierre;
    if (hasHarvests) return cosecha;
    return campana.isSown ? crecimiento : inicio;
  }
}

/// Aviso que reemplaza los botones de registro en una campaña cerrada (RN-01).
class ClosedCampaignNotice extends StatelessWidget {
  final Campana campana;

  const ClosedCampaignNotice({super.key, required this.campana});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cierre = campana.fechaCierre;
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cierre == null ? 'Campaña cerrada' : 'Cerrada el ${DateFormat("d 'de' MMMM y", 'es').format(cierre)}',
                  style: text.titleSmall,
                ),
                Text('Solo lectura: puedes ver sus registros y su resumen.', style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
