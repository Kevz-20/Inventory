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

  Future<void> updateProductStock(int productId, int quantitySold) async {
    await db.rawUpdate(
      'UPDATE product SET quantity = quantity - ? WHERE id = ?',
      [quantitySold, productId],
    );
  }

  Future<List<Map<String, dynamic>>> getCustomers({bool shared = false}) async {
    try {
      if (shared) {
        return await db.query('customer'); // ✅ correct table
      } else {
        final accountId = await AccountRepository().getAccountId();
        return await db.query(
          'customer', // ✅ correct table
          where: 'account_id = ?',
          whereArgs: [accountId],
        );
      }
    } catch (e) {
      return [];
    }
  }

  // ------------------- SALES -------------------

  // Cash checkout
  Future<void> checkoutCash(List<Map<String, dynamic>> items) async {
    final accountId = await accountRepo.getAccountId();
    final now = DateTime.now().toIso8601String();

    // Calculate total safely converting num -> int
    final total = items.fold<int>(
      0,
      (sum, item) => sum + (item['subtotal'] as num).toInt(),
    );

    // Insert main sale record
    final saleId = await insertSale(
      accountId: accountId,
      saleType: 'cash',
      total: total,
      createdAt: now,
    );

    // Insert each sale item + sales_cash + update stock
    for (var item in items) {
      final productId = item['productId'];
      final subtotal = (item['subtotal'] as num).toInt();
      final unitPrice = (item['price'] as num).toInt();
      final quantity = (item['quantity'] as num).toInt();

      await insertSaleItem(
        saleId: saleId,
        productId: productId,
        unitPrice: unitPrice,
        quantity: quantity,
        subtotal: subtotal,
      );

      await insertSalesCash(
        accountId: accountId,
        productId: productId,
        amount: subtotal,
        quantity: quantity,
        date: now,
        createdAt: now,
      );

      await updateProductStock(productId, quantity);
    }
  }

  // Insert into main sales table and return sale ID
  Future<int> insertSale({
    required int accountId,
    int? customerId,
    required String saleType,
    required int total,
    required String createdAt,
  }) async {
    final data = {
      'account_id': accountId,
      'customer_id': customerId,
      'sale_type': saleType,
      'total': total,
      'created_at': createdAt,
    };
    return await db.insert('sales', data);
  }

  // Insert items into sale_item table
  Future<void> insertSaleItem({
    required int saleId,
    required int productId,
    required int unitPrice,
    required int quantity,
    required int subtotal,
  }) async {
    final data = {
      'sale_id': saleId,
      'product_id': productId,
      'unit_price': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
    await db.insert('sale_item', data);
  }

  Future<void> insertSalesCash({
    required int accountId,
    required int productId,
    required int amount,
    required int quantity,
    required String date,
    required String createdAt,
  }) async {
    await db.insert('sales_cash', {
      'account_id': accountId,
      'product_id': productId,
      'amount': amount,
      'quantity': quantity,
      'date': date,
      'created_at': createdAt,
    });
  }

  Future<void> insertSalesCredit({
    required int accountId,
    required int saleId,
    required int productId,
    required int customerId,
    required int amount,
    required int quantity,
    required int statusId,
    required String creditDate,
    required String dueDate,
    required String createdAt,
  }) async {
    await db.insert('sales_credit', {
      'account_id': accountId,
      'sale_id': saleId,
      'product_id': productId,
      'customer_id': customerId,
      'amount': amount,
      'quantity': quantity,
      'status_id': statusId,
      'credit_date': creditDate,
      'due_date': dueDate,
      'created_at': createdAt,
    });
  }

  // Credit checkout
  Future<void> checkoutCredit(
    List<Map<String, dynamic>> items,
    int customerId, {
    DateTime? dueDate,
  }) async {
    final accountId = await accountRepo.getAccountId();
    final now = DateTime.now().toIso8601String();
    final due =
        dueDate?.toIso8601String() ??
        DateTime.now().add(const Duration(days: 30)).toIso8601String();

    await db.transaction((txn) async {
      // 1️⃣ Verify customer exists for this account
      final customerExists = await txn.query(
        'customer',
        where: 'id = ? AND account_id = ?',
        whereArgs: [customerId, accountId],
      );
      if (customerExists.isEmpty) {
        throw Exception('Customer does not exist for this account');
      }

      // 2️⃣ Get status_id for unpaid credit
      final statusResult = await txn.query(
        'credit_status',
        where: 'code = ?',
        whereArgs: [0], // unpaid
      );
      if (statusResult.isEmpty) {
        throw Exception('Credit status "unpaid" not found in database');
      }
      final statusId = statusResult.first['id'] as int;

      // 3️⃣ Insert main sale record
      final saleId = await txn.insert('sales', {
        'account_id': accountId,
        'customer_id': customerId,
        'sale_type': 'credit',
        'total': items.fold<int>(
          0,
          (sum, item) => sum + (item['subtotal'] as num).toInt(),
        ),
        'created_at': now,
      });

      // 4️⃣ Insert each sale item + sales_credit + update stock
      for (var item in items) {
        final productId = item['productId'];

        // Check product exists for this account
        final productExists = await txn.query(
          'product',
          where: 'id = ? AND account_id = ?',
          whereArgs: [productId, accountId],
        );
        if (productExists.isEmpty) {
          throw Exception('Product $productId does not exist for this account');
        }

        final subtotal = (item['subtotal'] as num).toInt();
        final unitPrice = (item['price'] as num).toInt();
        final quantity = (item['quantity'] as num).toInt();

        // Insert into sale_item
        await txn.insert('sale_item', {
          'sale_id': saleId,
          'product_id': productId,
          'unit_price': unitPrice,
          'quantity': quantity,
          'subtotal': subtotal,
        });

        // Insert into sales_credit
        await txn.insert('sales_credit', {
          'account_id': accountId,
          'sale_id': saleId,
          'product_id': productId,
          'customer_id': customerId,
          'amount': subtotal,
          'quantity': quantity,
          'status_id': statusId,
          'credit_date': now,
          'due_date': due,
          'created_at': now,
        });

        // Update product stock
        await txn.rawUpdate(
          'UPDATE product SET quantity = quantity - ? WHERE id = ?',
          [quantity, productId],
        );
      }
    });
  }
}
