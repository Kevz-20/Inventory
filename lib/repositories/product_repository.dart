import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../core/sync_identity.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import 'account_repository.dart';

class ProductRepository {
  final Database db;
  final AccountRepository accountRepo;

  ProductRepository(this.db, this.accountRepo);

  void _scheduleSync() {
    unawaited(SyncService.instance.triggerBackgroundSync());
  }

  ProductModel? _findProductById(List<ProductModel> products, int id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
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

  Future<String?> _currentBackendUserId() async {
    return SupabaseService.client.auth.currentUser?.id;
  }

  String _asText(Object? raw) => raw?.toString().trim() ?? '';

  Future<Map<String, dynamic>?> _findBackendProductByExternalLocalUuid(
    String organizationId,
    String localUuid,
  ) async {
    if (localUuid.isEmpty) return null;
    final row = await SupabaseService.client
        .from('products')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('external_local_uuid', localUuid)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>?> _findBackendCustomerByExternalLocalUuid(
    String organizationId,
    String localUuid,
  ) async {
    if (localUuid.isEmpty) return null;
    final row = await SupabaseService.client
        .from('customers')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('external_local_uuid', localUuid)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>?> _getLocalCustomerById(int id) async {
    final rows = await db.query(
      'customer',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<String?> _findBackendProductIdByLocalProductId(int productId) async {
    final localRows = await db.query(
      'product',
      columns: ['server_id', 'local_uuid'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (localRows.isNotEmpty) {
      final serverId = localRows.first['server_id'] as String?;
      if (serverId != null && serverId.isNotEmpty) {
        return serverId;
      }
    }

    final organizationId = await _selectedOrganizationId();
    if (organizationId == null || organizationId.isEmpty) return null;

    final localProduct = await getProductById(productId);
    if (localProduct == null) return null;

    final localUuid = _asText(localRows.isNotEmpty
        ? localRows.first['local_uuid']
        : localProduct.localUuid);
    if (localUuid.isNotEmpty) {
      final byExternalKey = await _findBackendProductByExternalLocalUuid(
        organizationId,
        localUuid,
      );
      if (byExternalKey != null) {
        return byExternalKey['id'] as String;
      }
    }

    final row = await SupabaseService.client
        .from('products')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('name', localProduct.name)
        .limit(1)
        .maybeSingle();

    return row == null ? null : row['id'] as String;
  }

  Future<String?> _findBackendCustomerIdByLocalCustomerId(int customerId) async {
    final organizationId = await _selectedOrganizationId();
    if (organizationId == null || organizationId.isEmpty) return null;

    final localCustomer = await _getLocalCustomerById(customerId);
    if (localCustomer == null) return null;

    final localUuid = _asText(localCustomer['local_uuid']);
    if (localUuid.isNotEmpty) {
      final byExternalKey = await _findBackendCustomerByExternalLocalUuid(
        organizationId,
        localUuid,
      );
      if (byExternalKey != null) {
        return byExternalKey['id'] as String;
      }
    }

    final phoneNumber = (localCustomer['phone_number'] ?? '').toString().trim();
    if (phoneNumber.isNotEmpty) {
      final row = await SupabaseService.client
          .from('customers')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('phone_number', phoneNumber)
          .limit(1)
          .maybeSingle();
      if (row != null) return row['id'] as String;
    }

    final row = await SupabaseService.client
        .from('customers')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('first_name', (localCustomer['first_name'] ?? '').toString())
        .eq('middle_name', (localCustomer['middle_name'] ?? '').toString())
        .eq('last_name', (localCustomer['last_name'] ?? '').toString())
        .eq('municipality', (localCustomer['municipality'] ?? '').toString())
        .limit(1)
        .maybeSingle();

    return row == null ? null : row['id'] as String;
  }

  Future<Map<String, dynamic>?> _mirrorCashSaleToBackend(
    List<Map<String, dynamic>> items, {
    required double totalAmount,
    required String createdAt,
  }) async {
    final organizationId = await _selectedOrganizationId();
    final userId = await _currentBackendUserId();
    if (organizationId == null || organizationId.isEmpty || userId == null) {
      return null;
    }

    final saleRow = await SupabaseService.client
        .from('sales')
        .insert({
          'organization_id': organizationId,
          'sale_type': 'cash',
          'total_amount': totalAmount,
          'created_by_user_id': userId,
          'updated_by_user_id': userId,
          'created_at': createdAt,
          'updated_at': createdAt,
        })
        .select('id')
        .single();

    final saleId = saleRow['id'] as String;
    final saleItemIds = <String>[];

    for (final item in items) {
      final productId = await _findBackendProductIdByLocalProductId(
        item['productId'] as int,
      );
      if (productId == null) continue;

      final saleItemRow = await SupabaseService.client
          .from('sale_items')
          .insert({
            'sale_id': saleId,
            'product_id': productId,
            'unit_price': (item['price'] as num).toDouble(),
            'quantity': item['quantity'] as int,
            'subtotal': (item['subtotal'] as num).toDouble(),
          })
          .select('id')
          .single();
      saleItemIds.add(saleItemRow['id'] as String);
    }

    return {
      'sale_id': saleId,
      'sale_item_ids': saleItemIds,
    };
  }

  Future<Map<String, dynamic>?> _mirrorCreditSaleToBackend(
    List<Map<String, dynamic>> items, {
    required int customerId,
    required double totalAmount,
    required String createdAt,
    required String dueDate,
  }) async {
    final organizationId = await _selectedOrganizationId();
    final userId = await _currentBackendUserId();
    if (organizationId == null || organizationId.isEmpty || userId == null) {
      return null;
    }

    final backendCustomerId = await _findBackendCustomerIdByLocalCustomerId(
      customerId,
    );
    if (backendCustomerId == null) {
      return null;
    }

    final saleRow = await SupabaseService.client
        .from('sales')
        .insert({
          'organization_id': organizationId,
          'customer_id': backendCustomerId,
          'sale_type': 'credit',
          'total_amount': totalAmount,
          'created_by_user_id': userId,
          'updated_by_user_id': userId,
          'created_at': createdAt,
          'updated_at': createdAt,
        })
        .select('id')
        .single();

    final saleId = saleRow['id'] as String;
    final saleItemIds = <String>[];

    for (final item in items) {
      final productId = await _findBackendProductIdByLocalProductId(
        item['productId'] as int,
      );
      if (productId == null) continue;

      final saleItemRow = await SupabaseService.client
          .from('sale_items')
          .insert({
            'sale_id': saleId,
            'product_id': productId,
            'unit_price': (item['price'] as num).toDouble(),
            'quantity': item['quantity'] as int,
            'subtotal': (item['subtotal'] as num).toDouble(),
          })
          .select('id')
          .single();
      saleItemIds.add(saleItemRow['id'] as String);
    }

    final receivableRow = await SupabaseService.client
        .from('receivables')
        .insert({
          'organization_id': organizationId,
          'sale_id': saleId,
          'customer_id': backendCustomerId,
          'original_amount': totalAmount,
          'remaining_amount': totalAmount,
          'status': 'unpaid',
          'due_date': dueDate,
          'created_by_user_id': userId,
          'updated_by_user_id': userId,
          'created_at': createdAt,
          'updated_at': createdAt,
        })
        .select('id')
        .single();

    return {
      'sale_id': saleId,
      'sale_item_ids': saleItemIds,
      'receivable_id': receivableRow['id'],
    };
  }

  Future<void> _upsertLocalProduct(
    ProductModel product, {
    String? serverId,
    String? externalLocalUuid,
  }) async {
    final normalizedExternalLocalUuid = _asText(
      externalLocalUuid ?? product.localUuid,
    );
    final existing = await db.query(
      'product',
      columns: ['id'],
      where: normalizedExternalLocalUuid.isNotEmpty
          ? 'local_uuid = ?'
          : serverId != null && serverId.isNotEmpty
              ? 'server_id = ?'
              : 'LOWER(name) = ?',
      whereArgs: normalizedExternalLocalUuid.isNotEmpty
          ? [normalizedExternalLocalUuid]
          : serverId != null && serverId.isNotEmpty
              ? [serverId]
              : [product.name.toLowerCase()],
      limit: 1,
    );

    final fallbackExisting =
        existing.isEmpty && (serverId != null && serverId.isNotEmpty)
        ? await db.query(
            'product',
            columns: ['id'],
            where: 'LOWER(name) = ?',
            whereArgs: [product.name.toLowerCase()],
            limit: 1,
          )
        : existing;

    final data = product.toMap()
      ..['created_at'] = product.createdAt.toIso8601String()
      ..['updated_at'] = product.updatedAt.toIso8601String()
      ..['local_uuid'] = normalizedExternalLocalUuid.isEmpty
          ? (product.localUuid ?? SyncIdentity.newLocalUuid())
          : normalizedExternalLocalUuid
      ..['server_id'] = serverId
      ..['sync_status'] = 'synced'
      ..['last_synced_at'] = DateTime.now().toIso8601String();

    if (fallbackExisting.isEmpty) {
      await db.insert('product', data);
      return;
    }

    await db.update(
      'product',
      data,
      where: 'id = ?',
      whereArgs: [fallbackExisting.first['id']],
    );
  }

  Future<void> _syncProductsFromBackend() async {
    final organizationId = await _selectedOrganizationId();
    if (organizationId == null || organizationId.isEmpty) return;

    final rows = await SupabaseService.client
        .from('products')
        .select('id, external_local_uuid, name, purchase_price, selling_price, quantity, image_path, '
            'created_at, updated_at, product_categories(name)')
        .eq('organization_id', organizationId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final categoryMap = map['product_categories'] as Map<String, dynamic>?;
      await _upsertLocalProduct(
        ProductModel(
          name: map['name'] as String? ?? '',
          category: categoryMap?['name'] as String? ?? '',
          purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
          sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0,
          quantity: (map['quantity'] as num?)?.toInt() ?? 0,
          image: map['image_path'] as String?,
          createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
          updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
              DateTime.now(),
        ),
        serverId: map['id'] as String?,
        externalLocalUuid: map['external_local_uuid'] as String?,
      );
    }
  }

  Future<void> _upsertBackendProduct(ProductModel product) async {
    final organizationId = await _selectedOrganizationId();
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (organizationId == null || organizationId.isEmpty || userId == null) {
      return;
    }

    Map<String, dynamic>? existing;
    final localUuid = _asText(product.localUuid);
    if (product.id != null) {
      final localRows = await db.query(
        'product',
        columns: ['server_id', 'local_uuid'],
        where: 'id = ?',
        whereArgs: [product.id],
        limit: 1,
      );
      if (localRows.isNotEmpty) {
        final serverId = localRows.first['server_id'] as String?;
        if (serverId != null && serverId.isNotEmpty) {
          existing = {'id': serverId};
        } else {
          final persistedLocalUuid = _asText(localRows.first['local_uuid']);
          existing = await _findBackendProductByExternalLocalUuid(
            organizationId,
            persistedLocalUuid,
          );
        }
      }
    }

    existing ??= localUuid.isNotEmpty
        ? await _findBackendProductByExternalLocalUuid(organizationId, localUuid)
        : null;

    existing ??= await SupabaseService.client
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
      'external_local_uuid': localUuid.isEmpty ? null : localUuid,
      'updated_by_user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (existing == null) {
      final created = await SupabaseService.client.from('products').insert({
        ...payload,
        'created_by_user_id': userId,
      }).select('id').single();
      if (product.id != null) {
        await db.update(
          'product',
          {
            'server_id': created['id'],
            'sync_status': 'synced',
            'last_synced_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [product.id],
        );
      }
      return;
    }

    await SupabaseService.client
        .from('products')
        .update(payload)
        .eq('id', existing['id'] as String);
    if (product.id != null) {
      await db.update(
        'product',
        {
          'server_id': existing['id'],
          'sync_status': 'synced',
          'last_synced_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [product.id],
      );
    }
  }

  Future<int> insertProduct(ProductModel product) async {
    final fullName = await accountRepo.getFullName();
    final data = product.toMap();
    data['created_by'] = fullName;
    data['updated_by'] = fullName;
    data['local_uuid'] = SyncIdentity.newLocalUuid();
    data['sync_status'] = 'pending_upload';

    final id = await db.insert('product', data);

    if (await _isBackendMode()) {
      try {
        final localProduct = await getProductById(id);
        if (localProduct != null) {
          await _upsertBackendProduct(localProduct);
        }
      } catch (_) {
        await SyncService.instance.enqueueUpsert(
          entityType: 'product',
          localUuid: data['local_uuid'] as String,
        );
      }
      _scheduleSync();
    }

    return id;
  }

  Future<List<ProductModel>> getProducts() async {
    if (await _isBackendMode()) {
      await _syncProductsFromBackend();
    }

    final result = await db.rawQuery('''
      SELECT
        p.*,
        c.name AS category_name
      FROM product p
      LEFT JOIN product_category c ON c.id = p.category_id
      ORDER BY p.id DESC
    ''');

    return result.map((e) {
      final map = Map<String, dynamic>.from(e);
      if ((map['category'] == null || (map['category'] as String).isEmpty) &&
          map['category_name'] != null) {
        map['category'] = map['category_name'];
      }
      return ProductModel.fromMap(map);
    }).toList();
  }

  Future<int> updateProduct(ProductModel product) async {
    final fullName = await accountRepo.getFullName();
    final data = product.toMap();
    data['updated_by'] = fullName;
    data['sync_status'] = 'pending_upload';

    final result = await db.update(
      'product',
      data,
      where: 'id = ?',
      whereArgs: [product.id],
    );

    if (await _isBackendMode()) {
      final localRows = await db.query(
        'product',
        columns: ['local_uuid'],
        where: 'id = ?',
        whereArgs: [product.id],
        limit: 1,
      );
      try {
        final localProduct = await getProductById(product.id!);
        if (localProduct != null) {
          await _upsertBackendProduct(localProduct);
        }
      } catch (_) {
        final localUuid = localRows.isEmpty
            ? null
            : localRows.first['local_uuid'] as String?;
        if (localUuid != null && localUuid.isNotEmpty) {
          await SyncService.instance.enqueueUpsert(
            entityType: 'product',
            localUuid: localUuid,
          );
        }
      }
      _scheduleSync();
    }

    return result;
  }

  Future<int> deleteProduct(int id) async {
    String? localUuid;
    String? serverId;
    String? name;
    if (await _isBackendMode()) {
      final existing = await db.query(
        'product',
        columns: ['name', 'server_id', 'local_uuid'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        localUuid = existing.first['local_uuid'] as String?;
        serverId = existing.first['server_id'] as String?;
        name = existing.first['name'] as String?;
        final organizationId = await _selectedOrganizationId();
        if (organizationId != null && organizationId.isNotEmpty) {
          final query = SupabaseService.client
              .from('products')
              .update({'deleted_at': DateTime.now().toUtc().toIso8601String()});
          try {
            if (serverId != null && serverId.isNotEmpty) {
              await query.eq('id', serverId);
            } else if (localUuid != null && localUuid.isNotEmpty) {
              await query
                  .eq('organization_id', organizationId)
                  .eq('external_local_uuid', localUuid);
            } else if (name != null && name.isNotEmpty) {
              await query.eq('organization_id', organizationId).eq('name', name);
            }
          } catch (_) {
            if (localUuid != null && localUuid.isNotEmpty) {
              await SyncService.instance.enqueueDelete(
                entityType: 'product',
                localUuid: localUuid,
                payload: {
                  'server_id': serverId,
                  'external_local_uuid': localUuid,
                  'name': name,
                },
              );
            }
          }
        }
      }
      _scheduleSync();
    }

    return db.delete('product', where: 'id = ?', whereArgs: [id]);
  }

  Future<ProductModel?> getProductById(int id) async {
    if (await _isBackendMode()) {
      await _syncProductsFromBackend();
    }

    final result = await db.query('product', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return ProductModel.fromMap(result.first);
    return null;
  }

  Future<void> savePurchase(List<Map<String, dynamic>> purchasedItems) async {
    final fullName = await accountRepo.getFullName();
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final item in purchasedItems) {
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

      batch.rawUpdate(
        'UPDATE product SET quantity = quantity + ? WHERE id = ?',
        [item['quantity'], item['productId']],
      );
    }

    await batch.commit(noResult: true);

    if (await _isBackendMode()) {
      final products = await getProducts();
      for (final item in purchasedItems) {
        final product = _findProductById(products, item['productId'] as int);
        if (product != null) {
          await _upsertBackendProduct(product);
        }
      }
      _scheduleSync();
    }
  }

  Future<void> updateProductStock(int productId, int quantitySold) async {
    await db.rawUpdate(
      'UPDATE product SET quantity = quantity - ? WHERE id = ?',
      [quantitySold, productId],
    );

    if (await _isBackendMode()) {
      final product = await getProductById(productId);
      if (product != null) {
        await _upsertBackendProduct(product);
      }
      _scheduleSync();
    }
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    return db.query('customer');
  }

  Future<void> checkoutCash(List<Map<String, dynamic>> items) async {
    final now = DateTime.now().toIso8601String();
    final total = items.fold<int>(
      0,
      (sum, item) => sum + (item['subtotal'] as num).toInt(),
    );
    final nameParts = await accountRepo.getNameParts();
    final saleLocalUuid = SyncIdentity.newLocalUuid();
    final saleItemLocalUuids = <String>[];

    final saleId = await db.insert('sales', {
      'sale_type': 'cash',
      'total': total,
      'created_at': now,
      'created_by_first_name': nameParts['first'],
      'created_by_middle_name': nameParts['middle'],
      'created_by_last_name': nameParts['last'],
      'local_uuid': saleLocalUuid,
      'sync_status': 'pending_upload',
    });

    for (final item in items) {
      final productId = item['productId'];
      final subtotal = (item['subtotal'] as num).toInt();
      final unitPrice = (item['price'] as num).toInt();
      final quantity = (item['quantity'] as num).toInt();
      final saleItemLocalUuid = SyncIdentity.newLocalUuid();
      saleItemLocalUuids.add(saleItemLocalUuid);

      await db.insert('sale_item', {
        'sale_id': saleId,
        'product_id': productId,
        'unit_price': unitPrice,
        'quantity': quantity,
        'subtotal': subtotal,
        'local_uuid': saleItemLocalUuid,
        'sync_status': 'pending_upload',
      });

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

      await updateProductStock(productId as int, quantity);
    }

    if (await _isBackendMode()) {
      try {
        final backendSync = await _mirrorCashSaleToBackend(
          items,
          totalAmount: total.toDouble(),
          createdAt: now,
        );
      if (backendSync != null) {
        final syncedAt = DateTime.now().toIso8601String();
        await db.update(
          'sales',
          {
            'server_id': backendSync['sale_id'],
            'sync_status': 'synced',
            'last_synced_at': syncedAt,
          },
          where: 'local_uuid = ?',
          whereArgs: [saleLocalUuid],
        );

        final backendSaleItemIds =
            (backendSync['sale_item_ids'] as List<dynamic>? ?? [])
                .cast<String>();
        for (var i = 0;
            i < saleItemLocalUuids.length && i < backendSaleItemIds.length;
            i++) {
          await db.update(
            'sale_item',
            {
              'server_id': backendSaleItemIds[i],
              'sync_status': 'synced',
              'last_synced_at': syncedAt,
            },
            where: 'local_uuid = ?',
            whereArgs: [saleItemLocalUuids[i]],
          );
        }
      }
      } catch (_) {
        await SyncService.instance.enqueueUpsert(
          entityType: 'sales',
          localUuid: saleLocalUuid,
        );
      }
      _scheduleSync();
    }
  }

  Future<void> checkoutCredit(
    List<Map<String, dynamic>> items,
    int customerId, {
    DateTime? dueDate,
  }) async {
    final nameParts = await accountRepo.getNameParts();
    final now = DateTime.now().toIso8601String();
    final due = dueDate?.toIso8601String() ??
        DateTime.now().add(const Duration(days: 30)).toIso8601String();
    final saleLocalUuid = SyncIdentity.newLocalUuid();
    final saleItemLocalUuids = <String>[];
    int? localSaleId;

    await db.transaction((txn) async {
      final customerExists = await txn.query(
        'customer',
        where: 'id = ?',
        whereArgs: [customerId],
      );
      if (customerExists.isEmpty) throw Exception('Customer does not exist');

      final currentCredit =
          (customerExists.first['available_credit'] as num?)?.toDouble() ??
              1000.0;

      final statusResult = await txn.query(
        'credit_status',
        where: 'code = ?',
        whereArgs: [0],
      );
      if (statusResult.isEmpty) {
        throw Exception('Credit status "unpaid" not found');
      }
      final statusId = statusResult.first['id'] as int;

      final saleId = await txn.insert('sales', {
        'customer_id': customerId,
        'sale_type': 'credit',
        'total': items.fold<int>(
          0,
          (sum, item) => sum + (item['subtotal'] as num).toInt(),
        ),
        'created_at': now,
        'created_by_first_name': nameParts['first'],
        'created_by_middle_name': nameParts['middle'],
        'created_by_last_name': nameParts['last'],
        'local_uuid': saleLocalUuid,
        'sync_status': 'pending_upload',
      });
      localSaleId = saleId;

      for (final item in items) {
        final productId = item['productId'] as int;
        final subtotal = (item['subtotal'] as num).toInt();
        final unitPrice = (item['price'] as num).toInt();
        final quantity = (item['quantity'] as num).toInt();
        final saleItemLocalUuid = SyncIdentity.newLocalUuid();
        final salesCreditLocalUuid = SyncIdentity.newLocalUuid();
        saleItemLocalUuids.add(saleItemLocalUuid);

        await txn.insert('sale_item', {
          'sale_id': saleId,
          'product_id': productId,
          'unit_price': unitPrice,
          'quantity': quantity,
          'subtotal': subtotal,
          'local_uuid': saleItemLocalUuid,
          'sync_status': 'pending_upload',
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
          'created_by_first_name': nameParts['first'],
          'created_by_middle_name': nameParts['middle'],
          'created_by_last_name': nameParts['last'],
          'local_uuid': salesCreditLocalUuid,
          'sync_status': 'pending_upload',
        });

        await txn.rawUpdate(
          'UPDATE product SET quantity = quantity - ? WHERE id = ?',
          [quantity, productId],
        );
      }

      final totalAmount = items.fold<double>(
        0,
        (sum, item) => sum + (item['subtotal'] as num).toDouble(),
      );
      final newCredit = (currentCredit - totalAmount).clamp(0, double.infinity);

      await txn.update(
        'customer',
        {'available_credit': newCredit},
        where: 'id = ?',
        whereArgs: [customerId],
      );
    });

    if (await _isBackendMode()) {
      try {
        final backendSync = await _mirrorCreditSaleToBackend(
          items,
          customerId: customerId,
          totalAmount: items.fold<double>(
            0,
            (sum, item) => sum + (item['subtotal'] as num).toDouble(),
          ),
          createdAt: now,
          dueDate: due,
        );
        if (backendSync != null && localSaleId != null) {
          final syncedAt = DateTime.now().toIso8601String();
          await db.update(
            'sales',
            {
              'server_id': backendSync['sale_id'],
              'sync_status': 'synced',
              'last_synced_at': syncedAt,
            },
            where: 'local_uuid = ?',
            whereArgs: [saleLocalUuid],
          );

          final backendSaleItemIds =
              (backendSync['sale_item_ids'] as List<dynamic>? ?? [])
                  .cast<String>();
          for (var i = 0;
              i < saleItemLocalUuids.length && i < backendSaleItemIds.length;
              i++) {
            await db.update(
              'sale_item',
              {
                'server_id': backendSaleItemIds[i],
                'sync_status': 'synced',
                'last_synced_at': syncedAt,
              },
              where: 'local_uuid = ?',
              whereArgs: [saleItemLocalUuids[i]],
            );
          }

          await db.update(
            'sales_credit',
            {
              'server_id': backendSync['receivable_id'],
              'sync_status': 'synced',
              'last_synced_at': syncedAt,
            },
            where: 'sale_id = ?',
            whereArgs: [localSaleId],
          );
        }
      } catch (_) {
        await SyncService.instance.enqueueUpsert(
          entityType: 'sales',
          localUuid: saleLocalUuid,
        );
      }
      _scheduleSync();

      final products = await getProducts();
      for (final item in items) {
        final productId = item['productId'] as int;
        final product = _findProductById(products, productId);
        if (product != null) {
          await _upsertBackendProduct(product);
        }
      }
    }
  }
}
