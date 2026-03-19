import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';
import '../models/product_selling_option.dart';
import '../models/product_unit_conversion.dart';
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
      'base_unit': product.baseUnit,
      'cost_per_unit': product.costPerUnit,
      'price_per_unit': product.pricePerUnit,
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
      'base_unit': product.baseUnit,
      'cost_per_unit': product.costPerUnit,
      'price_per_unit': product.pricePerUnit,
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

  Future<List<String>> getBaseUnits() async {
    final rows = await db.query(
      'base_unit_choice',
      columns: ['name'],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map((row) => (row['name'] ?? '').toString()).toList();
  }

  Future<void> addBaseUnit(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    await db.insert('base_unit_choice', {
      'name': trimmed,
      'created_at': _now(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> updateBaseUnit(String previousName, String nextName) async {
    final oldTrimmed = previousName.trim();
    final newTrimmed = nextName.trim();
    if (oldTrimmed.isEmpty || newTrimmed.isEmpty) return;

    await db.update(
      'base_unit_choice',
      {
        'name': newTrimmed,
      },
      where: 'LOWER(name) = ?',
      whereArgs: [oldTrimmed.toLowerCase()],
    );
  }

  Future<void> deleteBaseUnit(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    await db.delete(
      'base_unit_choice',
      where: 'LOWER(name) = ?',
      whereArgs: [trimmed.toLowerCase()],
    );
  }

  Future<List<ProductUnitConversion>> getUnitConversions(int productId) async {
    final rows = await db.query(
      'product_unit_conversion',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'base_quantity DESC, unit_name ASC',
    );

    return rows.map(ProductUnitConversion.fromMap).toList();
  }

  Future<void> replaceUnitConversions(
    int productId,
    List<ProductUnitConversion> conversions,
  ) async {
    final now = _now();

    await db.transaction((txn) async {
      await txn.delete(
        'product_unit_conversion',
        where: 'product_id = ?',
        whereArgs: [productId],
      );

      for (final conversion in conversions) {
        await txn.insert('product_unit_conversion', {
          'product_id': productId,
          'unit_name': conversion.unitName.trim(),
          'base_quantity': conversion.baseQuantity,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  Future<List<ProductSellingOption>> getSellingOptions(int productId) async {
    final rows = await db.query(
      'product_selling_option',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'base_quantity DESC, label ASC',
    );

    return rows.map(ProductSellingOption.fromMap).toList();
  }

  Future<void> replaceSellingOptions(
    int productId,
    List<ProductSellingOption> options,
  ) async {
    final now = _now();

    await db.transaction((txn) async {
      await txn.delete(
        'product_selling_option',
        where: 'product_id = ?',
        whereArgs: [productId],
      );

      for (final option in options) {
        await txn.insert('product_selling_option', {
          'product_id': productId,
          'label': option.label.trim(),
          'mode': option.mode.trim(),
          'unit_name': option.unitName?.trim(),
          'base_quantity': option.baseQuantity,
          'price': option.price,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
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
