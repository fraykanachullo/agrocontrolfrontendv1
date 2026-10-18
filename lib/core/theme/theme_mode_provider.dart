import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/app_providers.dart';

const _storageKey = 'theme_mode';

/// Modo visual elegido por el usuario (por defecto, el del sistema).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final FlutterSecureStorage _storage;

  ThemeModeNotifier(this._storage) : super(ThemeMode.system) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      state = ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
    } catch (_) {
      // Sin almacenamiento disponible: se queda el modo del sistema.
    }
  }

  /// Alterna entre claro y oscuro partiendo del brillo que se ve ahora.
  Future<void> toggle(Brightness current) =>
      set(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(key: _storageKey, value: state.name);
    } catch (_) {}
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref.watch(secureStorageProvider)),
);
