import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';

/// Clase Singleton para la administración de la base de datos local SQLite con SQFlite.
/// Maneja creación de tablas, migraciones, inicialización de datos de prueba (Seed),
/// y persistencia de la sesión activa del usuario.
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'percucol_store.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
      // Habilitar soporte de foreign keys en cada conexión nueva
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _ensureAllTablesExist(db);
  }

  Future<void> _onOpen(Database db) async {
    await _ensureAllTablesExist(db);
  }

  Future<void> _ensureAllTablesExist(Database db) async {
    // 1. users
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        role TEXT NOT NULL DEFAULT 'client',
        createdAt TEXT NOT NULL
      )
    ''');

    // 2. categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        iconName TEXT NOT NULL DEFAULT 'drum',
        colorHex TEXT NOT NULL DEFAULT '0xFFD4881A'
      )
    ''');

    // 3. products
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        categoryId INTEGER NOT NULL,
        imageUrl TEXT,
        rating REAL DEFAULT 4.8,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // 4. active_session
    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        userId INTEGER NOT NULL,
        token TEXT,
        loggedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 5. sales
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        userName TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 6. sale_items
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        unitPrice REAL NOT NULL,
        quantity INTEGER NOT NULL,
        productImageUrl TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');
    // Migración: agregar columna productImageUrl si la tabla ya existe sin ella
    try {
      await db.execute("ALTER TABLE sale_items ADD COLUMN productImageUrl TEXT NOT NULL DEFAULT ''");
    } catch (_) {
      // Columna ya existe — no hacer nada
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await _ensureAllTablesExist(db);
    // Semilla de datos iniciales
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Usuarios iniciales (Admin y Cliente)
    await db.insert('users', {
      'name': 'Administrador Percucol',
      'email': 'admin@percucol.com',
      'password': 'admin123',
      'phone': '+57 310 555 0199',
      'address': 'Cra. 7 #72-10, Bogotá, Colombia',
      'role': 'admin',
      'createdAt': now,
    });

    await db.insert('users', {
      'name': 'Carlos Rivera (Percusionista)',
      'email': 'cliente@percucol.com',
      'password': 'cliente123',
      'phone': '+57 301 444 8822',
      'address': 'Calle 85 #14-20, Bogotá, Colombia',
      'role': 'client',
      'createdAt': now,
    });

    // Categorías de Percusión
    final catBateriasId = await db.insert('categories', {
      'name': 'Baterías Acústicas',
      'description': 'Kits completos y tambores profesionales para estudio y escenario.',
      'iconName': 'drum_set',
      'colorHex': '0xFFD4881A',
    });

    final catLatinaId = await db.insert('categories', {
      'name': 'Percusión Latina',
      'description': 'Congas, bongós, timbales y cajones de resonancia profunda.',
      'iconName': 'congas',
      'colorHex': '0xFFE5A93C',
    });

    final catFolclorId = await db.insert('categories', {
      'name': 'Percusión Folclórica Colombiana',
      'description': 'Tambora caribeña, tambor alegre, llamador y maracones de tradición.',
      'iconName': 'folklore',
      'colorHex': '0xFFA66A2C',
    });

    final catMenorId = await db.insert('categories', {
      'name': 'Percusión Menor & Shakers',
      'description': 'Maracas, güiros, cencerros metálicos y panderetas afinadas.',
      'iconName': 'shaker',
      'colorHex': '0xFF10B981',
    });

    final catPlatillosId = await db.insert('categories', {
      'name': 'Platillos & Herrajes',
      'description': 'Aleaciones B20 martilladas a mano, stands reforzados y pedales.',
      'iconName': 'cymbal',
      'colorHex': '0xFF3B82F6',
    });

    // Productos iniciales con stocks variados (incluyendo agotados para pruebas de UX)
    final initialProducts = [
      {
        'name': 'Set de Congas LP Classic Madera de Roble',
        'description': 'Juego de Quinto 11" y Conga 11 3/4" con aros Comfort Curve II y parches de cuero crudo seleccionado.',
        'price': 3450000.0,
        'stock': 4,
        'categoryId': catLatinaId,
        'imageUrl': 'https://images.unsplash.com/photo-1519892300165-cb5542fb47c7?auto=format&fit=crop&w=600&q=80',
        'rating': 4.9,
      },
      {
        'name': 'Tambor Alegre Costeño 24" Ceiba y Cuero Chivo',
        'description': 'Tambor alegre artesanal elaborado por luthiers de San Pelayo. Calado en tronco de ceiba maciza y entorchado tradicional.',
        'price': 480000.0,
        'stock': 8,
        'categoryId': catFolclorId,
        'imageUrl': 'https://images.unsplash.com/photo-1543791187-df796fa11835?auto=format&fit=crop&w=600&q=80',
        'rating': 5.0,
      },
      {
        'name': 'Batería DW Collector\'s Series Maple 5 Piezas',
        'description': 'Kit maestro en maple norteamericano con tecnología SSC. Acabado lacado Black Oyster y herrajes cromados de alta precisión.',
        'price': 18500000.0,
        'stock': 2,
        'categoryId': catBateriasId,
        'imageUrl': 'https://images.unsplash.com/photo-1519892300165-cb5542fb47c7?auto=format&fit=crop&w=600&q=80',
        'rating': 5.0,
      },
      {
        'name': 'Cajón Flamenco LP Matador Dark Brown',
        'description': 'Cuerpo de abedul con bordonas ajustables y sistema de trampa interna. Graves potentes y agudos cortantes para sesión acústica.',
        'price': 690000.0,
        'stock': 6,
        'categoryId': catLatinaId,
        'imageUrl': 'https://images.unsplash.com/photo-1520523839898-507129c54c3d?auto=format&fit=crop&w=600&q=80',
        'rating': 4.8,
      },
      {
        'name': 'Tambora Tradicional Ribereña 16" Cuero Doble',
        'description': 'Tambora folclórica de golpe y respuesta con aros de encavado a mano y golpeador de totumo forrado en badana.',
        'price': 520000.0,
        'stock': 0, // ¡AGOTADO PARA DEMOSTRACIÓN DE UX!
        'categoryId': catFolclorId,
        'imageUrl': 'https://images.unsplash.com/photo-1543791187-df796fa11835?auto=format&fit=crop&w=600&q=80',
        'rating': 4.7,
      },
      {
        'name': 'Timbales Tito Puente Signature 14" & 15" Latón Dorado',
        'description': 'Cascos de latón macizo acanalados con soporte inclinable extra estable y campana cha-cha incluida.',
        'price': 2680000.0,
        'stock': 0, // ¡AGOTADO PARA DEMOSTRACIÓN DE UX!
        'categoryId': catLatinaId,
        'imageUrl': 'https://images.unsplash.com/photo-1519892300165-cb5542fb47c7?auto=format&fit=crop&w=600&q=80',
        'rating': 4.9,
      },
      {
        'name': 'Juego de Maracas Llaneras de Capacho Especial',
        'description': 'Par de maracas artesanales en calabazo curado con semillas de capacho seleccionadas para un sonido seco y brillante.',
        'price': 1350000.0,
        'stock': 15,
        'categoryId': catMenorId,
        'imageUrl': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=600&q=80',
        'rating': 4.8,
      },
      {
        'name': 'Platillo Crash Sabian HHX Evolution 18" O-Zone',
        'description': 'Diseñado junto a Dave Weckl. Agujeros de ventilación para una respuesta explosiva y sustain rápido y oscuro.',
        'price': 1850000.0,
        'stock': 3,
        'categoryId': catPlatillosId,
        'imageUrl': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=600&q=80',
        'rating': 4.9,
      },
      {
        'name': 'Tambor Llamador Colombiano Cuero de Venado',
        'description': 'Pieza indispensable para el patrón rítmico del bullerengue y la cumbia. Construcción en madera de bonga centenaria.',
        'price': 310000.0,
        'stock': 7,
        'categoryId': catFolclorId,
        'imageUrl': 'https://images.unsplash.com/photo-1543791187-df796fa11835?auto=format&fit=crop&w=600&q=80',
        'rating': 4.9,
      },
    ];

    for (final prod in initialProducts) {
      await db.insert('products', prod);
    }
  }

  // ==========================================
  // GESTIÓN DE SESIÓN ACTIVA (PERSISTENCIA)
  // ==========================================

  Future<void> saveActiveSession(int userId) async {
    final db = await database;
    await db.insert(
      'active_session',
      {
        'id': 1,
        'userId': userId,
        'token': 'session_token_${DateTime.now().millisecondsSinceEpoch}',
        'loggedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> getActiveSessionUserId() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'active_session',
      where: 'id = 1',
    );
    if (maps.isNotEmpty) {
      return maps.first['userId'] as int?;
    }
    return null;
  }

  Future<void> clearActiveSession() async {
    final db = await database;
    await db.delete('active_session', where: 'id = 1');
  }

  // ==========================================
  // OPERACIONES CRUD: USUARIOS
  // ==========================================

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase().trim()],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'id DESC');
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // OPERACIONES CRUD: CATEGORÍAS
  // ==========================================

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'id ASC');
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    // Con PRAGMA foreign_keys = ON activo, el ON DELETE CASCADE de products
    // elimina automáticamente los productos de esta categoría.
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // OPERACIONES CRUD: PRODUCTOS
  // ==========================================

  Future<int> insertProduct(ProductModel product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<ProductModel>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'id DESC');
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<List<ProductModel>> getProductsByCategory(int categoryId) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'id DESC',
    );
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> decrementProductStock(int productId, int quantity) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?',
      [quantity, productId],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Obtiene el ID del usuario invitado genérico (lo crea si no existe).
  /// Así las compras sin sesión siempre tienen un userId válido en la FK.
  Future<int> getOrCreateGuestUserId() async {
    const guestEmail = 'guest@percucol.com';
    final existing = await getUserByEmail(guestEmail);
    if (existing != null && existing.id != null) {
      return existing.id!;
    }
    return await insertUser(UserModel(
      name: 'Invitado',
      email: guestEmail,
      password: '',
      phone: '',
      address: '',
      role: 'client',
      createdAt: DateTime.now().toIso8601String(),
    ));
  }
  Future<void> resetDatabase() async {
    final db = await database;
    await db.delete('active_session');
    await db.delete('sale_items');
    await db.delete('sales');
    await db.delete('products');
    await db.delete('categories');
    await db.delete('users');
    await _seedInitialData(db);
  }

  // ==========================================
  // OPERACIONES CRUD: VENTAS
  // ==========================================

  /// Ejecuta una compra completa de forma 100% ATÓMICA:
  /// 1. Verifica en SQLite que haya stock suficiente para cada producto.
  /// 2. Inserta el registro de la venta en 'sales'.
  /// 3. Inserta cada producto en 'sale_items'.
  /// 4. Descuenta el stock físico SOLO si los pasos anteriores tuvieron éxito.
  /// Si ocurre CUALQUIER error, se hace ROLLBACK automático completo.
  /// ¡El stock NUNCA se descuenta a menos que la venta se complete con éxito!
  Future<int> executeAtomicPurchase({
    required SaleModel sale,
    required List<SaleItemModel> items,
  }) async {
    final db = await database;
    return await db.transaction<int>((txn) async {
      // Paso 1: Validar existencias ANTES de tocar nada
      for (final item in items) {
        final List<Map<String, dynamic>> res = await txn.query(
          'products',
          columns: ['id', 'name', 'stock'],
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        if (res.isEmpty) {
          throw Exception('El producto "${item.productName}" no fue encontrado en el catálogo.');
        }

        final availableStock = (res.first['stock'] as num).toInt();
        if (availableStock < item.quantity) {
          throw Exception(
            'Stock insuficiente para "${item.productName}". '
            'Disponibles: $availableStock, solicitados: ${item.quantity}.',
          );
        }
      }

      // Paso 2: Registrar la venta (cabecera)
      final saleId = await txn.insert('sales', sale.toMap());

      // Paso 3: Registrar ítems de la venta
      for (final item in items) {
        await txn.insert('sale_items', SaleItemModel(
          saleId: saleId,
          productId: item.productId,
          productName: item.productName,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
        ).toMap());
      }

      // Paso 4: Descontar stock SOLO si la venta quedó registrada correctamente
      for (final item in items) {
        final updated = await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ? AND stock >= ?',
          [item.quantity, item.productId, item.quantity],
        );
        // Si no se actualizó ninguna fila, significa que el stock cambió entre
        // la validación y el update (race condition). Lanzamos excepción para rollback.
        if (updated == 0) {
          throw Exception(
            'No se pudo descontar el stock de "${item.productName}". '
            'Puede que el stock cambió mientras procesabas la compra.',
          );
        }
      }

      return saleId;
    });
  }

  /// Restablece stock agotado para pruebas
  Future<void> restockProducts() async {
    final db = await database;
    await db.rawUpdate('UPDATE products SET stock = 6 WHERE stock <= 0');
  }

  /// Crea una venta con sus ítems en una sola transacción atómica
  Future<int> insertSaleWithItems(SaleModel sale, List<SaleItemModel> items) async {
    final db = await database;
    int saleId = 0;
    await db.transaction((txn) async {
      saleId = await txn.insert('sales', sale.toMap());
      for (final item in items) {
        final itemMap = SaleItemModel(
          saleId: saleId,
          productId: item.productId,
          productName: item.productName,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
        ).toMap();
        await txn.insert('sale_items', itemMap);
      }
    });
    return saleId;
  }

  /// Obtiene todas las ventas ordenadas por fecha descendente
  Future<List<SaleModel>> getAllSales() async {
    final db = await database;
    final saleMaps = await db.query('sales', orderBy: 'id DESC');
    final List<SaleModel> sales = [];
    for (final map in saleMaps) {
      final saleId = map['id'] as int;
      final itemMaps = await db.query(
        'sale_items',
        where: 'saleId = ?',
        whereArgs: [saleId],
      );
      final items = itemMaps.map((m) => SaleItemModel.fromMap(m)).toList();
      sales.add(SaleModel.fromMap(map).copyWith(items: items));
    }
    return sales;
  }

  /// Obtiene ventas de un usuario específico
  Future<List<SaleModel>> getSalesByUser(int userId) async {
    final db = await database;
    final saleMaps = await db.query(
      'sales',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    final List<SaleModel> sales = [];
    for (final map in saleMaps) {
      final saleId = map['id'] as int;
      final itemMaps = await db.query(
        'sale_items',
        where: 'saleId = ?',
        whereArgs: [saleId],
      );
      final items = itemMaps.map((m) => SaleItemModel.fromMap(m)).toList();
      sales.add(SaleModel.fromMap(map).copyWith(items: items));
    }
    return sales;
  }

  /// Actualiza el estado de una venta
  Future<int> updateSaleStatus(int saleId, String newStatus) async {
    final db = await database;
    return await db.update(
      'sales',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  /// Elimina una venta (los items se eliminan por CASCADE)
  Future<int> deleteSale(int saleId) async {
    final db = await database;
    return await db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
  }

  /// Métricas: total de ingresos y número de ventas
  Future<Map<String, dynamic>> getSalesMetrics() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as totalSales, SUM(totalAmount) as totalRevenue FROM sales WHERE status != ?',
      ['cancelled'],
    );
    return {
      'totalSales': result.first['totalSales'] ?? 0,
      'totalRevenue': result.first['totalRevenue'] ?? 0.0,
    };
  }
}

