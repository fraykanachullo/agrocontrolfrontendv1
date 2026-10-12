import '../entities/campana.dart';

abstract class CampanaRepository {
  Future<List<Campana>> listCampanas();
  Future<Campana> getCampana(int id);
  Future<Campana> createCampana({
    required String nombre,
    required String cultivo,
    required double extension,
    required String tipoExtension,
    required DateTime fechaInicio,
    double? latitud,
    double? longitud,
  });
  Future<Campana> updateCampana(int id, {String? nombre, String? cultivo});
  Future<Campana> cerrarCampana(int id);
}
