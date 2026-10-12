import 'package:flutter/material.dart';
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
