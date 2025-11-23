import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';

class StockInRepository {
  final Database db;
  StockInRepository(this.db);

  // Cache account id
  int? cachedAccountId;

  // Cache mobile number
  int? cachedModileNumber;

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
        cachedModileNumber != mobileNumber.hashCode) {
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
    cachedModileNumber = mobileNumber.hashCode;
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

  void clearCache() {
    cachedAccountId = null;
    cachedModileNumber = null;
  }
}
