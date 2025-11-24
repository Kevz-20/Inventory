import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';

class StockInRepository {
  final Database db;
  StockInRepository(this.db);

  // Account cache
  int? cachedAccountId;
  int? cachedMobileNumber;

  // Get current timestamp
  String _now() => DateTime.now().toIso8601String();

  // Get mobile number
  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mobileNumber');
  }

  // Get account id
  Future<int> getAccountId() async {
    final mobileNumber = await getMobileNumber();
    if (mobileNumber == null) throw Exception('Account not found');

    if (cachedAccountId != null &&
        cachedMobileNumber != mobileNumber.hashCode) {
      cachedAccountId = null;
    }

    if (cachedAccountId != null) return cachedAccountId!;

    final result = await db.query(
      'account',
      columns: ['id'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
      limit: 1,
    );

    if (result.isEmpty) throw Exception('Account not found');

    cachedAccountId = result.first['id'] as int;
    cachedMobileNumber = mobileNumber.hashCode;
    return cachedAccountId!;
  }

  // Add product
  Future<int> addProduct(ProductModel product) async {
    final accountId = await getAccountId();
    final now = _now();

    final data = {
      'account_id': accountId,
      'name': product.name,
      'category': product.category,
      'purchase_price': product.purchasePrice,
      'selling_price': product.sellingPrice,
      'quantity': product.quantity,
      'image': product.image,
      'created_at': now,
      'updated_at': now,
    };

    return await db.insert(
      'product',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get products
  Future<List<ProductModel>> getProducts() async {
    final accountId = await getAccountId();

    final List<Map<String, dynamic>> maps = await db.query(
      'product',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'created_at DESC',
    );

    return maps.map(ProductModel.fromMap).toList();
  }

  // Update product
  Future<int> updateProduct(ProductModel product) async {
    final accountId = await getAccountId();
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
      where: 'id = ? AND account_id = ?',
      whereArgs: [product.id, accountId],
    );
  }

  // Delete product
  Future<int> deleteProduct(int productId) async {
    final accountId = await getAccountId();

    return await db.delete(
      'product',
      where: 'id = ? AND account_id = ?',
      whereArgs: [productId, accountId],
    );
  }

  // Check if product name already exists
  Future<bool> isDuplicateProduct(String name) async {
    final accountId = await getAccountId();

    final result = await db.query(
      'product',
      columns: ['id'],
      where: 'account_id = ? AND LOWER(name) = ?',
      whereArgs: [accountId, name.toLowerCase()],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // Load all products for autocomplete
  Future<List<ProductModel>> loadAllProducts() async {
    final accountId = await getAccountId();

    final result = await db.query(
      'product',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'name ASC',
    );

    return result.map(ProductModel.fromMap).toList();
  }

  // Delete all products
  Future<int> deleteAllProducts() async {
    final accountId = await getAccountId();

    return await db.delete(
      'product',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }

  // Clear cache
  void clearCache() {
    cachedAccountId = null;
    cachedMobileNumber = null;
  }
}
