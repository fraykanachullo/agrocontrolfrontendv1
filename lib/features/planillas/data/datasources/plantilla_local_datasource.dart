import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/plantilla_cultivo.dart';

/// Plantillas de cultivo guardadas en el teléfono (una por cultivo).
class PlantillaLocalDatasource {
  Future<List<PlantillaCultivo>> listar() async {
    final db = await AppDatabase.database;
    final rows = await db.query('plantillas_cultivo', orderBy: 'cultivo COLLATE NOCASE');
    return rows.map(PlantillaCultivo.fromMap).toList();
  }

  /// La plantilla del cultivo, o una básica si aún no tiene.
  Future<PlantillaCultivo> paraCultivo(String cultivo) async {
    final db = await AppDatabase.database;
    final rows = await db.query('plantillas_cultivo', where: 'cultivo = ? COLLATE NOCASE', whereArgs: [cultivo.trim()]);
    return rows.isEmpty ? PlantillaCultivo.basica(cultivo.trim()) : PlantillaCultivo.fromMap(rows.first);
  }

  Future<void> guardar(PlantillaCultivo p) async {
    final db = await AppDatabase.database;
    await db.insert('plantillas_cultivo', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> eliminar(int id) async {
    final db = await AppDatabase.database;
    await db.delete('plantillas_cultivo', where: 'id = ?', whereArgs: [id]);
  }
}
