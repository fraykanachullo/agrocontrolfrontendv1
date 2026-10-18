import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'agrocontrol.db');

    return await openDatabase(
      path,
      version: 11,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  static Future<void> _createDB(Database db, int version) async {
    await _createTables(db);
    await _seedDemoData(db);
  }

  static Future<void> _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createSyncQueueTable(db);
      await _addUuidColumns(db);
    }
    if (oldVersion < 3) {
      await _createEvidenciasTable(db);
    }
    if (oldVersion < 4) {
      await _createCosechaClasesTable(db);
    }
    if (oldVersion < 5) {
      await _addModoCosechaColumns(db);
      await _createCosechaDetallesTable(db);
    }
    if (oldVersion < 6) {
      await _createPlanillasTable(db);
    }
    if (oldVersion < 7) {
      // Etapa del cultivo del gasto (Preparación, Siembra, Mantenimiento, Cosecha).
      await db.execute('ALTER TABLE transacciones ADD COLUMN etapa TEXT');
    }
    if (oldVersion < 8) {
      // Detalle de la liquidación: vendidos por calidad, descuentos, forma de cobro y comprobante.
      await db.execute('ALTER TABLE cosechas ADD COLUMN liquidacion_json TEXT');
    }
    if (oldVersion < 9) {
      await _addTerrenos(db);
    }
    if (oldVersion < 10) {
      await _addCicloDespacho(db);
    }
    if (oldVersion < 11) {
      await _createIncidenciasTable(db);
      await _moverIncidencias(db);
      await _createPlantillasTable(db);
      await _seedPlantillas(db);
    }
  }

  /// v11: las incidencias tenían el prefijo "[Incidencia] " en actividades
  /// ("[Incidencia] Plaga · Severidad alta · nota"). Pasan a su propia tabla,
  /// junto con sus fotos.
  static Future<void> _moverIncidencias(Database db) async {
    const prefijo = '[Incidencia] ';
    final viejas = await db.query('actividades', where: 'descripcion LIKE ?', whereArgs: ['$prefijo%']);
    for (final a in viejas) {
      final partes = (a['descripcion'] as String).substring(prefijo.length).split(' · ');
      final conSeveridad = partes.length > 1 && partes[1].startsWith('Severidad ');
      final severidad = conSeveridad ? partes[1].substring('Severidad '.length) : 'media';
      final nota = partes.skip(conSeveridad ? 2 : 1).join(' · ');
      final id = await db.insert('incidencias', {
        'campana_id': a['campana_id'],
        'tipo': partes.first,
        'severidad': severidad,
        'nota': nota.isEmpty ? null : nota,
        'fecha': a['fecha'],
        'created_at': a['created_at'],
        'is_synced': 0,
        'uuid_local': a['uuid_local'],
      });
      await db.update(
        'evidencias',
        {'relacion_tipo': 'incidencia', 'relacion_id': id},
        where: "relacion_tipo = 'actividad' AND relacion_id = ?",
        whereArgs: [a['id']],
      );
      await db.delete('actividades', where: 'id = ?', whereArgs: [a['id']]);
    }
  }

  /// v10: ciclo del despacho (anotado → en tránsito → recibido → liquidado →
  /// cobrado). Cada paso guarda su fecha; `estado` sigue siendo pendiente o
  /// entregado (liquidado) para el servidor. Los despachos que ya existían
  /// salieron el día del envío, y los liquidados se dan por cobrados, como
  /// se mostraban antes.
  static Future<void> _addCicloDespacho(Database db) async {
    for (final col in ['fecha_salida TEXT', 'fecha_recepcion TEXT', 'fecha_cobro TEXT']) {
      await db.execute('ALTER TABLE cosechas ADD COLUMN $col');
    }
    await db.execute("UPDATE cosechas SET fecha_salida = fecha_envio WHERE tipo_venta != 'parcela'");
    await db.execute("UPDATE cosechas SET fecha_cobro = COALESCE(fecha_liquidacion, fecha_envio) WHERE estado = 'entregado'");
  }

  /// v9: el terreno vive más que la campaña. Cada campaña existente recibe su
  /// propio terreno (con su área y ubicación), y la fecha de siembra se toma de
  /// la primera labor de siembra del cuaderno, si la hay.
  static Future<void> _addTerrenos(Database db) async {
    await _createTerrenosTable(db);
    for (final col in ['terreno_id INTEGER', 'variedad TEXT', 'fecha_siembra TEXT']) {
      await db.execute('ALTER TABLE campanas ADD COLUMN $col');
    }
    final campanas = await db.query('campanas');
    for (final c in campanas) {
      final now = DateTime.now().toIso8601String();
      final terrenoId = await db.insert('terrenos', {
        'user_id': c['user_id'],
        'nombre': 'Terreno de ${c['nombre']}',
        'tenencia': 'propio',
        'area': c['extension'] ?? 0,
        'unidad': c['tipo_extension'] ?? 'hectarea',
        'latitud': c['latitud'],
        'longitud': c['longitud'],
        'created_at': now,
        'updated_at': now,
      });
      final siembra = await db.rawQuery(
        "SELECT MIN(fecha) AS f FROM actividades WHERE campana_id = ? AND descripcion LIKE 'Siembra%'",
        [c['id']],
      );
      await db.update(
        'campanas',
        {'terreno_id': terrenoId, 'fecha_siembra': siembra.first['f']},
        where: 'id = ?',
        whereArgs: [c['id']],
      );
    }
  }

  static Future<void> _addModoCosechaColumns(Database db) async {
    final columns = [
      'modo_cosecha TEXT',
      'tipo_calculo_venta TEXT',
      'unidad_empaque TEXT',
      'total_bultos INTEGER',
      'peso_total_kg REAL',
    ];
    for (final col in columns) {
      try {
        await db.execute('ALTER TABLE cosechas ADD COLUMN $col');
      } catch (_) {}
    }
  }

  static Future<void> _addUuidColumns(Database db) async {
    final tables = ['campanas', 'actividades', 'transacciones', 'cosechas'];
    for (final table in tables) {
      try {
        await db.execute('ALTER TABLE $table ADD COLUMN uuid_local TEXT');
      } catch (_) {}
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        nombre_completo TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        telefono TEXT,
        rol TEXT DEFAULT 'propietario',
        plan_suscripcion TEXT DEFAULT 'gratuito',
        tenant_id INTEGER DEFAULT 1,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE campanas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        cultivo TEXT NOT NULL,
        extension REAL NOT NULL DEFAULT 0,
        tipo_extension TEXT NOT NULL DEFAULT 'hectarea',
        latitud REAL,
        longitud REAL,
        estado TEXT NOT NULL DEFAULT 'activa',
        fecha_inicio TEXT,
        fecha_cierre TEXT,
        balance_neto_final REAL,
        terreno_id INTEGER,
        variedad TEXT,
        fecha_siembra TEXT,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        uuid_local TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE actividades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        campana_id INTEGER NOT NULL,
        descripcion TEXT NOT NULL,
        fecha TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        uuid_local TEXT,
        FOREIGN KEY (campana_id) REFERENCES campanas(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transacciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        campana_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        categoria TEXT,
        monto REAL NOT NULL DEFAULT 0,
        descripcion TEXT,
        fecha TEXT NOT NULL,
        estado_pago TEXT DEFAULT 'pagado',
        etapa TEXT,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        uuid_local TEXT,
        FOREIGN KEY (campana_id) REFERENCES campanas(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cosechas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        campana_id INTEGER NOT NULL,
        tipo_venta TEXT NOT NULL,
        modo_cosecha TEXT,
        tipo_calculo_venta TEXT,
        unidad_empaque TEXT,
        total_bultos INTEGER,
        peso_total_kg REAL,
        cantidad_unidades REAL NOT NULL DEFAULT 0,
        conductor TEXT,
        mercado_destino TEXT,
        estado TEXT NOT NULL DEFAULT 'pendiente',
        precio_unitario REAL,
        descuentos_logistica REAL DEFAULT 0,
        monto_neto_final REAL,
        fecha_envio TEXT,
        fecha_liquidacion TEXT,
        fecha_salida TEXT,
        fecha_recepcion TEXT,
        fecha_cobro TEXT,
        liquidacion_json TEXT,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        uuid_local TEXT,
        FOREIGN KEY (campana_id) REFERENCES campanas(id)
      )
    ''');

    await _createTerrenosTable(db);
    await _createIncidenciasTable(db);
    await _createPlantillasTable(db);
    await _seedPlantillas(db);
    await _createSyncQueueTable(db);
    await _createEvidenciasTable(db);
    await _createCosechaClasesTable(db);
    await _createCosechaDetallesTable(db);
    await _createPlanillasTable(db);
  }

  /// Terreno: propio o alquilado, con su área, unidad (no cambia: RN-02) y ubicación GPS.
  static Future<void> _createTerrenosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS terrenos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        tenencia TEXT NOT NULL DEFAULT 'propio',
        area REAL NOT NULL DEFAULT 0,
        unidad TEXT NOT NULL DEFAULT 'hectarea',
        latitud REAL,
        longitud REAL,
        referencia TEXT,
        notas TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        uuid_local TEXT
      )
    ''');
  }

  /// Incidencia de la campaña: plaga, helada, enfermedad, robo…
  static Future<void> _createIncidenciasTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS incidencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        campana_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        severidad TEXT NOT NULL DEFAULT 'media',
        nota TEXT,
        fecha TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        uuid_local TEXT,
        FOREIGN KEY (campana_id) REFERENCES campanas(id)
      )
    ''');
  }

  /// Plantilla de cultivo editable: calidades (columnas de la hoja), filas
  /// por defecto, envase y peso promedio del envase.
  static Future<void> _createPlantillasTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plantillas_cultivo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cultivo TEXT NOT NULL UNIQUE COLLATE NOCASE,
        calidades_json TEXT NOT NULL,
        filas INTEGER NOT NULL DEFAULT 16,
        envase TEXT NOT NULL DEFAULT 'java',
        peso_envase_kg REAL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Plantilla inicial de tomate (hoja real "Viernes 17").
  static Future<void> _seedPlantillas(Database db) async {
    await db.insert(
      'plantillas_cultivo',
      {
        'cultivo': 'Tomate',
        'calidades_json': jsonEncode([
          {'codigo': 'I', 'nombre': 'Primera'},
          {'codigo': 'II', 'nombre': 'Segunda'},
          {'codigo': 'III', 'nombre': 'Tercera'},
          {'codigo': '0', 'nombre': 'Cuarta'},
          {'codigo': 'R', 'nombre': 'Rojos'},
          {'codigo': 'Z', 'nombre': 'Manchados'},
        ]),
        'filas': 16,
        'envase': 'java',
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> _createSyncQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid_local TEXT NOT NULL,
        tabla TEXT NOT NULL,
        operacion TEXT NOT NULL,
        datos TEXT NOT NULL,
        intentos INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createEvidenciasTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS evidencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        relacion_id INTEGER NOT NULL,
        relacion_tipo TEXT NOT NULL,
        ruta_archivo TEXT NOT NULL,
        uuid_local TEXT,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<void> _createCosechaClasesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cosecha_clases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cosecha_id INTEGER NOT NULL,
        clase TEXT NOT NULL,
        cantidad REAL NOT NULL DEFAULT 0,
        precio_unitario REAL NOT NULL DEFAULT 0,
        peso_kg REAL,
        subtotal REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        uuid_local TEXT,
        FOREIGN KEY (cosecha_id) REFERENCES cosechas(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createCosechaDetallesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cosecha_detalles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cosecha_id INTEGER NOT NULL,
        categoria TEXT,
        simbolo TEXT,
        posicion_fila INTEGER,
        cantidad_bultos INTEGER NOT NULL DEFAULT 0,
        peso_promedio_bulto_kg REAL,
        peso_kg REAL,
        precio_venta REAL,
        monto_parcial REAL,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        uuid_local TEXT,
        FOREIGN KEY (cosecha_id) REFERENCES cosechas(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createPlanillasTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS planillas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid_local TEXT NOT NULL,
        campana_id INTEGER NOT NULL,
        cultivo TEXT NOT NULL,
        tipo TEXT NOT NULL,
        fecha TEXT NOT NULL,
        mercado TEXT,
        transportista TEXT,
        notas TEXT,
        total_unidades INTEGER DEFAULT 0,
        total_peso REAL DEFAULT 0,
        estado TEXT DEFAULT 'guardada',
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (campana_id) REFERENCES campanas(id)
      )
    ''');
  }

  static Future<void> _seedDemoData(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert('users', {
      'id': 2,
      'nombre_completo': 'Carlos Mendoza',
      'email': 'agricultor@test.com',
      'telefono': '+51 987 654 321',
      'rol': 'propietario',
      'plan_suscripcion': 'premium',
      'tenant_id': 2,
      'password': 'password123',
    });

    await db.insert('users', {
      'id': 3,
      'nombre_completo': 'Maria Torres',
      'email': 'gratuito@test.com',
      'telefono': '+51 912 345 678',
      'rol': 'propietario',
      'plan_suscripcion': 'gratuito',
      'tenant_id': 1,
      'password': 'password123',
    });

    final terrenoPampa = await db.insert('terrenos', {
      'user_id': 2,
      'nombre': 'La Pampa',
      'tenencia': 'propio',
      'area': 2.5,
      'unidad': 'hectarea',
      'created_at': now,
      'updated_at': now,
    });

    final terrenoAlquilado = await db.insert('terrenos', {
      'user_id': 2,
      'nombre': 'Chacra del canal',
      'tenencia': 'alquilado',
      'area': 1.8,
      'unidad': 'hectarea',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('campanas', {
      'user_id': 2,
      'terreno_id': terrenoPampa,
      'fecha_siembra': '2025-01-25',
      'nombre': 'Tomate 2025',
      'cultivo': 'Tomate',
      'extension': 2.5,
      'tipo_extension': 'hectarea',
      'latitud': -12.0464,
      'longitud': -77.0428,
      'estado': 'activa',
      'fecha_inicio': '2025-01-15',
      'created_at': now,
    });

    await db.insert('campanas', {
      'user_id': 2,
      'terreno_id': terrenoAlquilado,
      'nombre': 'Cebolla 2025',
      'cultivo': 'Cebolla',
      'extension': 1.8,
      'tipo_extension': 'hectarea',
      'latitud': -12.0500,
      'longitud': -77.0400,
      'estado': 'activa',
      'fecha_inicio': '2025-03-01',
      'created_at': now,
    });

    await db.insert('campanas', {
      'user_id': 2,
      'terreno_id': terrenoPampa,
      'fecha_siembra': '2024-06-10',
      'nombre': 'Papa 2024',
      'cultivo': 'Papa',
      'extension': 3.0,
      'tipo_extension': 'hectarea',
      'estado': 'cerrada',
      'fecha_inicio': '2024-06-01',
      'fecha_cierre': '2024-12-20',
      'balance_neto_final': 15000.50,
      'created_at': now,
    });

    await db.insert('actividades', {
      'campana_id': 1,
      'descripcion': 'Aplicación de fertilizante NPK en parcela norte',
      'fecha': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
      'created_at': now,
    });

    await db.insert('actividades', {
      'campana_id': 1,
      'descripcion': 'Riego por goteo - zona sur verificada',
      'fecha': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
      'created_at': now,
    });

    await db.insert('actividades', {
      'campana_id': 1,
      'descripcion': 'Control de plagas - monitoreo de mosca blanca',
      'fecha': now,
      'created_at': now,
    });

    await db.insert('transacciones', {
      'campana_id': 1,
      'tipo': 'gasto',
      'categoria': 'Fertilizantes',
      'monto': 350.00,
      'descripcion': 'Compra de fertilizante NPK 15-15-15',
      'fecha': DateTime.now()
          .subtract(const Duration(days: 3))
          .toIso8601String(),
      'created_at': now,
    });

    await db.insert('transacciones', {
      'campana_id': 1,
      'tipo': 'gasto',
      'categoria': 'Mano de obra',
      'monto': 120.00,
      'descripcion': 'Jornaleros - siembra辅助',
      'fecha': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
      'created_at': now,
    });

    await db.insert('transacciones', {
      'campana_id': 1,
      'tipo': 'ingreso',
      'categoria': 'Venta',
      'monto': 2500.00,
      'descripcion': 'Venta parcial tomate cherry',
      'fecha': DateTime.now()
          .subtract(const Duration(hours: 12))
          .toIso8601String(),
      'created_at': now,
    });

    await db.insert('cosechas', {
      'campana_id': 1,
      'tipo_venta': 'mayorista',
      'cantidad_unidades': 500,
      'conductor': 'Juan Perez',
      'mercado_destino': 'Mercado Mayorista de Lima',
      'estado': 'pendiente',
      'precio_unitario': 3.50,
      'fecha_envio': DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String(),
      'created_at': now,
    });

    await db.insert('cosechas', {
      'campana_id': 1,
      'tipo_venta': 'minorista',
      'cantidad_unidades': 100,
      'mercado_destino': 'Tienda local',
      'estado': 'entregado',
      'precio_unitario': 5.00,
      'monto_neto_final': 500.00,
      'fecha_envio': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
      'fecha_liquidacion': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
      'fecha_cobro': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
      'created_at': now,
    });
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
