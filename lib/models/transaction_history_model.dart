class TransactionHistoryModel {
  final int? id;
  final int accountId;
  final String type;
  final int? productId;
  final int? saleId;
  final int? expenseId;
  final int? capitalTransactionId;
  final double? amount;
  final int? quantity;
  final String? description;
  final DateTime createdAt;

  TransactionHistoryModel({
    this.id,
    required this.accountId,
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

  factory TransactionHistoryModel.fromMap(Map<String, dynamic> map) {
    return TransactionHistoryModel(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      type: map['type'] as String,
      productId: map['product_id'] as int?,
      saleId: map['sale_id'] as int?,
      expenseId: map['expense_id'] as int?,
      capitalTransactionId: map['capital_transaction_id'] as int?,
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : null,
      quantity: map['quantity'] as int?,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] ?? map['date']),
    );
  }

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
