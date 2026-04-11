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

  Future<int> updateCategory(String previousName, String nextName) async {
    final previousTrimmed = previousName.trim();
    final nextTrimmed = nextName.trim();
    if (previousTrimmed.isEmpty || nextTrimmed.isEmpty) {
      throw Exception('Category name cannot be empty');
    }

    final duplicate = await db.query(
      'product_category',
      columns: ['id'],
      where: 'LOWER(name) = ? AND LOWER(name) != ?',
      whereArgs: [nextTrimmed.toLowerCase(), previousTrimmed.toLowerCase()],
      limit: 1,
    );
    if (duplicate.isNotEmpty) {
      throw Exception('Category already exists');
    }

    await db.transaction((txn) async {
      await txn.update(
        'product_category',
        {'name': nextTrimmed},
        where: 'LOWER(name) = ?',
        whereArgs: [previousTrimmed.toLowerCase()],
      );

      await txn.update(
        'product',
        {'category': nextTrimmed},
        where: 'LOWER(category) = ?',
        whereArgs: [previousTrimmed.toLowerCase()],
      );
    });

    return 1;
  }

  Future<int> countProductsUsingCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 0;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*) FROM product
        WHERE LOWER(category) = ?
        ''',
        [trimmed.toLowerCase()],
      ),
    );
    return result ?? 0;
  }

  Future<int> deleteCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 0;

    final usageCount = await countProductsUsingCategory(trimmed);
    if (usageCount > 0) {
      throw Exception('Category is still used by existing products');
    }

    return db.delete(
      'product_category',
      where: 'LOWER(name) = ?',
      whereArgs: [trimmed.toLowerCase()],
    );
  }
}
