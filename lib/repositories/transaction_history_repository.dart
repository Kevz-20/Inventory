import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense_model.dart';
import '../models/transaction_history_model.dart';
import 'account_repository.dart';
import 'expense_repository.dart'; // import your expense repo provider

class TransactionHistoryRepository {
  final Database database;
  final AccountRepository accountRepo;
  final ExpenseRepository expenseRepo;

  TransactionHistoryRepository({
    required this.database,
    required this.accountRepo,
    required this.expenseRepo,
  });

  // Insert a new transaction (auto fetch account_id)
  Future<int> insertTransaction(TransactionHistory transaction) async {
    final accountId = await accountRepo.getAccountId();
    final transactionWithAccount = TransactionHistory(
      id: transaction.id,
      accountId: accountId,
      type: transaction.type,
      productId: transaction.productId,
      saleId: transaction.saleId,
      expenseId: transaction.expenseId,
      capitalTransactionId: transaction.capitalTransactionId,
      amount: transaction.amount,
      quantity: transaction.quantity,
      description: transaction.description,
      createdAt: transaction.createdAt,
    );

    debugPrint(
      "debug - Inserting transaction: ${transactionWithAccount.toMap()}",
    );

    return await database.insert(
      'transaction_history',
      transactionWithAccount.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all transactions
  Future<List<TransactionHistory>> getAllTransactions() async {
    final accountId = await accountRepo.getAccountId();

    final List<Map<String, dynamic>> maps = await database.query(
      'transaction_history',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'created_at DESC',
    );

    debugPrint(
      'debug - Retrieved ${maps.length} transactions from transaction_history',
    );

    return List.generate(
      maps.length,
      (i) => TransactionHistory.fromMap(maps[i]),
    );
  }

  // Fetch expenses as transactions
  Future<List<ExpenseModel>> fetchExpensesAsTransactions({
    String? category,
  }) async {
    try {
      final allExpenses = await expenseRepo.fetchExpensesForCurrentAccount();

      debugPrint(
        "debug - Fetched ${allExpenses.length} expenses from expenses table",
      );

      final filteredExpenses = category != null && category != 'All'
          ? allExpenses.where((e) => e.category == category).toList()
          : allExpenses;

      debugPrint(
        "debug - Filtered ${filteredExpenses.length} expenses by category: $category",
      );

      return filteredExpenses;
    } catch (e) {
      debugPrint("debug - Failed to fetch expenses: $e");
      return [];
    }
  }

  // Get transactions filtered by date range and/or category
  Future<List<TransactionHistory>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final accountId = await accountRepo.getAccountId();
    debugPrint('debug - Account ID: $accountId');

    String whereClause = 'account_id = ?';
    List<dynamic> whereArgs = [accountId];

    if (startDate != null && endDate != null) {
      whereClause += ' AND created_at BETWEEN ? AND ?';
      whereArgs.addAll([
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ]);
      debugPrint(
        'debug - Filtering by date: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );
    }

    if (category != null && category != 'All') {
      whereClause += ' AND type = ?';
      whereArgs.add(category);
      debugPrint('debug - Filtering by category: $category');
    }

    debugPrint(
      'debug - Querying transaction_history with whereClause: $whereClause, whereArgs: $whereArgs',
    );

    final List<Map<String, dynamic>> maps = await database.query(
      'transaction_history',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    debugPrint('debug - Retrieved ${maps.length} transactions');

    return List.generate(
      maps.length,
      (i) => TransactionHistory.fromMap(maps[i]),
    );
  }

  // Delete a transaction
  Future<int> deleteTransaction(int id) async {
    final accountId = await accountRepo.getAccountId();

    return await database.delete(
      'transaction_history',
      where: 'id = ? AND account_id = ?',
      whereArgs: [id, accountId],
    );
  }

  // Update a transaction
  Future<int> updateTransaction(TransactionHistory transaction) async {
    final accountId = await accountRepo.getAccountId();
    final transactionWithAccount = TransactionHistory(
      id: transaction.id,
      accountId: accountId,
      type: transaction.type,
      productId: transaction.productId,
      saleId: transaction.saleId,
      expenseId: transaction.expenseId,
      capitalTransactionId: transaction.capitalTransactionId,
      amount: transaction.amount,
      quantity: transaction.quantity,
      description: transaction.description,
      createdAt: transaction.createdAt,
    );

    debugPrint(
      "debug - Updating transaction: ${transactionWithAccount.toMap()}",
    );

    return await database.update(
      'transaction_history',
      transactionWithAccount.toMap(),
      where: 'id = ? AND account_id = ?',
      whereArgs: [transaction.id, accountId],
    );
  }
}
