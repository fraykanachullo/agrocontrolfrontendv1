import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';

class PlanillaLocalDatasource {
  Future<List<Map<String, dynamic>>> listPlanillas(int campanaId) async {
    final db = await AppDatabase.database;
    return await db.query(
      'planillas',
      where: 'campana_id = ?',
      whereArgs: [campanaId],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getPlanilla(int id) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'planillas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<int> insertPlanilla(Map<String, dynamic> data) async {
    final db = await AppDatabase.database;
    return await db.insert(
      'planillas',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePlanilla(int id, Map<String, dynamic> data) async {
    final db = await AppDatabase.database;
    await db.update('planillas', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePlanilla(int id) async {
    final db = await AppDatabase.database;
    await db.delete('planillas', where: 'id = ?', whereArgs: [id]);
  }
}
