import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';

class StockInRepository {
  final Database db;
  StockInRepository(this.db);

  // Get current timestamp
  String _now() => DateTime.now().toIso8601String();

  // Get mobile number
  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mobileNumber');
  }

  // Add product
  Future<int> addProduct(ProductModel product) async {
    final now = _now();

    final data = {
      'name': product.name,
      'category': product.category,
      'purchase_price': product.purchasePrice,
      'selling_price': product.sellingPrice,
      'quantity': product.quantity,
      'image': product.image,
      'created_at': now,
      'updated_at': now,
      // Optional accountability fields:
      // 'created_by_first_name': 'John',
      // 'created_by_middle_name': 'D.',
      // 'created_by_last_name': 'Doe',
    };

    return await db.insert(
      'product',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get products
  Future<List<ProductModel>> getProducts() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'product',
      orderBy: 'created_at DESC',
    );

    return maps.map(ProductModel.fromMap).toList();
  }

  // Update product
  Future<int> updateProduct(ProductModel product) async {
    final now = _now();

    final data = {
      'name': product.name,
      'category': product.category,
      'purchase_price': product.purchasePrice,
      'selling_price': product.sellingPrice,
      'quantity': product.quantity,
      'image': product.image,
      'updated_at': now,
    };

    return await db.update(
      'product',
      data,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Delete product
  Future<int> deleteProduct(int productId) async {
    return await db.delete(
      'product',
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Check if product name already exists
  Future<bool> isDuplicateProduct(String name) async {
    final result = await db.query(
      'product',
      columns: ['id'],
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase()],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // Load all products for autocomplete
  Future<List<ProductModel>> loadAllProducts() async {
    final result = await db.query(
      'product',
      orderBy: 'name ASC',
    );

    return result.map(ProductModel.fromMap).toList();
  }

  // Delete all products
  Future<int> deleteAllProducts() async {
    return await db.delete('product');
  }

  // Clear cache (no longer needed for accountId)
  void clearCache() {}
}
