class TransactionHistory {
  final int? id;
  final int? accountId;
  final String type; // e.g., 'Gasto', 'Halin', 'Withdraw', 'Deposit'
  final int? productId;
  final int? saleId;
  final int? expenseId;
  final int? capitalTransactionId;
  final double? amount;
  final int? quantity;
  final String? description;
  final DateTime createdAt;

  TransactionHistory({
    this.id,
    this.accountId,
    required this.type,
    this.productId,
    this.saleId,
    this.expenseId,
    this.capitalTransactionId,
    this.amount,
    this.quantity,
    this.description,
    required this.createdAt,
  });

  // Convert a Map object from the database into a TransactionHistory
  factory TransactionHistory.fromMap(Map<String, dynamic> map) {
    return TransactionHistory(
      id: map['id'] as int?,
      accountId: map['account_id'] as int?,
      type: map['type'] as String,
      productId: map['product_id'] as int?,
      saleId: map['sale_id'] as int?,
      expenseId: map['expense_id'] as int?,
      capitalTransactionId: map['capital_transaction_id'] as int?,
      amount: map['amount'] != null ? map['amount'] as double : null,
      quantity: map['quantity'] as int?,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convert the TransactionHistory into a Map object for DB operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'type': type,
      'product_id': productId,
      'sale_id': saleId,
      'expense_id': expenseId,
      'capital_transaction_id': capitalTransactionId,
      'amount': amount,
      'quantity': quantity,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
