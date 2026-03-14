import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';
import '../services/audit_log_service.dart';

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
      'category': product.category, // keep existing
      'category_id': product.categoryId, // ✅ NEW (supports product_category table)
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

    final productId = await db.insert(
      'product',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await AuditLogService.instance.log(
      module: 'stock_in_product',
      tableName: 'product',
      recordId: productId.toString(),
      action: 'create',
      newValue: data,
    );
    return productId;
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
    final previous = product.id == null
        ? null
        : await db.query(
            'product',
            where: 'id = ?',
            whereArgs: [product.id],
            limit: 1,
          );

    final data = {
      'name': product.name,
      'category': product.category, // keep existing
      'category_id': product.categoryId, // ✅ NEW
      'purchase_price': product.purchasePrice,
      'selling_price': product.sellingPrice,
      'quantity': product.quantity,
      'image': product.image,
      'updated_at': now,
    };

    final updated = await db.update(
      'product',
      data,
      where: 'id = ?',
      whereArgs: [product.id],
    );
    if (updated > 0) {
      await AuditLogService.instance.log(
        module: 'stock_in_product',
        tableName: 'product',
        recordId: product.id?.toString(),
        action: 'update',
        oldValue: previous?.isNotEmpty == true
            ? Map<String, dynamic>.from(previous!.first)
            : null,
        newValue: data,
      );
    }
    return updated;
  }

  // Delete product
  Future<int> deleteProduct(int productId) async {
    final previous = await db.query(
      'product',
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    final deleted = await db.delete(
      'product',
      where: 'id = ?',
      whereArgs: [productId],
    );
    if (deleted > 0) {
      await AuditLogService.instance.log(
        module: 'stock_in_product',
        tableName: 'product',
        recordId: productId.toString(),
        action: 'delete',
        oldValue: previous.isNotEmpty
            ? Map<String, dynamic>.from(previous.first)
            : null,
      );
    }
    return deleted;
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
    final products = await db.query('product');
    final deleted = await db.delete('product');
    if (deleted > 0) {
      await AuditLogService.instance.log(
        module: 'stock_in_product',
        tableName: 'product',
        action: 'bulk_delete',
        oldValue: {
          'count': deleted,
          'records': products,
        },
      );
    }
    return deleted;
  }

  // Clear cache (no longer needed for accountId)
  void clearCache() {}
}
