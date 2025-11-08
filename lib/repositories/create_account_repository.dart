import 'package:sqflite/sqflite.dart';
import '../models/create_account_model.dart';
import '../services/db_service.dart';

class CreateAccountRepository {
  final DBService _dbService;

  CreateAccountRepository(this._dbService);

  // Check if phone number exists for a specific association
  Future<bool> isPhoneNumberExists(
    String phoneNumber,
    String associationName,
  ) async {
    final db = await _dbService.database;
    final result = await db.query(
      'account',
      where: 'phone_number = ? AND association_name = ?',
      whereArgs: [phoneNumber, associationName],
    );
    return result.isNotEmpty;
  }

  // Insert a new account, abort if duplicate for the same association
  Future<int> createAccount(Account account) async {
    final db = await _dbService.database;

    // Prevent duplicate for same association
    if (await isPhoneNumberExists(
      account.phoneNumber,
      account.associationName!,
    )) {
      throw Exception('Phone number already exists for this association');
    }

    return await db.insert(
      'account',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort, // do not replace
    );
  }

  // Fetch account by phone number
  Future<Account?> getAccountByPhone(String phoneNumber) async {
    final db = await _dbService.database;
    final result = await db.query(
      'account',
      where: 'phone_number = ?',
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
}
