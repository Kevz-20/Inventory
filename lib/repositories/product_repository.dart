import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';
import '../repositories/account_repository.dart';

class ProductRepository {
  final Database db;
  final AccountRepository accountRepo;

  ProductRepository(this.db, this.accountRepo);

  // ------------------- PRODUCT -------------------

  Future<int> insertProduct(ProductModel product) async {
    final fullName = await accountRepo.getFullName(); // First+Middle+Last
    final data = product.toMap();
    data['created_by'] = fullName;
    data['updated_by'] = fullName;

    return await db.insert('product', data);
  }

  Future<List<ProductModel>> getProducts() async {
    final result = await db.query('product'); // all accounts
    return result.map((e) => ProductModel.fromMap(e)).toList();
  }

  Future<int> updateProduct(ProductModel product) async {
    final fullName = await accountRepo.getFullName();
    final data = product.toMap();
    data['updated_by'] = fullName;

    return await db.update(
      'product',
      data,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    return await db.delete(
      'product',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ProductModel?> getProductById(int id) async {
    final result = await db.query(
      'product',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) return ProductModel.fromMap(result.first);
    return null;
  }

  // ------------------- PURCHASE -------------------

  Future<void> savePurchase(List<Map<String, dynamic>> purchasedItems) async {
    final fullName = await accountRepo.getFullName();
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (var item in purchasedItems) {
      // Insert into stock_in
      batch.insert('stock_in', {
        'product_id': item['productId'],
        'quantity': item['quantity'],
        'purchase_price': item['price'],
        'markup_rate': item['markup'] ?? 0,
        'image': item['image'],
        'created_at': now,
        'updated_at': now,
        'created_by': fullName,
        'updated_by': fullName,
      });

      // Update product stock
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

  // ------------------- CUSTOMERS -------------------

  Future<List<Map<String, dynamic>>> getCustomers() async {
    return await db.query('customer'); // all customers, no account filter
  }

  // ------------------- SALES -------------------

  // Cash checkout
  Future<void> checkoutCash(List<Map<String, dynamic>> items) async {
    final now = DateTime.now().toIso8601String();

    // Calculate total
    final total = items.fold<int>(0, (sum, item) => sum + (item['subtotal'] as num).toInt());

    // Get name parts for created_by fields
    final nameParts = await accountRepo.getNameParts();

    // Insert main sale record
    final saleId = await db.insert('sales', {
      'sale_type': 'cash',
      'total': total,
      'created_at': now,
      'created_by_first_name': nameParts['first'],
      'created_by_middle_name': nameParts['middle'],
      'created_by_last_name': nameParts['last'],
    });

    // Insert each sale item and update stock
    for (var item in items) {
      final productId = item['productId'];
      final subtotal = (item['subtotal'] as num).toInt();
      final unitPrice = (item['price'] as num).toInt();
      final quantity = (item['quantity'] as num).toInt();

      // Insert sale item
      await db.insert('sale_item', {
        'sale_id': saleId,
        'product_id': productId,
        'unit_price': unitPrice,
        'quantity': quantity,
        'subtotal': subtotal,
      });

      // Insert into sales_cash (added created_by fields)
      await db.insert('sales_cash', {
        'product_id': productId,
        'amount': subtotal,
        'quantity': quantity,
        'date': now,
        'created_at': now,
        'created_by_first_name': nameParts['first'],
        'created_by_middle_name': nameParts['middle'],
        'created_by_last_name': nameParts['last'],
      });

      // Update stock
      await updateProductStock(productId, quantity);
    }
  }

  // Credit checkout
  Future<void> checkoutCredit(
    List<Map<String, dynamic>> items,
    int customerId, {
    DateTime? dueDate,
  }) async {
    final nameParts = await accountRepo.getNameParts(); // <-- updated
    final now = DateTime.now().toIso8601String();
    final due = dueDate?.toIso8601String() ??
        DateTime.now().add(const Duration(days: 30)).toIso8601String();

    await db.transaction((txn) async {
      // Verify customer exists
      final customerExists = await txn.query(
        'customer',
        where: 'id = ?',
        whereArgs: [customerId],
      );
      if (customerExists.isEmpty) throw Exception('Customer does not exist');

      // Current available credit
      final currentCredit = (customerExists.first['available_credit'] as num?)?.toDouble() ?? 1000.0;

      // Status_id for unpaid credit
      final statusResult = await txn.query(
        'credit_status',
        where: 'code = ?',
        whereArgs: [0],
      );
      if (statusResult.isEmpty) throw Exception('Credit status "unpaid" not found');
      final statusId = statusResult.first['id'] as int;

      // Insert main sale record (updated created_by fields)
      final saleId = await txn.insert('sales', {
        'customer_id': customerId,
        'sale_type': 'credit',
        'total': items.fold<int>(0, (sum, item) => sum + (item['subtotal'] as num).toInt()),
        'created_at': now,
        'created_by_first_name': nameParts['first'],
        'created_by_middle_name': nameParts['middle'],
        'created_by_last_name': nameParts['last'],
      });

      // Insert sale items and sales_credit
      for (var item in items) {
        final productId = item['productId'];
        final subtotal = (item['subtotal'] as num).toInt();
        final unitPrice = (item['price'] as num).toInt();
        final quantity = (item['quantity'] as num).toInt();

        // Insert sale item
        await txn.insert('sale_item', {
          'sale_id': saleId,
          'product_id': productId,
          'unit_price': unitPrice,
          'quantity': quantity,
          'subtotal': subtotal,
        });

        // Insert into sales_credit (updated created_by fields)
        await txn.insert('sales_credit', {
          'sale_id': saleId,
          'product_id': productId,
          'customer_id': customerId,
          'amount': subtotal,
          'quantity': quantity,
          'status_id': statusId,
          'credit_date': now,
          'due_date': due,
          'created_at': now,
          'created_by_first_name': nameParts['first'],
          'created_by_middle_name': nameParts['middle'],
          'created_by_last_name': nameParts['last'],
        });

        // Update product stock
        await txn.rawUpdate(
          'UPDATE product SET quantity = quantity - ? WHERE id = ?',
          [quantity, productId],
        );
      }

      // Update customer's available credit
      final totalAmount = items.fold<double>(0, (sum, item) => sum + (item['subtotal'] as num).toDouble());
      final newCredit = (currentCredit - totalAmount).clamp(0, double.infinity);

      await txn.update(
        'customer',
        {'available_credit': newCredit},
        where: 'id = ?',
        whereArgs: [customerId],
      );
    });
  }
}
