import 'package:intl/intl.dart';

class CashflowRecord {
  final int? id;
  final DateTime date;
  final String item;
  final double cashIn;
  final double cashOut;

  CashflowRecord({
    this.id,
    required this.date,
    required this.item,
    required this.cashIn,
    required this.cashOut,
  });

  String get formattedDate => DateFormat('yyyy-MM-dd').format(date);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'item': item,
      'cash_in': cashIn,
      'cash_out': cashOut,
    };
  }

  factory CashflowRecord.fromMap(Map<String, dynamic> map) {
    return CashflowRecord(
      id: map['id'],
      date: DateTime.parse(map['date']),
      item: map['item'],
      cashIn: map['cash_in'],
      cashOut: map['cash_out'],
    );
  }
}
