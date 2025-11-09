import '../models/create_account_model.dart';
import '../services/db_service.dart';

class CreateAccountRepository {
  final DBService _dbService;

  CreateAccountRepository(this._dbService);

  // Check if phone number exists
  Future<bool> isPhoneNumberExists(
    String mobileNumber,
    String associationName,
  ) async {
    final db = await _dbService.database;
    final result = await db.query(
      'account',
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber, associationName],
    );
    return result.isNotEmpty;
  }

  // Insert a new account
  Future<int> createAccount(Account account) async {
    final db = await _dbService.database;

    // Insert account into DB (will fail if primary key exists)
    return await db.insert('account', account.toMap());
  }

  // Fetch account by phone number
  Future<Account?> getAccountByPhone(String phoneNumber) async {
    final db = await _dbService.database;
    final result = await db.query(
      'account',
      where: 'mobile_number = ?',
      whereArgs: [phoneNumber],
    );
    if (result.isNotEmpty) return Account.fromMap(result.first);
    return null;
  }

  // Fetch all security questions
  Future<List<String>> getSecurityQuestions() async {
    final db = await _dbService.database;
    final result = await db.query('security_questions');
    return result.map((row) => row['question'] as String).toList();
  }

  // Delete all accounts
  Future<void> wipeAccounts() async {
    final db = await _dbService.database;
    await db.delete('account');
  }
}
