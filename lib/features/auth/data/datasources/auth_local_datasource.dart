import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/database/app_database.dart';
import '../models/user_model.dart';

class AuthLocalDatasource {
  final FlutterSecureStorage _storage;

  AuthLocalDatasource(this._storage);

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConfig.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: AppConfig.tokenKey);
  }

  Future<void> saveUser(UserModel user) async {
    await _storage.write(
      key: AppConfig.userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<UserModel?> getCachedUser() async {
    final json = await _storage.read(key: AppConfig.userKey);
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> clearUser() async {
    await _storage.delete(key: AppConfig.userKey);
  }

  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
  }

  // ── SQLite-backed methods ──

  Future<UserModel?> loginOffline(String email, String password) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (results.isEmpty) return null;
    return UserModel.fromJson(results.first);
  }

  Future<void> saveUserToDb(UserModel user) async {
    final db = await AppDatabase.database;
    await db.insert(
      'users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUserFromDb(String email) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (results.isEmpty) return null;
    return UserModel.fromJson(results.first);
  }
}
