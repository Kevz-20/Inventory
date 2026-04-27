import 'package:sqflite/sqflite.dart';
import '../models/current_user.dart';
import '../models/product_model.dart';
import '../models/product_selling_option.dart';
import '../models/product_unit_conversion.dart';
import '../repositories/account_repository.dart';
import '../services/audit_log_service.dart';
import '../services/notification_service.dart';

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
    data['sync_status'] = 'pending';
    data['last_synced_at'] = null;
    data['is_deleted'] = 0;

    final productId = await db.insert('product', data);
    await AuditLogService.instance.log(
      module: 'product',
      tableName: 'product',
      recordId: productId.toString(),
      action: 'create',
      newValue: data,
    );
    return productId;
  }

  Future<List<ProductModel>> getProducts() async {
  final result = await db.rawQuery('''
    SELECT
      p.*,
      c.name AS category_name
    FROM product p
    LEFT JOIN product_category c ON c.id = p.category_id
    WHERE p.is_deleted = 0
    ORDER BY p.id DESC
  ''');

  return result.map((e) {
    final map = Map<String, dynamic>.from(e);

    // ✅ If your ProductModel expects `category` string
    // but DB uses category_id, inject readable name:
    if ((map['category'] == null || (map['category'] as String).isEmpty) &&
        map['category_name'] != null) {
      map['category'] = map['category_name'];
    }

    return ProductModel.fromMap(map);
  }).toList();
}

  Future<Map<int, List<ProductUnitConversion>>> getAllUnitConversions() async {
    final rows = await db.query(
      'product_unit_conversion',
      orderBy: 'product_id ASC, base_quantity DESC, unit_name ASC',
    );

    final result = <int, List<ProductUnitConversion>>{};
    for (final row in rows) {
      final conversion = ProductUnitConversion.fromMap(row);
      final productId = conversion.productId;
      if (productId == null) continue;
      result.putIfAbsent(productId, () => []);
      result[productId]!.add(conversion);
    }
    return result;
  }

  Future<Map<int, List<ProductSellingOption>>> getAllSellingOptions() async {
    final rows = await db.query(
      'product_selling_option',
      orderBy: 'product_id ASC, base_quantity DESC, label ASC',
    );

    final result = <int, List<ProductSellingOption>>{};
    for (final row in rows) {
      final option = ProductSellingOption.fromMap(row);
      final productId = option.productId;
      if (productId == null) continue;
      result.putIfAbsent(productId, () => []);
      result[productId]!.add(option);
    }
    return result;
  }

  Future<int> updateProduct(ProductModel product) async {
    final fullName = await accountRepo.getFullName();
    final previous = product.id == null ? null : await getProductById(product.id!);
    final data = product.toMap();
    data['updated_by'] = fullName;
    data['sync_status'] = 'pending';
    data['last_synced_at'] = null;

    final updated = await db.update(
      'product',
      data,
      where: 'id = ?',
      whereArgs: [product.id],
    );
    if (updated > 0) {
      await AuditLogService.instance.log(
        module: 'product',
        tableName: 'product',
        recordId: product.id?.toString(),
        action: 'update',
        oldValue: previous?.toMap(),
        newValue: data,
      );
      final association = await accountRepo.getSlpaName();
      final changes     = NotificationService.buildChanges(previous?.toMap(), data);
      NotificationService.instance.sendProductAlert(
        action:      'Edited',
        productName: product.name,
        memberName:  fullName,
        association: association,
        changes:     changes,
      );
    }
    return updated;
  }

  Future<int> deleteProduct(int id) async {
    final previous = await getProductById(id);
    final deleted = await db.update(
      'product',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (deleted > 0) {
      await AuditLogService.instance.log(
        module: 'product',
        tableName: 'product',
        recordId: id.toString(),
        action: 'delete',
        oldValue: previous?.toMap(),
      );
      final association = await accountRepo.getSlpaName();
      NotificationService.instance.sendProductAlert(
        action:      'Deleted',
        productName: previous?.name ?? 'Unknown Product',
        memberName:  await accountRepo.getFullName(),
        association: association,
      );
    }
    return deleted;
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
        'sync_status': 'pending',
        'last_synced_at': null,
        'is_deleted': 0,
      });

      // Update product stock
      batch.rawUpdate(
        'UPDATE product SET quantity = quantity + ? WHERE id = ?',
        [item['quantity'], item['productId']],
      );
    }

    await batch.commit(noResult: true);
    await AuditLogService.instance.log(
      module: 'stock_in',
      tableName: 'stock_in',
      action: 'create',
      newValue: {
        'items': purchasedItems,
        'created_at': now,
        'created_by': fullName,
      },
    );
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

    final total = items.fold<double>(
      0,
      (sum, item) => sum + (item['subtotal'] as num).toDouble(),
    );

    final saleId = await db.insert('sales', {
      'sale_type': 'cash',
      'total': total,
      'created_at': now,
      'created_by_first_name': CurrentUser.firstName,
      'created_by_middle_name': CurrentUser.middleName,
      'created_by_last_name': CurrentUser.lastName,
      'created_by_member_id': CurrentUser.memberId,
      'sync_status': 'pending',
      'last_synced_at': null,
      'is_deleted': 0,
    });

    // Insert each sale item and update stock
    for (var item in items) {
      final productId = item['productId'];
      final subtotal = (item['subtotal'] as num).toDouble();
      final unitPrice = (item['price'] as num).toDouble();
      final quantity = (item['quantity'] as num).toInt();

      // Insert sale item
      await db.insert('sale_item', {
        'sale_id': saleId,
        'product_id': productId,
        'unit_price': unitPrice,
        'quantity': quantity,
        'subtotal': subtotal,
      });

      await db.insert('sales_cash', {
        'product_id': productId,
        'amount': subtotal,
        'quantity': quantity,
        'date': now,
        'created_at': now,
        'created_by_first_name': CurrentUser.firstName,
        'created_by_middle_name': CurrentUser.middleName,
        'created_by_last_name': CurrentUser.lastName,
      });

      // Update stock
      await updateProductStock(productId, quantity);
    }

    await AuditLogService.instance.log(
      module: 'sales_cash',
      tableName: 'sales',
      recordId: saleId.toString(),
      action: 'create',
      newValue: {
        'sale_id': saleId,
        'sale_type': 'cash',
        'total': total,
        'items': items,
        'created_at': now,
      },
    );
  }

  // Credit checkout
  Future<void> checkoutCredit(
    List<Map<String, dynamic>> items,
    int customerId, {
    DateTime? dueDate,
  }) async {
    final now = DateTime.now().toIso8601String();
    final due = dueDate?.toIso8601String() ??
        DateTime.now().add(const Duration(days: 30)).toIso8601String();

    int? saleId;
    double totalAmount = 0;

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

      saleId = await txn.insert('sales', {
        'customer_id': customerId,
        'sale_type': 'credit',
        'total': items.fold<double>(
          0,
          (sum, item) => sum + (item['subtotal'] as num).toDouble(),
        ),
        'created_at': now,
        'created_by_first_name': CurrentUser.firstName,
        'created_by_middle_name': CurrentUser.middleName,
        'created_by_last_name': CurrentUser.lastName,
        'created_by_member_id': CurrentUser.memberId,
        'sync_status': 'pending',
        'last_synced_at': null,
        'is_deleted': 0,
      });

      // Insert sale items and sales_credit
      for (var item in items) {
        final productId = item['productId'];
        final subtotal = (item['subtotal'] as num).toDouble();
        final unitPrice = (item['price'] as num).toDouble();
        final quantity = (item['quantity'] as num).toInt();

        // Insert sale item
        await txn.insert('sale_item', {
          'sale_id': saleId,
          'product_id': productId,
          'unit_price': unitPrice,
          'quantity': quantity,
          'subtotal': subtotal,
        });

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
          'created_by_first_name': CurrentUser.firstName,
          'created_by_middle_name': CurrentUser.middleName,
          'created_by_last_name': CurrentUser.lastName,
        });

        // Update product stock
        await txn.rawUpdate(
          'UPDATE product SET quantity = quantity - ? WHERE id = ?',
          [quantity, productId],
        );
      }

      // Update customer's available credit
      totalAmount = items.fold<double>(0, (sum, item) => sum + (item['subtotal'] as num).toDouble());
      final newCredit = (currentCredit - totalAmount).clamp(0, double.infinity);

      await txn.update(
        'customer',
        {
          'available_credit': newCredit,
          'updated_at': now,
          'sync_status': 'pending',
          'last_synced_at': null,
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );
    });

    await AuditLogService.instance.log(
      module: 'sales_credit',
      tableName: 'sales',
      recordId: saleId?.toString(),
      action: 'create',
      newValue: {
        'sale_id': saleId,
        'customer_id': customerId,
        'sale_type': 'credit',
        'total': totalAmount,
        'due_date': due,
        'items': items,
        'created_at': now,
      },
    );
  }
}
