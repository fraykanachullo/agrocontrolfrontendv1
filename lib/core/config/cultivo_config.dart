/// Configuración de cultivos con sus clases, unidades y mercados
class CultivoConfig {
  final String cultivo;
  final String unidad; // javas, kilos, toneladas
  final String unidadLabel; // Nombre legible de la unidad
  final List<ClaseConfig> clases;
  final List<MercadoConfig> mercados;

  const CultivoConfig({
    required this.cultivo,
    required this.unidad,
    required this.unidadLabel,
    required this.clases,
    required this.mercados,
  });

  /// Si este cultivo maneja clases de calidad
  bool get tieneClases => clases.isNotEmpty;

  /// Unidades predefinidas por cultivo
  static const Map<String, CultivoConfig> configs = {
    'tomate': CultivoConfig(
      cultivo: 'tomate',
      unidad: 'javas',
      unidadLabel: 'Javas',
      clases: [
        ClaseConfig(codigo: 'extra', nombre: 'Extra', descripcion: 'Tomates grandes, bonitos, color uniforme'),
        ClaseConfig(codigo: '1ra', nombre: '1ra - Excelente', descripcion: 'Primera roja, verde o naranja, buen tamaño'),
        ClaseConfig(codigo: '2da', nombre: '2da - Buena', descripcion: 'Segunda, medianos, buen aspecto'),
        ClaseConfig(codigo: '4ta', nombre: '4ta - Mezcla', descripcion: 'Pequeños, mezclados, menos presentables'),
      ],
      mercados: [
        MercadoConfig(codigo: 'lima_sangre_machado', nombre: 'Lima - Sangre Machado'),
        MercadoConfig(codigo: 'lima_primera', nombre: 'Lima - Primera'),
        MercadoConfig(codigo: 'lima_otro', nombre: 'Lima - Otro mercado'),
        MercadoConfig(codigo: 'arequipa', nombre: 'Arequipa'),
        MercadoConfig(codigo: 'chacra', nombre: 'Venta en chacra'),
        MercadoConfig(codigo: 'compra_parcela', nombre: 'Compra de parcela'),
      ],
    ),
    'cebolla': CultivoConfig(
      cultivo: 'cebolla',
      unidad: 'toneladas',
      unidadLabel: 'Toneladas (sacos/malla ~23kg)',
      clases: [
        ClaseConfig(codigo: '1ra', nombre: '1ra - Primera', descripcion: 'Primera calidad, grandes'),
        ClaseConfig(codigo: '2da', nombre: '2da - Segunda', descripcion: 'Segunda calidad'),
        ClaseConfig(codigo: 'floreada', nombre: 'Floreada', descripcion: 'Floreada, aspecto variable'),
        ClaseConfig(codigo: 'paneton', nombre: 'Panetón/Extra', descripcion: 'Panetón o extra (no siempre disponible)'),
      ],
      mercados: [
        MercadoConfig(codigo: 'lima_mayorista', nombre: 'Lima Mayorista'),
        MercadoConfig(codigo: 'arequipa', nombre: 'Arequipa'),
        MercadoConfig(codigo: 'chacra', nombre: 'Venta en chacra'),
        MercadoConfig(codigo: 'compra_parcela', nombre: 'Compra de parcela'),
      ],
    ),
    'ajo': CultivoConfig(
      cultivo: 'ajo',
      unidad: 'toneladas',
      unidadLabel: 'Toneladas (sacos)',
      clases: [
        ClaseConfig(codigo: '1ra', nombre: '1ra - Primera', descripcion: 'Primera calidad, grandes'),
        ClaseConfig(codigo: '2da', nombre: '2da - Segunda', descripcion: 'Segunda calidad'),
        ClaseConfig(codigo: 'partido', nombre: 'Partido', descripcion: 'Partido, menor calidad'),
      ],
      mercados: [
        MercadoConfig(codigo: 'lima_mayorista', nombre: 'Lima Mayorista'),
        MercadoConfig(codigo: 'arequipa', nombre: 'Arequipa'),
        MercadoConfig(codigo: 'chacra', nombre: 'Venta en chacra'),
        MercadoConfig(codigo: 'compra_parcela', nombre: 'Compra de parcela'),
      ],
    ),
    'vainita': CultivoConfig(
      cultivo: 'vainita',
      unidad: 'kilos',
      unidadLabel: 'Kilos',
      clases: [],
      mercados: [
        MercadoConfig(codigo: 'lima_mayorista', nombre: 'Lima Mayorista'),
        MercadoConfig(codigo: 'arequipa', nombre: 'Arequipa'),
        MercadoConfig(codigo: 'chacra', nombre: 'Venta en chacra'),
        MercadoConfig(codigo: 'compra_parcela', nombre: 'Compra de parcela'),
      ],
    ),
    'papa': CultivoConfig(
      cultivo: 'papa',
      unidad: 'kilos',
      unidadLabel: 'Kilos',
      clases: [],
      mercados: [
        MercadoConfig(codigo: 'lima_mayorista', nombre: 'Lima Mayorista'),
        MercadoConfig(codigo: 'arequipa', nombre: 'Arequipa'),
        MercadoConfig(codigo: 'chacra', nombre: 'Venta en chacra'),
      ],
    ),
    'maiz': CultivoConfig(
      cultivo: 'maiz',
      unidad: 'toneladas',
      unidadLabel: 'Toneladas',
      clases: [],
      mercados: [
        MercadoConfig(codigo: 'lima_mayorista', nombre: 'Lima Mayorista'),
        MercadoConfig(codigo: 'chacra', nombre: 'Venta en chacra'),
      ],
    ),
    'trigo': CultivoConfig(
      cultivo: 'trigo',
      unidad: 'toneladas',
      unidadLabel: 'Toneladas',
      clases: [],
      mercados: [
        MercadoConfig(codigo: 'lima_mayorista', nombre: 'Lima Mayorista'),
        MercadoConfig(codigo: 'chacra', nombre: 'Venta en chacra'),
      ],
    ),
  };

  /// Obtener config para un cultivo (fallback a "otro")
  static CultivoConfig forCultivo(String cultivo) {
    return configs[cultivo.toLowerCase()] ?? configs['papa']!;
  }

  /// Lista de todos los cultivos disponibles para crear campaña
  static const List<Map<String, String>> cultivosDisponibles = [
    {'value': 'tomate', 'label': 'Tomate'},
    {'value': 'cebolla', 'label': 'Cebolla'},
    {'value': 'ajo', 'label': 'Ajo'},
    {'value': 'vainita', 'label': 'Vainita'},
    {'value': 'papa', 'label': 'Papa'},
    {'value': 'maiz', 'label': 'Maíz'},
    {'value': 'trigo', 'label': 'Trigo'},
    {'value': 'otro', 'label': 'Otro'},
  ];
}

class ClaseConfig {
  final String codigo;
  final String nombre;
  final String descripcion;

  const ClaseConfig({
    required this.codigo,
    required this.nombre,
    required this.descripcion,
  });
}

class MercadoConfig {
  final String codigo;
  final String nombre;

  const MercadoConfig({
    required this.codigo,
    required this.nombre,
  });
}
