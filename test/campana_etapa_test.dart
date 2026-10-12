import 'package:agrocontrol/features/campanas/domain/entities/campana.dart';
import 'package:agrocontrol/features/campanas/presentation/campaign_display.dart';
import 'package:flutter_test/flutter_test.dart';

Campana _campana({String estado = 'activa', DateTime? siembra, DateTime? cierre}) => Campana(
      id: 1,
      nombre: 'Tomate · La Pampa 2026',
      cultivo: 'Tomate',
      extension: 2,
      tipoExtension: 'hectarea',
      estado: estado,
      fechaSiembra: siembra,
      fechaCierre: cierre,
    );

void main() {
  group('Etapa de la campaña según sus hitos', () {
    test('sin siembra está en preparación', () {
      expect(CampaignStage.of(_campana(), hasHarvests: false), CampaignStage.inicio);
    });

    test('la siembra la pasa a crecimiento', () {
      expect(CampaignStage.of(_campana(siembra: DateTime(2026, 8, 1)), hasHarvests: false), CampaignStage.crecimiento);
    });

    test('la primera cosecha la pasa a cosecha', () {
      expect(CampaignStage.of(_campana(siembra: DateTime(2026, 8, 1)), hasHarvests: true), CampaignStage.cosecha);
    });

    test('cerrada siempre está en cierre', () {
      expect(CampaignStage.of(_campana(estado: 'cerrada'), hasHarvests: true), CampaignStage.cierre);
    });
  });

  group('Días desde la siembra', () {
    test('sin siembra no hay días', () {
      expect(_campana().diasDesdeSiembra, isNull);
    });

    test('el día de la siembra es el día 1', () {
      expect(_campana(siembra: DateTime.now()).diasDesdeSiembra, 1);
    });

    test('una campaña cerrada cuenta hasta su cierre', () {
      final c = _campana(estado: 'cerrada', siembra: DateTime(2026, 3, 1), cierre: DateTime(2026, 3, 31));
      expect(c.diasDesdeSiembra, 31);
    });
  });
}
