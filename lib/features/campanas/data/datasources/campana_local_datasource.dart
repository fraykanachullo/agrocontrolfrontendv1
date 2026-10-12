import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/campana_model.dart';

class CampanaLocalDatasource {
  Future<List<CampanaModel>> listCampanas(int userId) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'campanas',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return results.map((r) => CampanaModel.fromJson(r)).toList();
  }

  Future<CampanaModel?> getCampana(int id) async {
    final db = await AppDatabase.database;
    final results = await db.query('campanas', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return CampanaModel.fromJson(results.first);
  }

  Future<int> insertCampana(Map<String, dynamic> data) async {
    final db = await AppDatabase.database;
    return await db.insert('campanas', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCampana(int id, Map<String, dynamic> data) async {
    final db = await AppDatabase.database;
    await db.update('campanas', data, where: 'id = ?', whereArgs: [id]);
  }

  // ── Actividades ──

  Future<List<Map<String, dynamic>>> listActividades(int campanaId) async {
    final db = await AppDatabase.database;
    return await db.query(
      'actividades',
      where: 'campana_id = ?',
      whereArgs: [campanaId],
      orderBy: 'fecha DESC',
    );
  }

  Future<int> insertActividad(Map<String, dynamic> data) async {
    final db = await AppDatabase.database;
    return await db.insert('actividades', data);
  }

  // ── Transacciones ──

  Future<List<Map<String, dynamic>>> listTransacciones(int campanaId) async {
    final db = await AppDatabase.database;
    return await db.query(
      'transacciones',
      where: 'campana_id = ?',
      whereArgs: [campanaId],
      orderBy: 'fecha DESC',
    );
  }

  Future<int> insertTransaccion(Map<String, dynamic> data) async {
    final db = await AppDatabase.database;
    return await db.insert('transacciones', data);
  }

  // ── Cosechas ──

  Future<List<Map<String, dynamic>>> listCosechas(int campanaId) async {
    final db = await AppDatabase.database;
    return await db.query(
      'cosechas',
      where: 'campana_id = ?',
      whereArgs: [campanaId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> insertCosecha(Map<String, dynamic> data) async {
    final db = await AppDatabase.database;
    return await db.insert('cosechas', data);
  }

  Future<void> updateCosecha(int id, Map<String, dynamic> data) async {
    final db = await AppDatabase.database;
    await db.update('cosechas', data, where: 'id = ?', whereArgs: [id]);
  }

  // ── Cosecha Clases (desglose por clase/calidad) ──

  Future<List<Map<String, dynamic>>> listCosechaClases(int cosechaId) async {
    final db = await AppDatabase.database;
    return await db.query(
      'cosecha_clases',
      where: 'cosecha_id = ?',
      whereArgs: [cosechaId],
      orderBy: 'id ASC',
    );
  }

  Future<int> insertCosechaClase(Map<String, dynamic> data) async {
    final db = await AppDatabase.database;
    return await db.insert('cosecha_clases', data);
  }

  Future<void> deleteCosechaClases(int cosechaId) async {
    final db = await AppDatabase.database;
    await db.delete('cosecha_clases', where: 'cosecha_id = ?', whereArgs: [cosechaId]);
  }

  // ── Cosecha Detalles (desglose matricial / categorías / peso directo) ──

  Future<List<Map<String, dynamic>>> listCosechaDetalles(int cosechaId) async {
    final db = await AppDatabase.database;
    return await db.query(
      'cosecha_detalles',
      where: 'cosecha_id = ?',
      whereArgs: [cosechaId],
      orderBy: 'id ASC',
    );
  }

  Future<int> insertCosechaDetalle(Map<String, dynamic> data) async {
    final db = await AppDatabase.database;
    return await db.insert('cosecha_detalles', data);
  }

  Future<void> deleteCosechaDetalles(int cosechaId) async {
    final db = await AppDatabase.database;
    await db.delete('cosecha_detalles', where: 'cosecha_id = ?', whereArgs: [cosechaId]);
  }

  Future<void> updateCosechaDetalle(int id, Map<String, dynamic> data) async {
    final db = await AppDatabase.database;
    await db.update('cosecha_detalles', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> listCosechaDetallesForIds(List<int> cosechaIds) async {
    if (cosechaIds.isEmpty) return [];
    final db = await AppDatabase.database;
    final placeholders = cosechaIds.map((_) => '?').join(',');
    return await db.query(
      'cosecha_detalles',
      where: 'cosecha_id IN ($placeholders)',
      whereArgs: cosechaIds,
      orderBy: 'id ASC',
    );
  }

  // ── Date-filtered queries for Historial ──

  Future<List<Map<String, dynamic>>> listActividadesForDay(int campanaId, String datePrefix) async {
    final db = await AppDatabase.database;
    return await db.query(
      'actividades',
      where: 'campana_id = ? AND fecha LIKE ?',
      whereArgs: [campanaId, '$datePrefix%'],
      orderBy: 'fecha DESC',
    );
  }

  Future<List<Map<String, dynamic>>> listTransaccionesForDay(int campanaId, String datePrefix) async {
    final db = await AppDatabase.database;
    return await db.query(
      'transacciones',
      where: 'campana_id = ? AND fecha LIKE ?',
      whereArgs: [campanaId, '$datePrefix%'],
      orderBy: 'fecha DESC',
    );
  }

  Future<List<Map<String, dynamic>>> listCosechasForDay(int campanaId, String datePrefix) async {
    final db = await AppDatabase.database;
    return await db.query(
      'cosechas',
      where: 'campana_id = ? AND (fecha_envio LIKE ? OR fecha_liquidacion LIKE ?)',
      whereArgs: [campanaId, '$datePrefix%', '$datePrefix%'],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> listCosechaClasesForIds(List<int> cosechaIds) async {
    if (cosechaIds.isEmpty) return [];
    final db = await AppDatabase.database;
    final placeholders = cosechaIds.map((_) => '?').join(',');
    return await db.query(
      'cosecha_clases',
      where: 'cosecha_id IN ($placeholders)',
      whereArgs: cosechaIds,
      orderBy: 'id ASC',
    );
  }

  // ── Gastos por Categoría ──

  /// Gastos, ingresos y cosechas de todas las campañas en una sola consulta.
  Future<List<Map<String, dynamic>>> getResumenCampanas() async {
    final db = await AppDatabase.database;
    return await db.rawQuery('''
      SELECT c.id AS campana_id,
        COALESCE((SELECT SUM(monto) FROM transacciones t WHERE t.campana_id = c.id AND t.tipo = 'gasto'), 0) AS gastos,
        COALESCE((SELECT SUM(monto) FROM transacciones t WHERE t.campana_id = c.id AND t.tipo = 'ingreso'), 0) AS ingresos_directos,
        COALESCE((SELECT SUM(monto_neto_final) FROM cosechas k WHERE k.campana_id = c.id AND k.estado = 'entregado'), 0) AS ventas,
        (SELECT COUNT(*) FROM cosechas k WHERE k.campana_id = c.id) AS cosechas,
        (SELECT COUNT(*) FROM cosechas k WHERE k.campana_id = c.id AND k.estado = 'pendiente') AS por_liquidar
      FROM campanas c
    ''');
  }

  Future<List<Map<String, dynamic>>> getGastosPorEtapa(int campanaId) async {
    final db = await AppDatabase.database;
    return await db.rawQuery(
      "SELECT COALESCE(etapa, 'Sin etapa') as etapa, SUM(monto) as total "
      "FROM transacciones WHERE campana_id = ? AND tipo = 'gasto' "
      "GROUP BY COALESCE(etapa, 'Sin etapa') ORDER BY total DESC",
      [campanaId],
    );
  }

  Future<List<Map<String, dynamic>>> getGastosPorCategoria(int campanaId) async {
    final db = await AppDatabase.database;
    return await db.rawQuery(
      "SELECT categoria, SUM(monto) as total, COUNT(*) as cantidad "
      "FROM transacciones WHERE campana_id = ? AND tipo = 'gasto' "
      "GROUP BY categoria ORDER BY total DESC",
      [campanaId],
    );
  }

  // ── Dashboard Aggregates ──

  Future<Map<String, dynamic>> getDashboardData(int campanaId) async {
    final db = await AppDatabase.database;

    final gastos = await db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) as total FROM transacciones WHERE campana_id = ? AND tipo = ?',
      [campanaId, 'gasto'],
    );
    final ingresos = await db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) as total FROM transacciones WHERE campana_id = ? AND tipo = ?',
      [campanaId, 'ingreso'],
    );
    final actividades = await db.rawQuery(
      'SELECT COUNT(*) as total FROM actividades WHERE campana_id = ?',
      [campanaId],
    );
    final cosechasPendientes = await db.rawQuery(
      "SELECT COUNT(*) as total FROM cosechas WHERE campana_id = ? AND estado = ?",
      [campanaId, 'pendiente'],
    );
    final cosechasEntregadas = await db.rawQuery(
      "SELECT COUNT(*) as total FROM cosechas WHERE campana_id = ? AND estado = ?",
      [campanaId, 'entregado'],
    );
    final cosechasLiquidadas = await db.rawQuery(
      "SELECT COALESCE(SUM(monto_neto_final), 0) as total FROM cosechas WHERE campana_id = ? AND estado = ?",
      [campanaId, 'entregado'],
    );

    return {
      'total_gastos': (gastos.first['total'] as num).toDouble(),
      'total_ingresos': (ingresos.first['total'] as num).toDouble() + (cosechasLiquidadas.first['total'] as num).toDouble(),
      'balance': (ingresos.first['total'] as num).toDouble() - (gastos.first['total'] as num).toDouble() + (cosechasLiquidadas.first['total'] as num).toDouble(),
      'total_actividades': (actividades.first['total'] as int),
      'cosechas_pendientes': (cosechasPendientes.first['total'] as int),
      'cosechas_entregadas': (cosechasEntregadas.first['total'] as int),
      'ingresos_ventas': (cosechasLiquidadas.first['total'] as num).toDouble(),
    };
  }
}
