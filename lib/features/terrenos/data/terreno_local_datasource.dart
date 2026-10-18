import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_queue_service.dart';
import '../domain/terreno.dart';

/// Terrenos guardados en el teléfono. Aún no se sincronizan: el servidor
/// todavía no tiene la tabla `terrenos` (queda `is_synced = 0`).
class TerrenoLocalDatasource {
  Future<List<Terreno>> listTerrenos(int userId) async {
    final db = await AppDatabase.database;
    final rows = await db.query('terrenos', where: 'user_id = ?', whereArgs: [userId], orderBy: 'nombre COLLATE NOCASE');
    return rows.map(Terreno.fromMap).toList();
  }

  Future<Terreno?> getTerreno(int id) async {
    final db = await AppDatabase.database;
    final rows = await db.query('terrenos', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Terreno.fromMap(rows.first);
  }

  Future<Terreno> insertTerreno({
    required int userId,
    required String nombre,
    required String tenencia,
    required double area,
    required String unidad,
    double? latitud,
    double? longitud,
    String? referencia,
    String? notas,
  }) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('terrenos', {
      'user_id': userId,
      'nombre': nombre,
      'tenencia': tenencia,
      'area': area,
      'unidad': unidad,
      'latitud': latitud,
      'longitud': longitud,
      'referencia': referencia,
      'notas': notas,
      'created_at': now,
      'updated_at': now,
      'is_synced': 0,
      'uuid_local': SyncQueueService.generateUuid(),
    });
    return (await getTerreno(id))!;
  }

  /// Edita un terreno. La unidad no se toca: queda fija desde su creación (RN-02).
  Future<void> updateTerreno(
    int id, {
    required String nombre,
    required String tenencia,
    required double area,
    double? latitud,
    double? longitud,
    String? referencia,
    String? notas,
  }) async {
    final db = await AppDatabase.database;
    await db.update(
      'terrenos',
      {
        'nombre': nombre,
        'tenencia': tenencia,
        'area': area,
        'latitud': latitud,
        'longitud': longitud,
        'referencia': referencia,
        'notas': notas,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
