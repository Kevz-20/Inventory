import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_model.dart';
import '../services/audit_log_service.dart';
import '../services/auto_sync_service.dart';
import '../services/db_service.dart';

class AccountRepository {
  final dbService = DBService.instance;

  /// Get current logged-in mobile number from SharedPreferences
  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobileNumber');
    if (mobile == null) {
      throw Exception('No mobile number stored in SharedPreferences');
    }
    return mobile;
  }

  /// Get current account ID by mobile number
  Future<int> getAccountId() async {
    final mobileNumber = await getMobileNumber();
    final db = await dbService.database;
    final result = await db.query(
      'slpa_member',
      columns: ['account_id'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('No account found for mobile number $mobileNumber');
    }
    return result.first['account_id'] as int;
  }

  Future<Map<String, dynamic>> getCurrentMemberRow() async {
    final mobileNumber = await getMobileNumber();
    final db = await dbService.database;
    final result = await db.query(
      'slpa_member',
      columns: ['id', 'account_id', 'first_name', 'middle_name', 'last_name', 'mobile_number'],
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('No member found for mobile number $mobileNumber');
    }
    return result.first;
  }

  Future<Account> getAccountDetails() async {
    final accountId = await getAccountId();
    final db = await dbService.database;

    final result = await db.rawQuery(
      '''
      SELECT a.*, sq.question AS security_question
      FROM   account a
      LEFT JOIN security_questions sq
             ON sq.id = a.security_question_id
      WHERE  a.id = ?
      LIMIT  1
      ''',
      [accountId],
    );

    if (result.isEmpty) {
      throw Exception('Account details not found for account ID $accountId');
    }
    return Account.fromMap(result.first);
  }

  Future<Account> getProfileDetails() async {
    final account = await getAccountDetails();
    final member = await getCurrentMemberRow();

    return account.copyWith(
      firstName: (member['first_name'] ?? '').toString(),
      middleName: (member['middle_name'] ?? '').toString().trim().isEmpty
          ? null
          : (member['middle_name'] ?? '').toString(),
      lastName: (member['last_name'] ?? '').toString(),
      mobileNumber: (member['mobile_number'] ?? '').toString(),
    );
  }

  Future<String> getFullName() async {
    final member = await getCurrentMemberRow();
    return [
      (member['first_name'] ?? '').toString(),
      (member['middle_name'] ?? '').toString(),
      (member['last_name'] ?? '').toString(),
    ].where((part) => part.trim().isNotEmpty).join(' ');
  }

  Future<String> getSlpaName() async {
    final account = await getAccountDetails();
    return account.slpaName;
  }

  Future<Map<String, String>> getNameParts() async {
    final member = await getCurrentMemberRow();
    return {
      'first': (member['first_name'] ?? '').toString(),
      'middle': (member['middle_name'] ?? '').toString(),
      'last': (member['last_name'] ?? '').toString(),
    };
  }

  /// Update account info and save mobile number + full name to SharedPreferences
  Future<void> updateAccount(Account updated) async {
    final db = await dbService.database;
    final previous = await getAccountDetails();
    final now = DateTime.now().toIso8601String();

    // Update account table (toMap() excludes security_question — safe to use)
    await db.update(
      'account',
      {
        ...updated.toMap(),
        'updated_at': now,
        'sync_status': 'pending',
        'last_synced_at': null,
      },
      where: 'id = ?',
      whereArgs: [updated.id],
    );

    // Save current mobile number
    final prefs = await SharedPreferences.getInstance();
    final currentMobile = await getMobileNumber();
    await prefs.setString('mobileNumber', currentMobile ?? updated.mobileNumber);

    // Keep session identity aligned with the current member and updated SLPA.
    await prefs.setString('slpaName', updated.slpaName);

    await AuditLogService.instance.log(
      accountId: updated.id,
      module: 'association_profile',
      tableName: 'account',
      recordId: updated.id?.toString(),
      action: 'update',
      oldValue: {
        'slpa_name': previous.slpaName,
        'profile_image': previous.profileImage,
      },
      newValue: {
        'slpa_name': updated.slpaName,
        'profile_image': updated.profileImage,
      },
    );

    unawaited(AutoSyncService.instance.tryAutoSync(force: true));
  }

  Future<void> updateCurrentMemberProfile(Account updated) async {
    final db = await dbService.database;
    final previous = await getProfileDetails();
    final member = await getCurrentMemberRow();
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        'slpa_member',
        {
          'first_name': updated.firstName.trim(),
          'middle_name': updated.middleName?.trim(),
          'last_name': updated.lastName.trim(),
          'updated_at': now,
          'sync_status': 'pending',
          'last_synced_at': null,
        },
        where: 'id = ?',
        whereArgs: [member['id']],
      );

      await txn.update(
        'account',
        {
          'profile_image': updated.profileImage,
          'updated_at': now,
          'sync_status': 'pending',
          'last_synced_at': null,
        },
        where: 'id = ?',
        whereArgs: [member['account_id']],
      );
    });

    await AuditLogService.instance.log(
      accountId: member['account_id'] as int?,
      module: 'member_profile',
      tableName: 'slpa_member',
      recordId: member['id']?.toString(),
      action: 'update',
      oldValue: {
        'first_name': previous.firstName,
        'middle_name': previous.middleName,
        'last_name': previous.lastName,
        'profile_image': previous.profileImage,
      },
      newValue: {
        'first_name': updated.firstName,
        'middle_name': updated.middleName,
        'last_name': updated.lastName,
        'profile_image': updated.profileImage,
      },
    );

    unawaited(AutoSyncService.instance.tryAutoSync(force: true));
  }
}
