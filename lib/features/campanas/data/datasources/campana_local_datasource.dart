import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/campana_model.dart';

/// Se intentó registrar en una campaña cerrada (RN-01: solo lectura).
class CampanaCerradaException implements Exception {
  @override
  String toString() => 'La campaña está cerrada: solo se puede consultar';
}

/// Bloquea cualquier registro nuevo en una campaña cerrada (RN-01).
Future<void> asegurarCampanaAbierta(int campanaId) async {
  final db = await AppDatabase.database;
  final rows = await db.query('campanas', columns: ['estado'], where: 'id = ?', whereArgs: [campanaId]);
  if (rows.isNotEmpty && rows.first['estado'] == 'cerrada') throw CampanaCerradaException();
}

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

  // Rango [desde, hasta): fechas ISO 'yyyy-MM-dd', se comparan como texto.

  Future<List<Map<String, dynamic>>> listActividadesEnRango(int campanaId, String desde, String hasta) async {
    final db = await AppDatabase.database;
    return await db.query(
      'actividades',
      where: 'campana_id = ? AND fecha >= ? AND fecha < ?',
      whereArgs: [campanaId, desde, hasta],
      orderBy: 'fecha DESC',
    );
  }

  Future<List<Map<String, dynamic>>> listTransaccionesEnRango(int campanaId, String desde, String hasta) async {
    final db = await AppDatabase.database;
    return await db.query(
      'transacciones',
      where: 'campana_id = ? AND fecha >= ? AND fecha < ?',
      whereArgs: [campanaId, desde, hasta],
      orderBy: 'fecha DESC',
    );
  }

  Future<List<Map<String, dynamic>>> listCosechasEnRango(int campanaId, String desde, String hasta) async {
    final db = await AppDatabase.database;
    return await db.query(
      'cosechas',
      where: 'campana_id = ? AND ((fecha_envio >= ? AND fecha_envio < ?) OR (fecha_liquidacion >= ? AND fecha_liquidacion < ?))',
      whereArgs: [campanaId, desde, hasta, desde, hasta],
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

  /// Último gasto registrado en la campaña (para "repetir el último gasto").
  Future<Map<String, dynamic>?> ultimoGasto(int campanaId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      'transacciones',
      where: "campana_id = ? AND tipo = 'gasto'",
      whereArgs: [campanaId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return rows.firstOrNull;
  }

  // ── Gastos por Categoría ──

  /// Gastos, ingresos y cosechas de todas las campañas en una sola consulta.
  /// Los ingresos solo cuentan lo ya cobrado; lo que deben va aparte.
  Future<List<Map<String, dynamic>>> getResumenCampanas() async {
    final db = await AppDatabase.database;
    return await db.rawQuery('''
      SELECT c.id AS campana_id,
        COALESCE((SELECT SUM(monto) FROM transacciones t WHERE t.campana_id = c.id AND t.tipo = 'gasto'), 0) AS gastos,
        COALESCE((SELECT SUM(monto) FROM transacciones t WHERE t.campana_id = c.id AND t.tipo = 'ingreso' AND $_cobrado), 0) AS ingresos_directos,
        COALESCE((SELECT SUM(monto_neto_final) FROM cosechas k WHERE k.campana_id = c.id AND $_ventaCobrada), 0) AS ventas,
        COALESCE((SELECT SUM(monto) FROM transacciones t WHERE t.campana_id = c.id AND t.tipo = 'ingreso' AND NOT $_cobrado), 0)
          + COALESCE((SELECT SUM(monto_neto_final) FROM cosechas k WHERE k.campana_id = c.id AND $_ventaPorCobrar), 0) AS por_cobrar,
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
  //
  // Regla: un ingreso solo suma al balance cuando ya se cobró. Lo que deben
  // (ingreso fiado o despacho liquidado sin cobrar) se muestra aparte como
  // "te deben" para que el agricultor lo revise.

  static const _cobrado = "COALESCE(estado_pago, '') != 'por_cobrar'";
  static const _ventaCobrada = "estado = 'entregado' AND fecha_cobro IS NOT NULL";
  static const _ventaPorCobrar = "estado = 'entregado' AND fecha_cobro IS NULL";

  /// Ya me pagaron (ingreso fiado) o ya pagué (gasto fiado).
  Future<void> marcarPagado(int transaccionId) async {
    final db = await AppDatabase.database;
    await db.update('transacciones', {'estado_pago': 'pagado'}, where: 'id = ?', whereArgs: [transaccionId]);
  }

  Future<Map<String, dynamic>> getDashboardData(int campanaId) async {
    final db = await AppDatabase.database;

    final gastos = await db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) as total FROM transacciones WHERE campana_id = ? AND tipo = ?',
      [campanaId, 'gasto'],
    );
    final ingresos = await db.rawQuery(
      "SELECT COALESCE(SUM(monto), 0) as total FROM transacciones WHERE campana_id = ? AND tipo = 'ingreso' AND $_cobrado",
      [campanaId],
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
    // Fiado en ambos sentidos: ingresos que aún no se cobran y gastos que se deben.
    final porCobrar = await db.rawQuery(
      "SELECT COALESCE(SUM(monto), 0) as total, COUNT(*) as cantidad FROM transacciones WHERE campana_id = ? AND tipo = 'ingreso' AND NOT $_cobrado",
      [campanaId],
    );
    final porPagar = await db.rawQuery(
      "SELECT COALESCE(SUM(monto), 0) as total FROM transacciones WHERE campana_id = ? AND tipo = 'gasto' AND estado_pago = 'por_pagar'",
      [campanaId],
    );
    final cosechasLiquidadas = await db.rawQuery(
      'SELECT COALESCE(SUM(monto_neto_final), 0) as total FROM cosechas WHERE campana_id = ? AND $_ventaCobrada',
      [campanaId],
    );
    final ventasPorCobrar = await db.rawQuery(
      'SELECT COALESCE(SUM(monto_neto_final), 0) as total, COUNT(*) as cantidad FROM cosechas WHERE campana_id = ? AND $_ventaPorCobrar',
      [campanaId],
    );

    return {
      'total_gastos': (gastos.first['total'] as num).toDouble(),
      'total_ingresos': (ingresos.first['total'] as num).toDouble() + (cosechasLiquidadas.first['total'] as num).toDouble(),
      'balance': (ingresos.first['total'] as num).toDouble() - (gastos.first['total'] as num).toDouble() + (cosechasLiquidadas.first['total'] as num).toDouble(),
      'total_actividades': (actividades.first['total'] as int),
      'cosechas_pendientes': (cosechasPendientes.first['total'] as int),
      'cosechas_entregadas': (cosechasEntregadas.first['total'] as int),
      'ingresos_ventas': (cosechasLiquidadas.first['total'] as num).toDouble(),
      'ingresos_por_cobrar': (porCobrar.first['total'] as num).toDouble(),
      'ingresos_por_cobrar_cantidad': porCobrar.first['cantidad'] as int,
      'ventas_por_cobrar': (ventasPorCobrar.first['total'] as num).toDouble(),
      'ventas_por_cobrar_cantidad': ventasPorCobrar.first['cantidad'] as int,
      'gastos_por_pagar': (porPagar.first['total'] as num).toDouble(),
    };
  }

  // ── Incidencias ──

  Future<int> insertIncidencia(Map<String, dynamic> data) async {
    final db = await AppDatabase.database;
    return await db.insert('incidencias', data);
  }

  Future<List<Map<String, dynamic>>> listIncidencias(int campanaId) async {
    final db = await AppDatabase.database;
    return await db.query('incidencias', where: 'campana_id = ?', whereArgs: [campanaId], orderBy: 'fecha ASC');
  }

  Future<List<Map<String, dynamic>>> listIncidenciasEnRango(int campanaId, String desde, String hasta) async {
    final db = await AppDatabase.database;
    return await db.query(
      'incidencias',
      where: 'campana_id = ? AND fecha >= ? AND fecha < ?',
      whereArgs: [campanaId, desde, hasta],
      orderBy: 'fecha DESC',
    );
  }
}
