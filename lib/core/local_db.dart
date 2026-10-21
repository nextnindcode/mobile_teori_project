import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDb {
  static Database? _db;

  // ===== BUKA DATABASE =====
  static Future<Database> get database async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'eclipseverse.db');

    _db = await openDatabase(path, version: 1, onCreate: _onCreate);

    return _db!;
  }

  // ===== BIKIN TABEL (dipanggil saat pertama kali) =====
  static Future<void> _onCreate(Database db, int version) async {
    // 1. Cart
    await db.execute('''
      CREATE TABLE cart_local (
        product_id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        quantity INTEGER NOT NULL
      )
    ''');

    // 2. Preferences
    await db.execute('''
      CREATE TABLE preferences (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // 3. Members Cache
    await db.execute('''
      CREATE TABLE members_cache (
        id INTEGER PRIMARY KEY,
        json TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // 4. User Profile
    await db.execute('''
      CREATE TABLE user_profile (
        user_id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL
      )
    ''');
  }

  // ===== CART =====
  static Future<List<Map<String, dynamic>>> getCart() async {
    final db = await database;
    return db.query('cart_local');
  }

  static Future<void> addToCart({
    required int productId,
    required String name,
    required int price,
    int quantity = 1,
  }) async {
    final db = await database;
    final existing = await db.query(
      'cart_local',
      where: 'product_id = ?',
      whereArgs: [productId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final currentQuantity = (existing.first['quantity'] as num).toInt();
      await db.update(
        'cart_local',
        {'quantity': currentQuantity + quantity},
        where: 'product_id = ?',
        whereArgs: [productId],
      );
      return;
    }

    await db.insert('cart_local', {
      'product_id': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
    });
  }

  static Future<void> updateQuantity(int productId, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      await db.delete(
        'cart_local',
        where: 'product_id = ?',
        whereArgs: [productId],
      );
    } else {
      await db.update(
        'cart_local',
        {'quantity': quantity},
        where: 'product_id = ?',
        whereArgs: [productId],
      );
    }
  }

  static Future<void> clearCart() async {
    final db = await database;
    await db.delete('cart_local');
  }

  // ===== PREFERENCES =====
  static Future<String?> getPreference(String key) async {
    final db = await database;
    final result = await db.query(
      'preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  static Future<void> setPreference(String key, String value) async {
    final db = await database;
    await db.insert('preferences', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> getPref(String key) => getPreference(key);
  static Future<void> setPref(String key, String value) =>
      setPreference(key, value);

  // ===== MEMBERS CACHE =====
  static Future<void> cacheMembers(List<Map<String, dynamic>> members) =>
      saveMembers(members);

  static Future<void> saveMembers(List<Map<String, dynamic>> members) async {
    final db = await database;
    await db.delete('members_cache');
    for (final m in members) {
      await db.insert('members_cache', {
        'id': m['id'],
        'json': jsonEncode(m),
        'cached_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Future<List<Map<String, dynamic>>> getCachedMembers() async {
    final db = await database;
    return db.query('members_cache');
  }

  static Future<List<Map<String, dynamic>>> getMembers() async {
    final db = await database;
    final rows = await db.query('members_cache');
    return rows
        .map((r) => jsonDecode(r['json'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ===== USER PROFILE =====
  static Future<void> saveProfile({
    required int userId,
    required String name,
    required String email,
  }) async {
    final db = await database;
    await db.insert('user_profile', {
      'user_id': userId,
      'name': name,
      'email': email,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final db = await database;
    final result = await db.query('user_profile', limit: 1);
    if (result.isEmpty) return null;
    return result.first;
  }

  static Future<Map<String, dynamic>?> getUserProfile() => getProfile();

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('cart_local');
    await db.delete('preferences');
    await db.delete('members_cache');
    await db.delete('user_profile');
  }
}
