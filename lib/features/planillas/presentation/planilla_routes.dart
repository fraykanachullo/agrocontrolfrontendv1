import 'package:flutter/material.dart';
import '../data/datasources/plantilla_local_datasource.dart';
import '../domain/entities/planilla.dart';
import 'screens/hoja_anotacion_screen.dart';

/// Abre la hoja de anotación (nueva o guardada) con la plantilla del cultivo.
Future<void> openPlanilla(
  BuildContext context, {
  required int campanaId,
  required String cultivo,
  required int numeroHoja,
  Planilla? planilla,
}) async {
  // La hoja nueva se arma con la plantilla del cultivo (calidades, filas, envase).
  final plantilla = await PlantillaLocalDatasource().paraCultivo(cultivo);
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => HojaAnotacionScreen(
        campanaId: campanaId,
        cultivo: cultivo,
        numeroHoja: numeroHoja,
        plantilla: plantilla,
        planilla: planilla,
      ),
    ),
  );
}
