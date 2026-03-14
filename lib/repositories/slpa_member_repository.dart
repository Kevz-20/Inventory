import 'dart:async';

import '../repositories/account_repository.dart';
import '../services/audit_log_service.dart';
import '../services/auto_sync_service.dart';
import '../services/db_service.dart';

class SlpaMemberRepository {
  SlpaMemberRepository(this._dbService, this._accountRepository);

  final DBService _dbService;
  final AccountRepository _accountRepository;

  Future<bool> isMobileNumberExists(String mobileNumber) async {
    final db = await _dbService.database;
    final rows = await db.query(
      'slpa_member',
      columns: ['id'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber.trim()],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> addMember({
    int? accountId,
    required String firstName,
    String? middleName,
    required String lastName,
    required String mobileNumber,
    required String pin,
    required int securityQuestionId,
    required String securityAnswer,
  }) async {
    final db = await _dbService.database;
    int resolvedAccountId;
    if (accountId != null) {
      resolvedAccountId = accountId;
    } else {
      try {
        resolvedAccountId = await _accountRepository.getAccountId();
      } catch (_) {
        final accountRows = await db.query(
          'account',
          columns: ['id'],
          orderBy: 'id ASC',
          limit: 1,
        );
        if (accountRows.isEmpty) {
          throw Exception('No association found for member creation');
        }
        resolvedAccountId = accountRows.first['id'] as int;
      }
    }
    final now = DateTime.now().toIso8601String();

    final memberId = await db.insert('slpa_member', {
      'account_id': resolvedAccountId,
      'first_name': firstName.trim(),
      'middle_name': middleName?.trim(),
      'last_name': lastName.trim(),
      'mobile_number': mobileNumber.trim(),
      'pin': pin.trim(),
      'security_question_id': securityQuestionId,
      'security_answer': securityAnswer.trim(),
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending',
      'last_synced_at': null,
      'is_deleted': 0,
    });

    final createdName = [
      firstName.trim(),
      middleName?.trim() ?? '',
      lastName.trim(),
    ].where((part) => part.isNotEmpty).join(' ');

    await AuditLogService.instance.log(
      accountId: resolvedAccountId,
      memberId: accountId != null ? memberId : null,
      memberName: accountId != null ? createdName : null,
      module: accountId != null ? 'first_member_setup' : 'member_management',
      tableName: 'slpa_member',
      recordId: memberId.toString(),
      action: 'create',
      newValue: {
        'first_name': firstName.trim(),
        'middle_name': middleName?.trim(),
        'last_name': lastName.trim(),
        'mobile_number': mobileNumber.trim(),
      },
    );

    unawaited(AutoSyncService.instance.tryAutoSync(force: true));
  }

  Future<List<String>> getSecurityQuestions() async {
    final db = await _dbService.database;
    final result = await db.query('security_questions', orderBy: 'id ASC');
    return result.map((row) => row['question'] as String).toList();
  }
}
