import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';
import 'account_repository.dart';

class ProductRepository {
  final Database db;
  final AccountRepository accountRepo;

  ProductRepository(this.db) : accountRepo = AccountRepository(db) {
    debugPrint('⭐ ProductRepository initialized');
  }

  Future<int> insertProduct(ProductModel product) async {
    debugPrint('⭐ Inserting product: ${product.name}');
    final accountId = await accountRepo.getAccountId();
    debugPrint('⭐ Account ID for insert: $accountId');
    final data = product.toMap();
    data['account_id'] = accountId;
    final id = await db.insert('product', data);
    debugPrint('⭐ Product inserted with ID: $id');
    return id;
  }

  Future<List<ProductModel>> getProducts() async {
    debugPrint('⭐ Fetching products...');
    final accountId = await accountRepo.getAccountId();
    debugPrint('⭐ Account ID for getProducts: $accountId');
    final result = await db.query(
      'product',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
    debugPrint('⭐ Raw product count: ${result.length}');
    final products = result.map((e) => ProductModel.fromMap(e)).toList();
    debugPrint('⭐ Products mapped: ${products.length}');
    return products;
  }

  Future<int> updateProduct(ProductModel product) async {
    debugPrint('⭐ Updating product ID: ${product.id}');
    final rows = await db.update(
      'product',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    debugPrint('⭐ Updated rows: $rows');
    return rows;
  }

  Future<int> deleteProduct(int id) async {
    debugPrint('⭐ Deleting product ID: $id');
    final rows = await db.delete('product', where: 'id = ?', whereArgs: [id]);
    debugPrint('⭐ Deleted rows: $rows');
    return rows;
  }

  Future<ProductModel?> getProductById(int id) async {
    debugPrint('⭐ Fetching product by ID: $id');
    final result = await db.query('product', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final product = ProductModel.fromMap(result.first);
      debugPrint('⭐ Product found: ${product.name}');
      return product;
    }
    debugPrint('⭐ Product not found');
    return null;
  }

  Future<void> savePurchase(List<Map<String, dynamic>> purchasedItems) async {
    debugPrint('⭐ Saving purchases: ${purchasedItems.length} items');
    final accountId = await accountRepo.getAccountId();
    debugPrint('⭐ Account ID for purchases: $accountId');
    final batch = db.batch();

    for (var item in purchasedItems) {
      final data = {
        'account_id': accountId,
        'product_id': item['productId'],
        'name': item['name'],
        'quantity': item['quantity'],
        'price': item['price'],
        'total': item['total'],
        'timestamp': DateTime.now().toIso8601String(),
      };
      debugPrint('⭐ Adding to batch: ${data['name']} x ${data['quantity']}');
      batch.insert('purchase', data);
    }

    await batch.commit(noResult: true);
    debugPrint('⭐ Purchases saved');
  }

  Future<List<Map<String, dynamic>>> getPurchases() async {
    debugPrint('⭐ Fetching purchases...');
    final accountId = await accountRepo.getAccountId();
    final result = await db.query(
      'purchase',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'timestamp DESC',
    );
    debugPrint('⭐ Purchases fetched: ${result.length}');
    return result;
  }
}
