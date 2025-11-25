import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';
import 'account_repository.dart';

class ProductRepository {
  final Database db;
  final AccountRepository accountRepo;

  ProductRepository(this.db) : accountRepo = AccountRepository(db);

  Future<int> insertProduct(ProductModel product) async {
    final accountId = await accountRepo.getAccountId();
    final data = product.toMap();
    data['account_id'] = accountId;
    return await db.insert('product', data);
  }

  Future<List<ProductModel>> getProducts() async {
    final accountId = await accountRepo.getAccountId();
    final result = await db.query(
      'product',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
    return result.map((e) => ProductModel.fromMap(e)).toList();
  }

  Future<int> updateProduct(ProductModel product) async {
    return await db.update(
      'product',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    return await db.delete('product', where: 'id = ?', whereArgs: [id]);
  }

  Future<ProductModel?> getProductById(int id) async {
    final result = await db.query('product', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return ProductModel.fromMap(result.first);
    }
    return null;
  }

  Future<void> savePurchase(List<Map<String, dynamic>> purchasedItems) async {
    final accountId = await accountRepo.getAccountId();
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
      batch.insert('purchase', data);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getPurchases() async {
    final accountId = await accountRepo.getAccountId();
    return await db.query(
      'purchase',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'timestamp DESC',
    );
  }
}
