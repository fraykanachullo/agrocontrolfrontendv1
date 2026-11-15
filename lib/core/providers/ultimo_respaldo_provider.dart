import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_providers.dart';

const _storageKey = 'ultimo_respaldo';

/// Cuándo se guardó el último respaldo en este teléfono (null si nunca).
class UltimoRespaldoNotifier extends StateNotifier<DateTime?> {
  final FlutterSecureStorage _storage;

  UltimoRespaldoNotifier(this._storage) : super(null) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final saved = DateTime.tryParse(await _storage.read(key: _storageKey) ?? '');
      if (saved != null) state = saved;
    } catch (_) {
      // Sin almacenamiento disponible: se queda sin fecha.
    }
  }

  Future<void> marcar(DateTime t) async {
    state = t;
    try {
      await _storage.write(key: _storageKey, value: t.toIso8601String());
    } catch (_) {}
  }
}

final ultimoRespaldoProvider = StateNotifierProvider<UltimoRespaldoNotifier, DateTime?>(
  (ref) => UltimoRespaldoNotifier(ref.watch(secureStorageProvider)),
);
