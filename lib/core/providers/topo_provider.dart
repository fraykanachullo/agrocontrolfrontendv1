import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_providers.dart';

const _storageKey = 'm2_por_topo';

/// Topo usual en Arequipa. Cambia según la zona: se ajusta en Perfil.
const kM2PorTopoPorDefecto = 3496.0;

/// Metros cuadrados de un topo en la zona del usuario (Diseño v2, S4).
class M2PorTopoNotifier extends StateNotifier<double> {
  final FlutterSecureStorage _storage;

  M2PorTopoNotifier(this._storage) : super(kM2PorTopoPorDefecto) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final saved = double.tryParse(await _storage.read(key: _storageKey) ?? '');
      if (saved != null && saved > 0) state = saved;
    } catch (_) {
      // Sin almacenamiento disponible: se queda el valor por defecto.
    }
  }

  Future<void> set(double m2) async {
    state = m2;
    try {
      await _storage.write(key: _storageKey, value: '$m2');
    } catch (_) {}
  }
}

final m2PorTopoProvider = StateNotifierProvider<M2PorTopoNotifier, double>(
  (ref) => M2PorTopoNotifier(ref.watch(secureStorageProvider)),
);

/// Pasa un área a hectáreas para comparar terrenos medidos en topos y en ha.
double aHectareas(double area, String unidad, double m2PorTopo) =>
    unidad == 'hectarea' ? area : area * m2PorTopo / 10000;
