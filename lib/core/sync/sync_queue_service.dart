import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

class SyncOperation {
  final int? id;
  final String uuidLocal;
  final String tabla;
  final String operacion;
  final Map<String, dynamic> datos;
  final int intentos;
  final String createdAt;

  const SyncOperation({
    this.id,
    required this.uuidLocal,
    required this.tabla,
    required this.operacion,
    required this.datos,
    this.intentos = 0,
    required this.createdAt,
  });

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] as int?,
      uuidLocal: map['uuid_local'] as String,
      tabla: map['tabla'] as String,
      operacion: map['operacion'] as String,
      datos: jsonDecode(map['datos'] as String) as Map<String, dynamic>,
      intentos: map['intentos'] as int? ?? 0,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uuid_local': uuidLocal,
      'tabla': tabla,
      'operacion': operacion,
      'datos': jsonEncode(datos),
      'intentos': intentos,
      'created_at': createdAt,
    };
  }
}

class SyncQueueService {
  static const _uuid = Uuid();

  static String generateUuid() => _uuid.v4();

  Future<String> enqueue({
    required String tabla,
    required String operacion,
    required Map<String, dynamic> datos,
  }) async {
    final db = await AppDatabase.database;
    final uuidLocal = generateUuid();
    final now = DateTime.now().toIso8601String();

    await db.insert('sync_queue', {
      'uuid_local': uuidLocal,
      'tabla': tabla,
      'operacion': operacion,
      'datos': jsonEncode(datos),
      'intentos': 0,
      'created_at': now,
    });

    return uuidLocal;
  }

  Future<List<SyncOperation>> getPending() async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
    );
    return results.map((r) => SyncOperation.fromMap(r)).toList();
  }

  Future<List<SyncOperation>> getPendingByTable(String tabla) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'sync_queue',
      where: 'tabla = ?',
      whereArgs: [tabla],
      orderBy: 'created_at ASC',
    );
    return results.map((r) => SyncOperation.fromMap(r)).toList();
  }

  Future<int> getPendingCount() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM sync_queue');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> incrementAttempts(int id) async {
    final db = await AppDatabase.database;
    await db.rawUpdate(
      'UPDATE sync_queue SET intentos = intentos + 1 WHERE id = ?',
      [id],
    );
    final result = await db.rawQuery('SELECT intentos FROM sync_queue WHERE id = ?', [id]);
    return (result.isNotEmpty ? result.first['intentos'] as int? : 0) ?? 0;
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByUuid(String uuidLocal) async {
    final db = await AppDatabase.database;
    await db.delete('sync_queue', where: 'uuid_local = ?', whereArgs: [uuidLocal]);
  }

  Future<void> markRecordSynced(String tabla, String uuidLocal, int remoteId) async {
    final db = await AppDatabase.database;
    final tableMap = {
      'campanas': 'campanas',
      'actividades': 'actividades',
      'transacciones': 'transacciones',
      'cosechas': 'cosechas',
    };
    final tableName = tableMap[tabla];
    if (tableName != null) {
      await db.update(
        tableName,
        {'is_synced': 1, 'id': remoteId},
        where: 'uuid_local = ?',
        whereArgs: [uuidLocal],
      );
    }
  }

  Future<void> clear() async {
    final db = await AppDatabase.database;
    await db.delete('sync_queue');
  }

  Future<int> clearStuck({int minIntentos = 3}) async {
    final db = await AppDatabase.database;
    return await db.delete('sync_queue', where: 'intentos >= ?', whereArgs: [minIntentos]);
  }
}
