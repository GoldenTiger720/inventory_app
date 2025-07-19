import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/inventory_item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'inventory_sales.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        cost REAL,
        current_quantity INTEGER NOT NULL,
        location TEXT,
        unit TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create inventory_counts table
    await db.execute('''
      CREATE TABLE inventory_counts (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        expected_quantity INTEGER NOT NULL,
        counted_quantity INTEGER,
        status TEXT NOT NULL,
        location TEXT,
        counted_at TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Create order_items table
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        user_id TEXT NOT NULL,
        added_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Insert sample products
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // Sample products
    final sampleProducts = [
      {
        'id': 'prod_001',
        'code': '1234567890',
        'name': 'Apple iPhone 14',
        'description': 'Latest iPhone with A15 Bionic chip',
        'price': 999.99,
        'cost': 750.00,
        'current_quantity': 50,
        'location': 'A1-B2',
        'unit': 'pcs',
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'prod_002',
        'code': '2345678901',
        'name': 'Samsung Galaxy S23',
        'description': 'Premium Android smartphone',
        'price': 899.99,
        'cost': 650.00,
        'current_quantity': 35,
        'location': 'A2-C1',
        'unit': 'pcs',
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'prod_003',
        'code': '3456789012',
        'name': 'iPad Pro 12.9"',
        'description': 'Professional tablet with M2 chip',
        'price': 1299.99,
        'cost': 950.00,
        'current_quantity': 20,
        'location': 'B1-A3',
        'unit': 'pcs',
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'prod_004',
        'code': '4567890123',
        'name': 'MacBook Air M2',
        'description': 'Lightweight laptop with Apple Silicon',
        'price': 1199.99,
        'cost': 900.00,
        'current_quantity': 15,
        'location': 'C1-D2',
        'unit': 'pcs',
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'prod_005',
        'code': '5678901234',
        'name': 'AirPods Pro',
        'description': 'Noise-cancelling wireless earbuds',
        'price': 249.99,
        'cost': 150.00,
        'current_quantity': 100,
        'location': 'D1-E1',
        'unit': 'pcs',
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final product in sampleProducts) {
      await db.insert('products', product);
    }
  }

  // Password hashing
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // User operations
  Future<User?> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final passwordHash = _hashPassword(password);
    final now = DateTime.now().toIso8601String();

    try {
      await db.insert('users', {
        'id': id,
        'email': email,
        'password_hash': passwordHash,
        'name': name,
        'role': role,
        'created_at': now,
        'updated_at': now,
      });

      return User(
        id: id,
        email: email,
        name: name,
        role: role,
        accessToken: _generateToken(id),
        refreshToken: _generateToken('$id-refresh'),
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('User with this email already exists');
      }
      throw Exception('Failed to create user: $e');
    }
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    final passwordHash = _hashPassword(password);

    final results = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, passwordHash],
    );

    if (results.isEmpty) {
      return null;
    }

    final userData = results.first;
    return User(
      id: userData['id'] as String,
      email: userData['email'] as String,
      name: userData['name'] as String,
      role: userData['role'] as String,
      accessToken: _generateToken(userData['id'] as String),
      refreshToken: _generateToken('${userData['id']}-refresh'),
    );
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) {
      return null;
    }

    final userData = results.first;
    return User(
      id: userData['id'] as String,
      email: userData['email'] as String,
      name: userData['name'] as String,
      role: userData['role'] as String,
    );
  }

  // Product operations
  Future<Product?> getProductByCode(String code) async {
    final db = await database;
    final results = await db.query(
      'products',
      where: 'code = ?',
      whereArgs: [code],
    );

    if (results.isEmpty) {
      return null;
    }

    return Product.fromJson(Map<String, dynamic>.from(results.first));
  }

  Future<List<Product>> searchProductsByDescription(String description) async {
    final db = await database;
    final results = await db.query(
      'products',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$description%', '%$description%'],
    );

    return results.map((row) => Product.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    final db = await database;
    updates['updated_at'] = DateTime.now().toIso8601String();
    
    await db.update(
      'products',
      updates,
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Inventory operations
  Future<List<InventoryItem>> getInventoryItemsForCounting() async {
    final db = await database;
    
    // Get all products for counting
    final products = await db.query('products', where: 'is_active = 1');
    
    final inventoryItems = <InventoryItem>[];
    for (final productData in products) {
      final product = Product.fromJson(Map<String, dynamic>.from(productData));
      
      // Check if there's an existing count for this product
      final countResults = await db.query(
        'inventory_counts',
        where: 'product_id = ? AND status = ?',
        whereArgs: [product.id, 'pending'],
      );
      
      if (countResults.isNotEmpty) {
        final countData = countResults.first;
        inventoryItems.add(InventoryItem(
          id: countData['id'] as String,
          product: product,
          expectedQuantity: product.currentQuantity,
          countedQuantity: countData['counted_quantity'] as int?,
          status: CountingStatus.pending,
          location: countData['location'] as String?,
          countedAt: countData['counted_at'] != null 
              ? DateTime.parse(countData['counted_at'] as String)
              : null,
          notes: countData['notes'] as String?,
        ));
      } else {
        // Create a new inventory count entry
        final countId = DateTime.now().millisecondsSinceEpoch.toString();
        inventoryItems.add(InventoryItem(
          id: countId,
          product: product,
          expectedQuantity: product.currentQuantity,
          status: CountingStatus.pending,
          location: product.location,
        ));
      }
    }
    
    return inventoryItems;
  }

  Future<List<InventoryItem>> getCountedItems() async {
    final db = await database;
    
    final results = await db.rawQuery('''
      SELECT 
        ic.*,
        p.id as product_id,
        p.code as product_code,
        p.name as product_name,
        p.description as product_description,
        p.price as product_price,
        p.cost as product_cost,
        p.current_quantity as product_current_quantity,
        p.location as product_location,
        p.unit as product_unit,
        p.is_active as product_is_active
      FROM inventory_counts ic
      JOIN products p ON ic.product_id = p.id
      WHERE ic.status = 'counted' OR ic.status = 'confirmed'
    ''');
    
    return results.map((row) {
      final product = Product(
        id: row['product_id'] as String,
        code: row['product_code'] as String,
        name: row['product_name'] as String,
        description: row['product_description'] as String,
        price: (row['product_price'] as num).toDouble(),
        cost: row['product_cost'] != null ? (row['product_cost'] as num).toDouble() : null,
        currentQuantity: row['product_current_quantity'] as int,
        location: row['product_location'] as String?,
        unit: row['product_unit'] as String?,
        isActive: (row['product_is_active'] as int) == 1,
      );
      
      return InventoryItem(
        id: row['id'] as String,
        product: product,
        expectedQuantity: row['expected_quantity'] as int,
        countedQuantity: row['counted_quantity'] as int?,
        status: _parseCountingStatus(row['status'] as String),
        location: row['location'] as String?,
        countedAt: row['counted_at'] != null 
            ? DateTime.parse(row['counted_at'] as String)
            : null,
        notes: row['notes'] as String?,
      );
    }).toList();
  }

  Future<void> updateInventoryCount(String itemId, int countedQuantity) async {
    final db = await database;
    final now = DateTime.now();
    
    // Check if the count exists
    final existing = await db.query(
      'inventory_counts',
      where: 'id = ?',
      whereArgs: [itemId],
    );
    
    if (existing.isEmpty) {
      // Create new count record
      await db.insert('inventory_counts', {
        'id': itemId,
        'product_id': itemId, // Assuming itemId is the product ID for new counts
        'expected_quantity': countedQuantity,
        'counted_quantity': countedQuantity,
        'status': 'counted',
        'counted_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    } else {
      // Update existing count
      await db.update(
        'inventory_counts',
        {
          'counted_quantity': countedQuantity,
          'status': 'counted',
          'counted_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );
    }
  }

  // Order operations
  Future<void> addToOrderQueue(String productId, int quantity, String userId) async {
    final db = await database;
    final product = await getProductByCode(productId);
    
    if (product == null) {
      throw Exception('Product not found');
    }
    
    await db.insert('order_items', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'product_id': product.id,
      'quantity': quantity,
      'unit_price': product.price,
      'user_id': userId,
      'added_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFromOrderQueue(String orderId) async {
    final db = await database;
    await db.delete(
      'order_items',
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // Helper methods
  String _generateToken(String seed) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode('$seed-$timestamp');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  CountingStatus _parseCountingStatus(String status) {
    switch (status) {
      case 'counted':
        return CountingStatus.counted;
      case 'confirmed':
        return CountingStatus.confirmed;
      default:
        return CountingStatus.pending;
    }
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}