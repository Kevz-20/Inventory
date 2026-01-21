enum CashflowType { income, expense }

class CashflowRecord {
  final int? id;
  final String description;
  final double amount;
  final CashflowType type;
  final DateTime date;

  CashflowRecord({
    this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'amount': amount,
    'type': type.index,
    'date': date.toIso8601String(),
  };

  factory CashflowRecord.fromMap(Map<String, dynamic> map) => CashflowRecord(
    id: map['id'],
    description: map['description'],
    amount: map['amount'],
    type: CashflowType.values[map['type']],
    date: DateTime.parse(map['date']),
  );
}
