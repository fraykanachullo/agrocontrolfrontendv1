import 'package:flutter/material.dart';
import '../domain/entities/planilla.dart';
import 'screens/hoja_anotacion_screen.dart';
import 'screens/planilla_editor_screen.dart';

/// Abre la pantalla adecuada para un tipo de planilla: la hoja de anotación
/// para la matricial y el editor general para el resto.
Future<void> openPlanilla(
  BuildContext context, {
  required int campanaId,
  required String cultivo,
  required String tipo,
  required int numeroHoja,
  Planilla? planilla,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => tipo == 'matricial'
          ? HojaAnotacionScreen(
              campanaId: campanaId,
              cultivo: cultivo,
              numeroHoja: numeroHoja,
              planilla: planilla,
            )
          : PlanillaEditorScreen(
              campanaId: campanaId,
              cultivo: cultivo,
              tipo: tipo,
              numeroHoja: numeroHoja,
              planilla: planilla,
            ),
    ),
  );
}
