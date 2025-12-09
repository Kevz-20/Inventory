class ExpenseModel {
  final int? id;
  final int accountId;
  final double amount;
  final String category;
  final String description;
  final String? receipt;
  final String createdAt;

  ExpenseModel({
    this.id,
    required this.accountId,
    required this.amount,
    required this.category,
    required this.description,
    this.receipt,
    required this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      receipt: map['receipt'],
      createdAt: map['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'amount': amount,
      'category': category,
      'description': description,
      'receipt': receipt,
      'created_at': createdAt,
    };
  }
}
