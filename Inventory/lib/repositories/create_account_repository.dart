import '../models/create_account_model.dart';
import '../services/audit_log_service.dart';
import '../services/db_service.dart';

class CreateAccountRepository {
  final DBService _dbService;

  CreateAccountRepository(this._dbService);

  // ---------------- CHECK IF SLPA NAME EXISTS ----------------
  Future<bool> isSlpaNameExists(String slpaName) async {
    final db = await _dbService.database;
    final result = await db.query(
      'account',
      where: 'slpa_name = ?',
      whereArgs: [slpaName.trim()],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // ---------------- CREATE NEW ACCOUNT ----------------
  Future<int> createAccount(Account account) async {
    final db = await _dbService.database;
    final now = DateTime.now().toIso8601String();
    final data = {
      ...account.toMap(),
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending',
      'last_synced_at': null,
      'is_deleted': 0,
    };
    final accountId = await db.insert('account', data);
    await AuditLogService.instance.log(
      accountId: accountId,
      module: 'association_setup',
      tableName: 'account',
      recordId: accountId.toString(),
      action: 'create',
      newValue: {'slpa_name': account.slpaName},
    );
    return accountId;
  }

  // ---------------- FETCH ACCOUNT BY PHONE NUMBER ----------------
  Future<Account?> getAccountByPhone(String phoneNumber) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      '''
      SELECT a.*
      FROM slpa_member m
      INNER JOIN account a ON a.id = m.account_id
      WHERE m.mobile_number = ?
      LIMIT 1
      ''',
      [phoneNumber.trim()],
    );
    if (result.isNotEmpty) return Account.fromMap(result.first);
    return null;
  }

  // ---------------- FETCH ACCOUNT BY SLPA NAME ----------------
  Future<Account?> getAccountBySlpaName(String slpaName) async {
    final db = await _dbService.database;
    final result = await db.query(
      'account',
      where: 'slpa_name = ?',
      whereArgs: [slpaName.trim()],
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
