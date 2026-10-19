import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/database/app_database.dart';
import '../huella_clave.dart';
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

  /// Entrar sin señal: compara la huella de la contraseña con la guardada la
  /// última vez que se entró (o registró) en este teléfono.
  Future<UserModel?> loginOffline(String email, String password) async {
    final db = await AppDatabase.database;
    final results = await db.query('users', where: 'email = ?', whereArgs: [email.trim()]);
    if (results.isEmpty) return null;
    final guardada = results.first['password'] as String?;
    if (guardada == null || guardada != huellaClave(email, password)) return null;
    return UserModel.fromJson(results.first);
  }

  /// Guarda o actualiza el usuario. Con [password], guarda su huella para
  /// poder entrar sin señal; sin ella, no toca la que ya había (un `replace`
  /// borraba la fila entera y dejaba sin ingreso offline).
  Future<void> saveUserToDb(UserModel user, {String? password}) async {
    final db = await AppDatabase.database;
    final data = {...user.toJson(), if (password != null) 'password': huellaClave(user.email, password)};
    final updated = await db.update('users', data, where: 'email = ?', whereArgs: [user.email]);
    if (updated == 0) {
      await db.insert('users', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }
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
