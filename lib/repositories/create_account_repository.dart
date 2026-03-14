import '../models/create_account_model.dart';
import '../services/db_service.dart';

class CreateAccountRepository {
  final DBService _dbService;

  CreateAccountRepository(this._dbService);

  // ---------------- CHECK IF PHONE NUMBER EXISTS ----------------
  Future<bool> isPhoneNumberExists(String mobileNumber) async {
    final db = await _dbService.database;
    final result = await db.query(
      'account',
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber.trim()],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ---------------- CHECK IF FULL NAME EXISTS ----------------
  Future<bool> isFullNameExists(
    String firstName,
    String? middleName,
    String lastName,
  ) async {
    final db = await _dbService.database;

    // Use COALESCE to treat NULL middle names as empty string
    final result = await db.query(
      'account',
      where: 'first_name = ? AND COALESCE(middle_name, "") = ? AND last_name = ?',
      whereArgs: [firstName.trim(), middleName?.trim() ?? '', lastName.trim()],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // ---------------- CREATE NEW ACCOUNT ----------------
  Future<int> createAccount(Account account) async {
    final db = await _dbService.database;

    // Insert account into DB (will fail if primary key exists)
    return await db.insert('account', account.toMap());
  }

  Future<void> upsertLocalAccount(Account account) async {
    final db = await _dbService.database;
    final existing = await db.query(
      'account',
      where: 'mobile_number = ?',
      whereArgs: [account.mobileNumber.trim()],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('account', account.toMap());
      return;
    }

    await db.update(
      'account',
      account.toMap(),
      where: 'mobile_number = ?',
      whereArgs: [account.mobileNumber.trim()],
    );
  }

  // ---------------- FETCH ACCOUNT BY PHONE NUMBER ----------------
  Future<Account?> getAccountByPhone(String phoneNumber) async {
    final db = await _dbService.database;
    final result = await db.query(
      'account',
      where: 'mobile_number = ?',
      whereArgs: [phoneNumber.trim()],
      limit: 1,
    );
    if (result.isNotEmpty) return Account.fromMap(result.first);
    return null;
  }

  // ---------------- FETCH ACCOUNT BY FULL NAME ----------------
  Future<Account?> getAccountByFullName(
    String firstName,
    String? middleName,
    String lastName,
  ) async {
    final db = await _dbService.database;
    final result = await db.query(
      'account',
      where: 'first_name = ? AND middle_name = ? AND last_name = ?',
      whereArgs: [firstName.trim(), middleName?.trim() ?? '', lastName.trim()],
      limit: 1,
    );
    if (result.isNotEmpty) return Account.fromMap(result.first);
    return null;
  }

  // ---------------- FETCH ALL SECURITY QUESTIONS ----------------
  Future<List<String>> getSecurityQuestions() async {
    final db = await _dbService.database;
    final result = await db.query('security_questions');
    return result.map((row) => row['question'] as String).toList();
  }

  // ---------------- DELETE ALL ACCOUNTS ----------------
  Future<void> wipeAccounts() async {
    final db = await _dbService.database;
    await db.delete('account');
  }
}
