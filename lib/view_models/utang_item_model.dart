class UtangItem {
  final int salesCreditId;
  final String itemName;
  final double amount;
  final int quantity;
  final DateTime creditDate;
  final DateTime? dueDate;

  UtangItem({
    required this.salesCreditId,
    required this.itemName,
    required this.amount,
    required this.quantity,
    required this.creditDate,
    this.dueDate,
  });

  factory UtangItem.fromMap(Map<String, dynamic> map) {
    return UtangItem(
      salesCreditId: map['sales_credit_id'],
      itemName: map['item_name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      creditDate: DateTime.tryParse(map['credit_date'] ?? '') ?? DateTime.now(),
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'])
          : null,
    );
  }
}