import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/ubicacion.dart';
import '../../../../core/widgets/glass.dart';

/// Ubicación del terreno con el GPS del teléfono (sin mapas inventados:
/// solo las coordenadas reales y un botón para abrirlas en Google Maps).
class UbicacionCard extends StatelessWidget {
  final double? lat;
  final double? lng;
  final double? precision;
  final bool buscando;
  final VoidCallback onMarcar;

  const UbicacionCard({super.key, required this.lat, required this.lng, required this.precision, required this.buscando, required this.onMarcar});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final marcada = lat != null && lng != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.track.withValues(alpha: AppColors.palette.isDark ? 0.35 : 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(marcada ? Icons.location_on_rounded : Icons.location_searching_rounded, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(marcada ? 'Ubicación marcada' : 'Ubicación del terreno', style: text.titleSmall),
                    Text(
                      marcada
                          ? '${formatoCoordenadas(lat!, lng!)}${precision == null ? '' : ' · ±${precision!.round()} m'}'
                          : 'Párate en el terreno. Funciona sin internet.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AgroActionButton(
                  label: buscando ? 'Buscando señal…' : (marcada ? 'Volver a marcar' : 'Marcar ubicación aquí'),
                  icon: Icons.my_location_rounded,
                  height: 46,
                  onPressed: buscando ? () {} : onMarcar,
                ),
              ),
              if (marcada) ...[
                const SizedBox(width: 8),
                GlassCircleButton(icon: Icons.map_outlined, tooltip: 'Ver en el mapa', size: 46, onPressed: () => abrirEnMapa(lat!, lng!)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
