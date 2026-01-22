import 'package:sqflite/sqflite.dart';
import 'account_repository.dart';

class CustomerRepository {
  final Database _db;
  final AccountRepository _accountRepository = AccountRepository();

  CustomerRepository(this._db);

  /// Insert a new customer for the current logged-in account
  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final accountId = await _accountRepository.getAccountId();

    final customerWithAccount = {
      ...customer,
      'account_id': accountId, // Link to current account
    };

    return await _db.insert(
      'customer',
      customerWithAccount,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing customer by ID (account-specific)
  Future<int> updateCustomer(int id, Map<String, dynamic> updatedCustomer) async {
    final accountId = await _accountRepository.getAccountId();

    final customerWithAccount = {
      ...updatedCustomer,
      'account_id': accountId,
    };

    return await _db.update(
      'customer',
      customerWithAccount,
      where: 'id = ? AND account_id = ?',
      whereArgs: [id, accountId],
    );
  }

  /// Delete a customer by ID (account-specific)
  Future<int> deleteCustomer(int id) async {
    final accountId = await _accountRepository.getAccountId();
    return await _db.delete(
      'customer',
      where: 'id = ? AND account_id = ?',
      whereArgs: [id, accountId],
    );
  }

  /// Get all customers
  /// If [shared] is false, fetch only for current account
  Future<List<Map<String, dynamic>>> getCustomers({bool allAccounts = false}) async {
  if (allAccounts) {
    // Fetch customers from ALL accounts
    return await _db.query(
      'customer',
      orderBy: 'first_name ASC',
    );
  }

  // Default: fetch only for current logged-in account
  final currentAccountId = await _accountRepository.getAccountId();
  return await _db.query(
    'customer',
    where: 'account_id = ?',
    whereArgs: [currentAccountId],
    orderBy: 'first_name ASC',
  );
}

  /// Get a single customer by ID (account-specific)
  Future<Map<String, dynamic>?> getCustomerById(int id) async {
    final accountId = await _accountRepository.getAccountId();
    final result = await _db.query(
      'customer',
      where: 'id = ? AND account_id = ?',
      whereArgs: [id, accountId],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}
