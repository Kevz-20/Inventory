import 'package:sqflite/sqflite.dart';

class CustomerRepository {
  final Database _db;

  // Inject DB only, AccountRepository no longer needed
  CustomerRepository(this._db);

  /// Insert a new customer
  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final customerWithDefaults = {
      ...customer,
      'available_credit': customer['available_credit'] ?? 1000.0, // default
      'created_at': customer['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': customer['updated_at'] ?? DateTime.now().toIso8601String(),
    };

    return await _db.insert(
      'customer',
      customerWithDefaults,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Update an existing customer by ID
  Future<int> updateCustomer(int id, Map<String, dynamic> updatedCustomer) async {
    return await _db.update(
      'customer',
      updatedCustomer,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a customer by ID
  Future<int> deleteCustomer(int id) async {
    return await _db.delete(
      'customer',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all customers
  Future<List<Map<String, dynamic>>> getCustomers() async {
    return await _db.query(
      'customer',
      orderBy: 'first_name ASC',
    );
  }

  /// Get a single customer by ID
  Future<Map<String, dynamic>?> getCustomerById(int id) async {
    final result = await _db.query(
      'customer',
      where: 'id = ?',
      whereArgs: [id],
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
    // 1️⃣ Get current credit
    final currentCredit = await getAvailableCredit(customerId);

    // 2️⃣ Calculate new credit safely (never below 0)
    final newCredit = (currentCredit - amount).clamp(0.0, double.infinity);

    // 3️⃣ Update in DB
    await _db.update(
      'customer',
      {'available_credit': newCredit},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  /// ------------------- OPTIONAL -------------------
  /// Get customer by full name (useful for multi-user associations)
  Future<Map<String, dynamic>?> getCustomerByFullName(
      String firstName, String? middleName, String lastName) async {
    final result = await _db.query(
      'customer',
      where: 'first_name = ? AND middle_name = ? AND last_name = ?',
      whereArgs: [firstName, middleName, lastName],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  /// Check if phone number already exists
  Future<bool> isPhoneExists(String phone) async {
    final result = await _db.query(
      'customer',
      where: 'phone_number = ?',
      whereArgs: [phone],
      limit: 1,
    );
    return result.isNotEmpty;
  }

/// Check if full name already exists
  Future<bool> isNameExists(
    String firstName,
    String? middleName,
    String lastName,
  ) async {
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
}
