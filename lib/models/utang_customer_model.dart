class UtangCustomer {
  final int id;
  final String fullName;
  final String? phoneNumber;
  final String? barangay;
  final DateTime? dueDate;
  int remainingDays;
  double balance; // <-- mutable now

  UtangCustomer({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.barangay,
    this.dueDate,
    this.remainingDays = 0,
    required this.balance,
  });

  factory UtangCustomer.fromMap(Map<String, dynamic> map) {
    final totalAmount = (map['total_amount'] as num?)?.toDouble() ?? 0.0;
    final totalPaid = (map['total_paid'] as num?)?.toDouble() ?? 0.0;
    final remainingBalance = totalAmount - totalPaid;

    return UtangCustomer(
      id: map['customer_id'] as int,
      fullName: map['full_name'] ?? '',
      phoneNumber: map['phone_number'],
      barangay: map['barangay'],
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'])
          : null,
      remainingDays: map['remaining_days'] ?? 0,
      balance: remainingBalance > 0 ? remainingBalance : 0,
    );
  }
}
