import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';
import 'account_repository.dart';

class ProductRepository {
  final Database db;
  final AccountRepository accountRepo;

  ProductRepository(this.db) : accountRepo = AccountRepository();

  // ------------------- PRODUCT -------------------
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
    if (result.isNotEmpty) return ProductModel.fromMap(result.first);
    return null;
  }

  // ------------------- PURCHASE -------------------
  Future<void> savePurchase(List<Map<String, dynamic>> purchasedItems) async {
    final accountId = await accountRepo.getAccountId();
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (var item in purchasedItems) {
      batch.insert('stock_in', {
        'account_id': accountId,
        'product_id': item['productId'],
        'quantity': item['quantity'],
        'purchase_price': item['price'],
        'markup_rate': item['markup'] ?? 0,
        'image': item['image'],
        'created_at': now,
        'updated_at': now,
      });

      batch.rawUpdate(
        'UPDATE product SET quantity = quantity + ? WHERE id = ?',
        [item['quantity'], item['productId']],
      );
    }

    await batch.commit(noResult: true);
  }

  // ------------------- SALES -------------------

  // Cash checkout
  Future<void> checkoutCash(List<Map<String, dynamic>> items) async {
    final accountId = await accountRepo.getAccountId();
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (var item in items) {
      batch.insert('sales_cash', {
        'account_id': accountId,
        'product_id': item['productId'],
        'amount': item['subtotal'],
        'quantity': item['quantity'],
        'date': now,
        'created_at': now,
      });

      batch.rawUpdate(
        'UPDATE product SET quantity = quantity - ? WHERE id = ?',
        [item['quantity'], item['productId']],
      );
    }

    await batch.commit(noResult: true);
  }

  // Credit checkout
  Future<void> checkoutCredit(
    List<Map<String, dynamic>> items,
    int customerId, {
    DateTime? dueDate,
  }) async {
    final accountId = await accountRepo.getAccountId();
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    final due =
        dueDate?.toIso8601String() ??
        DateTime.now().add(Duration(days: 30)).toIso8601String();

    for (var item in items) {
      batch.insert('sales_credit', {
        'account_id': accountId,
        'product_id': item['productId'],
        'customer_id': customerId,
        'amount': item['subtotal'],
        'quantity': item['quantity'],
        'status_id': 0, // unpaid
        'credit_date': now,
        'due_date': due,
        'created_at': now,
      });

      batch.rawUpdate(
        'UPDATE product SET quantity = quantity - ? WHERE id = ?',
        [item['quantity'], item['productId']],
      );
    }

    await batch.commit(noResult: true);
  }
}
