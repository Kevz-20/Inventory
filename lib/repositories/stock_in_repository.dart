import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product_model.dart';
import '../services/supabase_service.dart';

class StockInRepository {
  final Database db;
  StockInRepository(this.db);

  String _now() => DateTime.now().toIso8601String();

  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mobileNumber');
  }

  Future<bool> _isBackendMode() async {
    final prefs = await SharedPreferences.getInstance();
    return SupabaseService.isConfigured &&
        (prefs.getString('selectedOrganizationId')?.isNotEmpty ?? false);
  }

  Future<String?> _selectedOrganizationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedOrganizationId');
  }

  Future<void> _upsertLocalProduct(ProductModel product) async {
    final existing = await db.query(
      'product',
      columns: ['id'],
      where: 'LOWER(name) = ? AND COALESCE(category_id, -1) = ?',
      whereArgs: [product.name.toLowerCase(), product.categoryId ?? -1],
      limit: 1,
    );

    final data = {
      'name': product.name,
      'category': product.category,
      'category_id': product.categoryId,
      'purchase_price': product.purchasePrice,
      'selling_price': product.sellingPrice,
      'quantity': product.quantity,
      'image': product.image,
      'created_at': product.createdAt.toIso8601String(),
      'updated_at': product.updatedAt.toIso8601String(),
    };

    if (existing.isEmpty) {
      await db.insert('product', data);
      return;
    }

    await db.update(
      'product',
      data,
      where: 'id = ?',
      whereArgs: [existing.first['id']],
    );
  }

  Future<void> _syncProductsFromBackend() async {
    final organizationId = await _selectedOrganizationId();
    if (organizationId == null || organizationId.isEmpty) return;

    final rows = await SupabaseService.client
        .from('products')
        .select('name, purchase_price, selling_price, quantity, image_path, '
            'created_at, updated_at, product_categories(name)')
        .eq('organization_id', organizationId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final categoryMap = map['product_categories'] as Map<String, dynamic>?;
      final categoryName = categoryMap?['name'] as String? ?? '';

      await _upsertLocalProduct(
        ProductModel(
          name: map['name'] as String? ?? '',
          category: categoryName,
          purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
          sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0,
          quantity: (map['quantity'] as num?)?.toInt() ?? 0,
          image: map['image_path'] as String?,
          createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
          updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
              DateTime.now(),
        ),
      );
    }
  }

  Future<void> _upsertBackendProduct(ProductModel product) async {
    final organizationId = await _selectedOrganizationId();
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (organizationId == null || organizationId.isEmpty || userId == null) {
      return;
    }

    final existing = await SupabaseService.client
        .from('products')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('name', product.name)
        .limit(1)
        .maybeSingle();

    final payload = {
      'organization_id': organizationId,
      'name': product.name,
      'purchase_price': product.purchasePrice,
      'selling_price': product.sellingPrice,
      'quantity': product.quantity,
      'image_path': product.image,
      'updated_by_user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (existing == null) {
      await SupabaseService.client.from('products').insert({
        ...payload,
        'created_by_user_id': userId,
      });
      return;
    }

    await SupabaseService.client
        .from('products')
        .update(payload)
        .eq('id', existing['id'] as String);
  }

  Future<int> addProduct(ProductModel product) async {
    final now = _now();
    final data = {
      'name': product.name,
      'category': product.category,
      'category_id': product.categoryId,
      'purchase_price': product.purchasePrice,
      'selling_price': product.sellingPrice,
      'quantity': product.quantity,
      'image': product.image,
      'created_at': now,
      'updated_at': now,
    };

    final id = await db.insert(
      'product',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (await _isBackendMode()) {
      await _upsertBackendProduct(product);
    }

    return id;
  }

  Future<List<ProductModel>> getProducts() async {
    if (await _isBackendMode()) {
      await _syncProductsFromBackend();
    }

    final maps = await db.query('product', orderBy: 'created_at DESC');
    return maps.map(ProductModel.fromMap).toList();
  }

  Future<int> updateProduct(ProductModel product) async {
    final now = _now();
    final data = {
      'name': product.name,
      'category': product.category,
      'category_id': product.categoryId,
      'purchase_price': product.purchasePrice,
      'selling_price': product.sellingPrice,
      'quantity': product.quantity,
      'image': product.image,
      'updated_at': now,
    };

    final result = await db.update(
      'product',
      data,
      where: 'id = ?',
      whereArgs: [product.id],
    );

    if (await _isBackendMode()) {
      await _upsertBackendProduct(product);
    }

    return result;
  }

  Future<int> deleteProduct(int productId) async {
    if (await _isBackendMode()) {
      final existing = await db.query(
        'product',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final organizationId = await _selectedOrganizationId();
        if (organizationId != null && organizationId.isNotEmpty) {
          await SupabaseService.client
              .from('products')
              .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
              .eq('organization_id', organizationId)
              .eq('name', existing.first['name'] as String);
        }
      }
    }

    return db.delete('product', where: 'id = ?', whereArgs: [productId]);
  }

  Future<bool> isDuplicateProduct(String name) async {
    if (await _isBackendMode()) {
      await _syncProductsFromBackend();
    }

    final result = await db.query(
      'product',
      columns: ['id'],
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase()],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<List<ProductModel>> loadAllProducts() async {
    if (await _isBackendMode()) {
      await _syncProductsFromBackend();
    }

    final result = await db.query('product', orderBy: 'name ASC');
    return result.map(ProductModel.fromMap).toList();
  }

  Future<int> deleteAllProducts() async {
    return db.delete('product');
  }

  void clearCache() {}
}
