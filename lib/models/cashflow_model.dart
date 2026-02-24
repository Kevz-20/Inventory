import 'package:intl/intl.dart';

class CashflowRecord {
  final int? id;
  final DateTime date;
  final String item;
  final double cashIn;
  final double cashOut;
  final double balance;

  // ✅ NEW FIELD
  final String? recordedBy;

  CashflowRecord({
    this.id,
    required this.date,
    required this.item,
    required this.cashIn,
    required this.cashOut,
    required this.balance,
    this.recordedBy, // ✅ NEW
  });

  String get formattedDate => DateFormat('MMM dd').format(date);
  String get formattedTime => DateFormat('h:mm a').format(date);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'item': item,
      'cash_in': cashIn,
      'cash_out': cashOut,
      'balance': balance,

      // optional (only if you store it)
      'recorded_by': recordedBy,
    };
  }

  factory CashflowRecord.fromMap(Map<String, dynamic> map) {
    // ✅ SAME STYLE AS YOUR TransactionHistory
    final createdByFirst =
        (map['created_by_first_name'] ?? map['first_name'] ?? '').toString();
    final createdByMiddle =
        (map['created_by_middle_name'] ?? map['middle_name'] ?? '').toString();
    final createdByLast =
        (map['created_by_last_name'] ?? map['last_name'] ?? '').toString();

    final builtRecordedBy = [
      createdByFirst,
      createdByMiddle,
      createdByLast,
    ].where((s) => s.trim().isNotEmpty).join(' ').trim();

    return CashflowRecord(
      id: map['id'],
      date: DateTime.parse(map['date']),
      item: map['item'],
      cashIn: (map['cash_in'] as num?)?.toDouble() ?? 0.0,
      cashOut: (map['cash_out'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,

      // ✅ NEW
      recordedBy: builtRecordedBy.isNotEmpty
          ? builtRecordedBy
          : (map['recorded_by']?.toString().trim().isNotEmpty == true
              ? map['recorded_by'].toString().trim()
              : null),
    );
  }
}