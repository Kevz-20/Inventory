import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../core/sync_identity.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';

class CustomerRepository {
  final Database _db;

  CustomerRepository(this._db);

  void _scheduleSync() {
    unawaited(SyncService.instance.triggerBackgroundSync());
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

  Future<Map<String, dynamic>?> _getLocalCustomerById(int id) async {
    final result = await _db.query(
      'customer',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<String?> _currentBackendUserId() async {
    return SupabaseService.client.auth.currentUser?.id;
  }

  String _asText(Object? raw) => raw?.toString().trim() ?? '';

  Future<Map<String, dynamic>?> _findBackendCustomerByExternalLocalUuid({
    required String organizationId,
    required String localUuid,
  }) async {
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

  Future<Map<String, dynamic>?> _currentLocalAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final mobileNumber = prefs.getString('mobileNumber') ?? '';
    if (mobileNumber.isEmpty) return null;

    final rows = await _db.query(
      'account',
      columns: ['id', 'first_name', 'middle_name', 'last_name'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> _upsertLocalCustomer(Map<String, dynamic> customer) async {
    final phoneNumber = _asText(customer['phone_number']);
    final serverId = _asText(customer['server_id']);
    final externalLocalUuid = _asText(customer['local_uuid']);
    final firstName = _asText(customer['first_name']);
    final middleName = _asText(customer['middle_name']);
    final lastName = _asText(customer['last_name']);
    final municipality = _asText(customer['municipality']);

    List<Map<String, dynamic>> existing = [];
    if (externalLocalUuid.isNotEmpty) {
      existing = await _db.query(
        'customer',
        columns: ['id'],
        where: 'local_uuid = ?',
        whereArgs: [externalLocalUuid],
        limit: 1,
      );
    }

    if (serverId.isNotEmpty) {
      existing = await _db.query(
        'customer',
        columns: ['id'],
        where: 'server_id = ?',
        whereArgs: [serverId],
        limit: 1,
      );
    }

    if (existing.isEmpty && phoneNumber.isNotEmpty) {
      existing = await _db.query(
        'customer',
        columns: ['id'],
        where: 'phone_number = ?',
        whereArgs: [phoneNumber],
        limit: 1,
      );
    }

    if (existing.isEmpty) {
      existing = await _db.query(
        'customer',
        columns: ['id'],
        where:
            'first_name = ? AND COALESCE(middle_name, "") = ? AND last_name = ? AND municipality = ?',
        whereArgs: [firstName, middleName, lastName, municipality],
        limit: 1,
      );
    }

    final data = {
      'first_name': firstName,
      'middle_name': middleName.isEmpty ? null : middleName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'municipality': municipality,
      'barangay': customer['barangay'],
      'landmark': customer['landmark'],
      'credit_limit': customer['credit_limit'] ?? 1000.0,
      'available_credit': customer['available_credit'] ?? 1000.0,
      'created_at':
          customer['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at':
          customer['updated_at'] ?? DateTime.now().toIso8601String(),
      'local_uuid': externalLocalUuid.isEmpty
          ? SyncIdentity.newLocalUuid()
          : externalLocalUuid,
      'server_id': serverId.isEmpty ? null : serverId,
      'sync_status': customer['sync_status'] ?? 'synced',
      'last_synced_at':
          customer['last_synced_at'] ?? DateTime.now().toIso8601String(),
    };

    if (existing.isEmpty) {
      await _db.insert('customer', data);
      return;
    }

    await _db.update(
      'customer',
      data,
      where: 'id = ?',
      whereArgs: [existing.first['id']],
    );
  }

  Future<Map<String, dynamic>?> _findBackendCustomerByIdentity({
    required String organizationId,
    required Map<String, dynamic> customer,
  }) async {
    final serverId = customer['server_id'] as String?;
    if (serverId != null && serverId.isNotEmpty) {
      return {'id': serverId};
    }

    final localUuid = _asText(customer['local_uuid']);
    if (localUuid.isNotEmpty) {
      final byExternalKey = await _findBackendCustomerByExternalLocalUuid(
        organizationId: organizationId,
        localUuid: localUuid,
      );
      if (byExternalKey != null) {
        return byExternalKey;
      }
    }

    final phoneNumber = _asText(customer['phone_number']);

    if (phoneNumber.isNotEmpty) {
      final row = await SupabaseService.client
          .from('customers')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('phone_number', phoneNumber)
          .limit(1)
          .maybeSingle();
      if (row != null) return Map<String, dynamic>.from(row);
    }

    final row = await SupabaseService.client
        .from('customers')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('first_name', customer['first_name'] as String)
        .eq('middle_name', customer['middle_name'] as String? ?? '')
        .eq('last_name', customer['last_name'] as String)
        .eq('municipality', customer['municipality'] as String)
        .limit(1)
        .maybeSingle();

    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> _findBackendReceivablesForCustomer(
    String organizationId,
    String backendCustomerId,
  ) async {
    final rows = await SupabaseService.client
        .from('receivables')
        .select('id, remaining_amount')
        .eq('organization_id', organizationId)
        .eq('customer_id', backendCustomerId)
        .inFilter('status', ['unpaid', 'partial'])
        .order('created_at', ascending: true);

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> _upsertBackendCustomer(Map<String, dynamic> customer) async {
    final organizationId = await _selectedOrganizationId();
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (organizationId == null || organizationId.isEmpty || userId == null) {
      return;
    }

    final normalized = {
      'first_name': (customer['first_name'] ?? '').toString().trim(),
      'middle_name': (customer['middle_name'] ?? '').toString().trim(),
      'last_name': (customer['last_name'] ?? '').toString().trim(),
      'phone_number': (customer['phone_number'] ?? '').toString().trim(),
      'municipality': (customer['municipality'] ?? '').toString().trim(),
      'barangay': (customer['barangay'] ?? '').toString().trim(),
      'landmark': (customer['landmark'] ?? '').toString().trim(),
      'credit_limit': customer['credit_limit'] ?? 1000.0,
      'available_credit': customer['available_credit'] ?? 1000.0,
      'external_local_uuid': _asText(customer['local_uuid']),
    };

    final existing = await _findBackendCustomerByIdentity(
      organizationId: organizationId,
      customer: normalized,
    );

    final payload = {
      'organization_id': organizationId,
      ...normalized,
      'updated_by_user_id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (existing == null) {
      final created = await SupabaseService.client.from('customers').insert({
        ...payload,
        'created_by_user_id': userId,
      }).select('id').single();
      final localUuid = customer['local_uuid'];
      if (localUuid != null) {
        await _db.update(
          'customer',
          {
            'server_id': created['id'],
            'sync_status': 'synced',
            'last_synced_at': DateTime.now().toIso8601String(),
          },
          where: 'local_uuid = ?',
          whereArgs: [localUuid],
        );
      }
      return;
    }

    await SupabaseService.client
        .from('customers')
        .update(payload)
        .eq('id', existing['id'] as String);
    final localUuid = customer['local_uuid'];
    if (localUuid != null) {
      await _db.update(
        'customer',
        {
          'server_id': existing['id'],
          'sync_status': 'synced',
          'last_synced_at': DateTime.now().toIso8601String(),
        },
        where: 'local_uuid = ?',
        whereArgs: [localUuid],
      );
    }
  }

  Future<List<String>> _mirrorCustomerPaymentToBackend({
    required int customerId,
    required double amount,
    required String paidAt,
  }) async {
    final organizationId = await _selectedOrganizationId();
    final userId = await _currentBackendUserId();
    if (organizationId == null || organizationId.isEmpty || userId == null) {
      return const [];
    }

    final localCustomer = await _getLocalCustomerById(customerId);
    if (localCustomer == null) return const [];

    final backendCustomer = await _findBackendCustomerByIdentity(
      organizationId: organizationId,
      customer: localCustomer,
    );
    if (backendCustomer == null) return const [];

    double remainingPayment = amount;
    final paymentIds = <String>[];
    final receivables = await _findBackendReceivablesForCustomer(
      organizationId,
      backendCustomer['id'] as String,
    );

    for (final receivable in receivables) {
      if (remainingPayment <= 0) break;

      final currentRemaining =
          (receivable['remaining_amount'] as num?)?.toDouble() ?? 0.0;
      if (currentRemaining <= 0) continue;

      final appliedAmount = remainingPayment > currentRemaining
          ? currentRemaining
          : remainingPayment;
      final updatedRemaining = currentRemaining - appliedAmount;
      final updatedStatus = updatedRemaining <= 0 ? 'paid' : 'partial';

      final paymentRow = await SupabaseService.client
          .from('receivable_payments')
          .insert({
            'organization_id': organizationId,
            'receivable_id': receivable['id'] as String,
            'amount': appliedAmount,
            'paid_at': paidAt,
            'created_by_user_id': userId,
          })
          .select('id')
          .single();
      paymentIds.add(paymentRow['id'] as String);

      await SupabaseService.client
          .from('receivables')
          .update({
            'remaining_amount': updatedRemaining,
            'status': updatedStatus,
            'updated_by_user_id': userId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', receivable['id'] as String);

      remainingPayment -= appliedAmount;
    }

    return paymentIds;
  }

  Future<void> _syncCustomersFromBackend() async {
    final organizationId = await _selectedOrganizationId();
    if (organizationId == null || organizationId.isEmpty) return;

    final rows = await SupabaseService.client
        .from('customers')
        .select(
          'id, first_name, middle_name, last_name, phone_number, municipality, '
          'barangay, landmark, credit_limit, available_credit, created_at, updated_at',
        )
        .eq('organization_id', organizationId)
        .isFilter('deleted_at', null)
        .order('first_name', ascending: true);

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      map['server_id'] = map['id'];
      map['local_uuid'] = map['external_local_uuid'];
      await _upsertLocalCustomer(map);
    }
  }

  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final customerWithDefaults = {
      ...customer,
      'available_credit': customer['available_credit'] ?? 1000.0,
      'credit_limit': customer['credit_limit'] ?? 1000.0,
      'created_at': customer['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': customer['updated_at'] ?? DateTime.now().toIso8601String(),
      'local_uuid': customer['local_uuid'] ?? SyncIdentity.newLocalUuid(),
      'sync_status': customer['sync_status'] ?? 'pending_upload',
    };

    final id = await _db.insert(
      'customer',
      customerWithDefaults,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    if (await _isBackendMode()) {
      try {
        await _upsertBackendCustomer(customerWithDefaults);
      } catch (_) {
        await SyncService.instance.enqueueUpsert(
          entityType: 'customer',
          localUuid: customerWithDefaults['local_uuid'] as String,
        );
      }
      _scheduleSync();
    }

    return id;
  }

  Future<int> updateCustomer(int id, Map<String, dynamic> updatedCustomer) async {
    final payload = {
      ...updatedCustomer,
      'sync_status': 'pending_upload',
    };
    final result = await _db.update(
      'customer',
      payload,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (await _isBackendMode()) {
      final local = await _getLocalCustomerById(id);
      if (local != null) {
        try {
          await _upsertBackendCustomer(local);
        } catch (_) {
          final localUuid = local['local_uuid'] as String?;
          if (localUuid != null && localUuid.isNotEmpty) {
            await SyncService.instance.enqueueUpsert(
              entityType: 'customer',
              localUuid: localUuid,
            );
          }
        }
      }
      _scheduleSync();
    }

    return result;
  }

  Future<int> deleteCustomer(int id) async {
    String? localUuid;
    String? serverId;
    String? phoneNumber;
    String? firstName;
    String? middleName;
    String? lastName;
    String? municipality;
    if (await _isBackendMode()) {
      final local = await _getLocalCustomerById(id);
      final organizationId = await _selectedOrganizationId();
      if (local != null && organizationId != null && organizationId.isNotEmpty) {
        localUuid = local['local_uuid'] as String?;
        serverId = local['server_id'] as String?;
        phoneNumber = (local['phone_number'] ?? '').toString();
        firstName = (local['first_name'] ?? '').toString();
        middleName = (local['middle_name'] ?? '').toString();
        lastName = (local['last_name'] ?? '').toString();
        municipality = (local['municipality'] ?? '').toString();
        final existing = await _findBackendCustomerByIdentity(
          organizationId: organizationId,
          customer: local,
        );
        if (existing != null) {
          try {
            await SupabaseService.client
                .from('customers')
                .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
                .eq('id', existing['id'] as String);
          } catch (_) {
            if (localUuid != null && localUuid.isNotEmpty) {
              await SyncService.instance.enqueueDelete(
                entityType: 'customer',
                localUuid: localUuid,
                payload: {
                  'server_id': serverId,
                  'external_local_uuid': localUuid,
                  'phone_number': phoneNumber,
                  'first_name': firstName,
                  'middle_name': middleName,
                  'last_name': lastName,
                  'municipality': municipality,
                },
              );
            }
          }
        }
      }
      _scheduleSync();
    }

    return _db.delete('customer', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    if (await _isBackendMode()) {
      await _syncCustomersFromBackend();
    }

    return _db.query('customer', orderBy: 'first_name ASC');
  }

  Future<Map<String, dynamic>?> getCustomerById(int id) async {
    if (await _isBackendMode()) {
      await _syncCustomersFromBackend();
    }

    final result = await _db.query('customer', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<double> getAvailableCredit(int customerId) async {
    final customer = await getCustomerById(customerId);
    if (customer != null) {
      final credit = customer['available_credit'];
      if (credit is int) return credit.toDouble();
      if (credit is double) return credit;
      if (credit is num) return credit.toDouble();
    }
    return 1000.0;
  }

  Future<void> deductAvailableCredit(int customerId, double amount) async {
    final currentCredit = await getAvailableCredit(customerId);
    final newCredit = (currentCredit - amount).clamp(0.0, double.infinity);

    await _db.update(
      'customer',
      {
        'available_credit': newCredit,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customerId],
    );

    if (await _isBackendMode()) {
      final local = await _getLocalCustomerById(customerId);
      if (local != null) {
        await _upsertBackendCustomer(local);
      }
      _scheduleSync();
    }
  }

  Future<Map<String, dynamic>?> getCustomerByFullName(
    String firstName,
    String? middleName,
    String lastName,
  ) async {
    if (await _isBackendMode()) {
      await _syncCustomersFromBackend();
    }

    final result = await _db.query(
      'customer',
      where: 'first_name = ? AND middle_name = ? AND last_name = ?',
      whereArgs: [firstName, middleName, lastName],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<bool> isPhoneExists(String phone) async {
    if (await _isBackendMode()) {
      await _syncCustomersFromBackend();
    }

    final result = await _db.query(
      'customer',
      where: 'phone_number = ?',
      whereArgs: [phone],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<bool> isNameExists(
    String firstName,
    String? middleName,
    String lastName,
  ) async {
    if (await _isBackendMode()) {
      await _syncCustomersFromBackend();
    }

    final result = await _db.query(
      'customer',
      where: 'first_name = ? AND middle_name = ? AND last_name = ?',
      whereArgs: [
        firstName.trim(),
        middleName?.trim() ?? '',
        lastName.trim(),
      ],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> addCustomerPayment({
    required int customerId,
    required double amount,
  }) async {
    final account = await _currentLocalAccount();
    final paidAt = DateTime.now().toIso8601String();
    final localUuid = SyncIdentity.newLocalUuid();

    await _db.insert('customer_payment', {
      'customer_id': customerId,
      'account_id': account?['id'],
      'amount': amount,
      'paid_at': paidAt,
      'created_by_first_name': account?['first_name'] ?? '',
      'created_by_middle_name': account?['middle_name'] ?? '',
      'created_by_last_name': account?['last_name'] ?? '',
      'local_uuid': localUuid,
      'sync_status': 'pending_upload',
    });

    final currentCredit = await getAvailableCredit(customerId);
    await updateCustomer(customerId, {
      'available_credit': currentCredit + amount,
      'updated_at': DateTime.now().toIso8601String(),
    });

    if (await _isBackendMode()) {
      try {
        final paymentIds = await _mirrorCustomerPaymentToBackend(
          customerId: customerId,
          amount: amount,
          paidAt: paidAt,
        );
        await _db.update(
          'customer_payment',
          {
            'server_id': paymentIds.length == 1 ? paymentIds.first : null,
            'sync_status': 'synced',
            'last_synced_at': DateTime.now().toIso8601String(),
          },
          where: 'local_uuid = ?',
          whereArgs: [localUuid],
        );
      } catch (_) {
        await SyncService.instance.enqueueUpsert(
          entityType: 'customer_payment',
          localUuid: localUuid,
        );
      }
      _scheduleSync();
    }
  }

  Future<void> increaseCreditLimit({
    required int customerId,
    required double amount,
  }) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) return;

    final currentCreditLimit =
        (customer['credit_limit'] as num?)?.toDouble() ?? 0.0;
    final currentAvailableCredit =
        (customer['available_credit'] as num?)?.toDouble() ?? 0.0;

    await updateCustomer(customerId, {
      'credit_limit': currentCreditLimit + amount,
      'available_credit': currentAvailableCredit + amount,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
