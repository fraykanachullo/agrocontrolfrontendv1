import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_providers.dart';

const _storageKey = 'dias_aviso_despacho';

/// Opciones para avisar de un despacho que no llega al mercado.
const opcionesDiasAviso = [2, 3, 4, 5, 7];

/// Días que un despacho puede ir en camino antes de avisar (por defecto 4).
class DiasAvisoNotifier extends StateNotifier<int> {
  final FlutterSecureStorage _storage;

  DiasAvisoNotifier(this._storage) : super(4) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final saved = int.tryParse(await _storage.read(key: _storageKey) ?? '');
      if (saved != null) state = saved;
    } catch (_) {
      // Sin almacenamiento disponible: se queda el valor por defecto.
    }
  }

  Future<void> set(int dias) async {
    state = dias;
    try {
      await _storage.write(key: _storageKey, value: '$dias');
    } catch (_) {}
  }
}

final diasAvisoDespachoProvider = StateNotifierProvider<DiasAvisoNotifier, int>(
  (ref) => DiasAvisoNotifier(ref.watch(secureStorageProvider)),
);
