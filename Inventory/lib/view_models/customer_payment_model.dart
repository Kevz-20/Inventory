class CustomerPayment {
  final int id;
  final double amount;
  final DateTime paidAt;
  final int? creditDateId;

  CustomerPayment({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.creditDateId,
  });

  factory CustomerPayment.fromMap(Map<String, dynamic> map) {
    return CustomerPayment(
      id: map['id'],
      amount: (map['amount'] ?? 0).toDouble(),
      paidAt: DateTime.tryParse(map['paid_at'] ?? '') ?? DateTime.now(),
      creditDateId: map['credit_date_id'],
    );
  }
}
