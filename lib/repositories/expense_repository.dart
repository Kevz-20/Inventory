import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../providers/account_repository_provider.dart';
import '../repositories/account_repository.dart';
import '../providers/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final expenseRepositoryProvider = FutureProvider<ExpenseRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  final accountRepo = await ref.watch(accountRepositoryProvider.future);
  return ExpenseRepository(db, accountRepo);
});

class ExpenseRepository {
  final Database db;
  final AccountRepository accountRepository;

  ExpenseRepository(this.db, this.accountRepository);

  Future<int> addExpense(ExpenseModel expense) async {
    return await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseModel>> fetchExpensesForCurrentAccount() async {
    final accountId = await accountRepository.getAccountId();

    final result = await db.query(
      'expenses',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'created_at DESC',
    );

    return result.map((e) => ExpenseModel.fromMap(e)).toList();
  }


  Future<List<ExpenseModel>> fetchExpensesByAccount(int accountId) async {
    final result = await db.query(
      'expenses',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'created_at DESC',
    );

    return result.map((e) => ExpenseModel.fromMap(e)).toList();
  }

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

  Future<int> updateExpense(ExpenseModel expense) async {
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
