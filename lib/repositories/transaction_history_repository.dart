import 'package:sqflite/sqflite.dart';
import '../models/transaction_history_model.dart';
import 'account_repository.dart'; // make sure to import your account repo

class TransactionHistoryRepository {
  final Database database;
  final AccountRepository accountRepo;

  TransactionHistoryRepository({
    required this.database,
    required this.accountRepo,
  });

  // Insert a new transaction (auto fetch account_id)
  Future<int> insertTransaction(TransactionHistory transaction) async {
    // Get the current account ID
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

    return List.generate(
      maps.length,
      (i) => TransactionHistory.fromMap(maps[i]),
    );
  }

  // Get transactions filtered by date range and/or category
  Future<List<TransactionHistory>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final accountId = await accountRepo.getAccountId();

    String whereClause = 'account_id = ?';
    List<dynamic> whereArgs = [accountId];

    if (startDate != null && endDate != null) {
      whereClause += ' AND created_at BETWEEN ? AND ?';
      whereArgs.addAll([
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ]);
    }

    if (category != null && category != 'All') {
      whereClause += ' AND type = ?';
      whereArgs.add(category);
    }

    final List<Map<String, dynamic>> maps = await database.query(
      'transaction_history',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

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

    return await database.update(
      'transaction_history',
      transactionWithAccount.toMap(),
      where: 'id = ? AND account_id = ?',
      whereArgs: [transaction.id, accountId],
    );
  }
}
