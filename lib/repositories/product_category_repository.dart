import 'package:sqflite/sqflite.dart';

class ProductCategoryRepository {
  final Database db;
  ProductCategoryRepository(this.db);

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    return await db.query(
      'product_category',
      columns: ['id', 'name'],
      orderBy: 'name ASC',
    );
  }

  /// Inserts category if not exists, then returns its id.
  Future<int> getOrCreateCategoryId(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Category name cannot be empty');
    }

    // 1) Try find existing
    final existing = await db.query(
      'product_category',
      columns: ['id'],
      where: 'LOWER(name) = ?',
      whereArgs: [trimmed.toLowerCase()],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    // 2) Insert new
    final id = await db.insert(
      'product_category',
      {
        'name': trimmed,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // If insert was ignored (rare race), query again
    if (id == 0) {
      final again = await db.query(
        'product_category',
        columns: ['id'],
        where: 'LOWER(name) = ?',
        whereArgs: [trimmed.toLowerCase()],
        limit: 1,
      );
      if (again.isNotEmpty) return again.first['id'] as int;
    }

    return id;
  }

  /// (Optional alias) If your ViewModel uses insertOrGetCategoryId, keep this too.
  Future<int> insertOrGetCategoryId(String name) => getOrCreateCategoryId(name);
}