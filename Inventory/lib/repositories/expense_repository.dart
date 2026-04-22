import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../models/current_user.dart';
import '../models/expense_model.dart';
import '../providers/database_provider.dart';
import '../services/audit_log_service.dart';


// -----------------------------
// Provider
// -----------------------------
final expenseRepositoryProvider = FutureProvider<ExpenseRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return ExpenseRepository(db);
});

// -----------------------------
// Repository
// -----------------------------
class ExpenseRepository {
  final Database db;

  ExpenseRepository(this.db);

  /// Add a new expense
  Future<int> addExpense(ExpenseModel expense) async {
  final data = expense.toMap();

  data['created_by_first_name'] = CurrentUser.firstName;
  data['created_by_middle_name'] = CurrentUser.middleName ?? '';
  data['created_by_last_name'] = CurrentUser.lastName;
  data['created_by_member_id'] = CurrentUser.memberId;

  // created_at: if empty, use current datetime
  data['created_at'] = expense.createdAt.isNotEmpty
      ? expense.createdAt
      : DateTime.now().toIso8601String();
  data['updated_at'] = DateTime.now().toIso8601String();
  data['sync_status'] = 'pending';
  data['last_synced_at'] = null;
  data['is_deleted'] = 0;

  final expenseId = await db.insert(
    'expenses',
    data,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  await AuditLogService.instance.log(
    module: 'expense',
    tableName: 'expenses',
    recordId: expenseId.toString(),
    action: 'create',
    newValue: data,
  );
  return expenseId;
}


  /// Fetch all expenses
  Future<List<ExpenseModel>> fetchAllExpenses() async {
    final result = await db.query(
      'expenses',
      orderBy: 'created_at DESC',
    );
    return result.map((e) => ExpenseModel.fromMap(e)).toList();
  }

  /// Fetch a single expense by ID
  Future<ExpenseModel?> fetchExpense(int id) async {
    final result = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ExpenseModel.fromMap(result.first);
  }

  /// Update an expense
  Future<int> updateExpense(ExpenseModel expense) async {
  final previous = expense.id == null ? null : await fetchExpense(expense.id!);
  final data = expense.toMap();

  // Keep the original creator
  data['created_by_first_name'] = expense.createdByFirstName;
  data['created_by_middle_name'] = expense.createdByMiddleName ?? '';
  data['created_by_last_name'] = expense.createdByLastName;
  data['updated_at'] = DateTime.now().toIso8601String();
  data['sync_status'] = 'pending';
  data['last_synced_at'] = null;

  final updated = await db.update(
    'expenses',
    data,
    where: 'id = ?',
    whereArgs: [expense.id],
  );
  if (updated > 0) {
    await AuditLogService.instance.log(
      module: 'expense',
      tableName: 'expenses',
      recordId: expense.id?.toString(),
      action: 'update',
      oldValue: previous?.toMap(),
      newValue: data,
    );
  }
  return updated;
}

  /// Delete an expense
  Future<int> deleteExpense(int id) async {
    final previous = await fetchExpense(id);
    final deleted = await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deleted > 0) {
      await AuditLogService.instance.log(
        module: 'expense',
        tableName: 'expenses',
        recordId: id.toString(),
        action: 'delete',
        oldValue: previous?.toMap(),
      );
    }
    return deleted;
  }

  /// Fetch total expenses
  Future<double> fetchTotalExpenses() async {
    final result = await db.rawQuery('SELECT IFNULL(SUM(amount), 0) AS total FROM expenses');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
