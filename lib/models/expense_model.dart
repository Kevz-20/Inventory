class ExpenseModel {
  final int? id;
  final double amount;
  final String category;
  final String description;
  final String? receipt;
  final String createdAt;

  final String createdByFirstName;
  final String? createdByMiddleName;
  final String createdByLastName;

  ExpenseModel({
    this.id,
    required this.amount,
    required this.category,
    required this.description,
    this.receipt,
    required this.createdAt,
    required this.createdByFirstName,
    this.createdByMiddleName,
    required this.createdByLastName,
  });

  /// Convert ExpenseModel to Map for DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'receipt': receipt,
      'created_at': createdAt,
      'created_by_first_name': createdByFirstName,
      'created_by_middle_name': createdByMiddleName ?? '',
      'created_by_last_name': createdByLastName,
    };
  }

  /// Create ExpenseModel from DB Map
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      amount: map['amount'] is int
          ? (map['amount'] as int).toDouble()
          : map['amount'] as double,
      category: map['category'] as String,
      description: map['description'] as String,
      receipt: map['receipt'] as String?,
      createdAt: map['created_at'] as String,
      createdByFirstName: map['created_by_first_name'] as String? ?? '',
      createdByMiddleName: map['created_by_middle_name'] as String?,
      createdByLastName: map['created_by_last_name'] as String? ?? '',
    );
  }
}
