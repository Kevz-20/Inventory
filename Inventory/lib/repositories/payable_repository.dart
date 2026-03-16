import '../models/payable_model.dart';
import '../services/db_service.dart';
import '../services/audit_log_service.dart';
import 'package:sqflite/sqflite.dart';

class PayableRepository {
  /// Fetch all payables (global, all accounts can see)
  Future<List<Payable>> getAllPayables() async {
    final db = await DBService.instance.database;

    final result = await db.query(
      'payable',
      orderBy: 'due_date ASC',
    );

    return result.map((e) => Payable.fromMap(e)).toList();
  }

  /// Fetch a single payable by ID
  Future<Payable?> getPayableById(int id) async {
    final db = await DBService.instance.database;

    final result = await db.query(
      'payable',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) return Payable.fromMap(result.first);
    return null;
  }

  /// Add a new payable
  Future<int> addPayable(Payable payable) async {
    final db = await DBService.instance.database;
    final map = payable.toMap();
    map['updated_at'] ??= map['created_at'] ?? DateTime.now().toIso8601String();
    map['sync_status'] = 'pending';
    map['last_synced_at'] = null;
    map['is_deleted'] = 0;

    // Fill creator info if null
    if (payable.createdByFirstName == null ||
        payable.createdByMiddleName == null ||
        payable.createdByLastName == null) {
      final currentUserQuery = await db.query(
        'account',
        where: 'is_logged_in = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (currentUserQuery.isNotEmpty) {
        final user = currentUserQuery.first;
        map['created_by_first_name'] ??= user['first_name'];
        map['created_by_middle_name'] ??= user['middle_name'];
        map['created_by_last_name'] ??= user['last_name'];
      }
    }

    final payableId = await db.insert(
      'payable',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await AuditLogService.instance.log(
      module: 'payable',
      tableName: 'payable',
      recordId: payableId.toString(),
      action: 'create',
      newValue: map,
    );
    return payableId;
  }

  /// Update an existing payable
  Future<int> updatePayable(Payable payable) async {
    final db = await DBService.instance.database;
    final previous = await getPayableById(payable.id);
    final map = payable.toMap();

    // ✅ Get current logged-in user from DB if creator info is null
    final currentUserQuery = await db.query(
      'account',
      where: 'is_logged_in = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (currentUserQuery.isNotEmpty) {
      final user = currentUserQuery.first;
      map['created_by_first_name'] ??= user['first_name'];
      map['created_by_middle_name'] ??= user['middle_name'];
      map['created_by_last_name'] ??= user['last_name'];
    }
    map['updated_at'] = DateTime.now().toIso8601String();
    map['sync_status'] = 'pending';
    map['last_synced_at'] = null;

    final updated = await db.update(
      'payable',
      map,
      where: 'id = ?',
      whereArgs: [payable.id],
    );
    if (updated > 0) {
      await AuditLogService.instance.log(
        module: 'payable',
        tableName: 'payable',
        recordId: payable.id.toString(),
        action: 'update',
        oldValue: previous?.toMap(),
        newValue: map,
      );
    }
    return updated;
  }

  /// Delete a payable
  Future<int> deletePayable(int id) async {
    final db = await DBService.instance.database;
    final previous = await getPayableById(id);
    final deleted = await db.delete(
      'payable',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deleted > 0) {
      await AuditLogService.instance.log(
        module: 'payable',
        tableName: 'payable',
        recordId: id.toString(),
        action: 'delete',
        oldValue: previous?.toMap(),
      );
    }
    return deleted;
  }

  /// Get total unpaid payables (optional helper for reports)
  Future<double> getTotalUnpaid() async {
    final db = await DBService.instance.database;
    final result = await db.rawQuery(
      'SELECT IFNULL(SUM(remaining_amount), 0) AS total FROM payable WHERE is_paid IS NULL OR is_paid = 0',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
