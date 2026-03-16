import 'package:sqflite/sqflite.dart';

class ExpenseCategoryRepository {
  final Database db;
  ExpenseCategoryRepository(this.db);

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    return db.query(
      'expense_category',
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  Future<int> getOrCreateCategoryId(String name) async {
    final trimmed = name.trim();
    final existing = await db.query(
      'expense_category',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [trimmed],
      limit: 1,
    );

    if (existing.isNotEmpty) return existing.first['id'] as int;

    return await db.insert('expense_category', {
      'name': trimmed,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}