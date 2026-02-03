import 'package:sqflite/sqflite.dart';
import 'account_repository.dart';

class CustomerRepository {
  final Database _db;
  final AccountRepository _accountRepository;

  // Inject both DB and AccountRepository
  CustomerRepository(this._db, this._accountRepository);

  /// Insert a new customer for the current logged-in account
  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final accountId = await _accountRepository.getAccountId();

    final customerWithAccount = {
      ...customer,
      'account_id': accountId, // Link to current account
      'available_credit': customer['available_credit'] ?? 1000.0, // default
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
    return await _db.update(
      'customer',
      updatedCustomer,
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
  Future<List<Map<String, dynamic>>> getCustomers({bool allAccounts = false}) async {
    if (allAccounts) {
      return await _db.query(
        'customer',
        orderBy: 'first_name ASC',
      );
    }

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
    if (result.isNotEmpty) return result.first;
    return null;
  }

  /// ------------------- NEW METHODS -------------------

  /// Get available credit for a specific customer
  Future<double> getAvailableCredit(int customerId) async {
    final customer = await getCustomerById(customerId);
    if (customer != null) {
      final credit = customer['available_credit'];
      if (credit is int) return credit.toDouble();
      if (credit is double) return credit;
    }
    return 1000.0; // default
  }

  /// Deduct available credit after utang / credit checkout
  Future<void> deductAvailableCredit(int customerId, double amount) async {
    final accountId = await _accountRepository.getAccountId();

    // 1️⃣ Get current credit
    final currentCredit = await getAvailableCredit(customerId);

    // 2️⃣ Calculate new credit safely (never below 0)
    final newCredit = (currentCredit - amount).clamp(0.0, double.infinity);

    // 3️⃣ Update in DB
    await _db.update(
      'customer',
      {'available_credit': newCredit},
      where: 'id = ? AND account_id = ?',
      whereArgs: [customerId, accountId],
    );
  }
}
