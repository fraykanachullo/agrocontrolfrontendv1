import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/campana_model.dart';

class CampanaRemoteDatasource {
  final DioClient _dioClient;

  CampanaRemoteDatasource(this._dioClient);

  Future<List<CampanaModel>> listCampanas() async {
    final response = await _dioClient.get(ApiEndpoints.campanas);
    final data = response.data['data'] as List;
    return data
        .map((e) => CampanaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CampanaModel> getCampana(int id) async {
    final response = await _dioClient.get(ApiEndpoints.campanaById(id.toString()));
    return CampanaModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<CampanaModel> createCampana({
    required String nombre,
    required String cultivo,
    required double extension,
    required String tipoExtension,
    required DateTime fechaInicio,
    double? latitud,
    double? longitud,
  }) async {
    final response = await _dioClient.post(
      ApiEndpoints.campanas,
      data: {
        'nombre': nombre,
        'cultivo': cultivo,
        'extension': extension,
        'tipo_extension': tipoExtension,
        'fecha_inicio': fechaInicio.toIso8601String().substring(0, 10),
        if (latitud != null) 'latitud': latitud,
        if (longitud != null) 'longitud': longitud,
      },
    );
    return CampanaModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<CampanaModel> updateCampana(int id, {String? nombre, String? cultivo}) async {
    final response = await _dioClient.put(
      ApiEndpoints.campanaById(id.toString()),
      data: {
        if (nombre != null) 'nombre': nombre,
        if (cultivo != null) 'cultivo': cultivo,
      },
    );
    return CampanaModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<CampanaModel> cerrarCampana(int id) async {
    final response = await _dioClient.post(ApiEndpoints.cerrarCampana(id.toString()));
    return CampanaModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
