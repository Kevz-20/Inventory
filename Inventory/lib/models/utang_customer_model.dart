class UtangCustomer {
  final int id;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? phoneNumber;
  final String? municipality;
  final String? barangay;
  final DateTime? dueDate; // keep DateTime for easier calculations
  int remainingDays; // mutable
  double balance; // mutable, for remaining balance
  final double totalAmount;

  UtangCustomer({
    required this.id,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.phoneNumber,
    this.municipality,
    this.barangay,
    this.dueDate,
    this.remainingDays = 0,
    required this.balance,
    required this.totalAmount,
  });

  /// Convenience getter for full name
  String get fullName => [
    firstName,
    middleName,
    lastName,
  ].where((e) => e != null && e.isNotEmpty).join(' ');

  /// Convenience getter for remaining days until due
  int get computedRemainingDays {
    if (dueDate == null) return 0;
    final dueDateOnly = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return dueDateOnly.difference(todayOnly).inDays;
  }

  /// Factory constructor to create a UtangCustomer from a map (DB row)
  factory UtangCustomer.fromMap(Map<String, dynamic> map) {
    // Handle total amount and payments
    final totalAmount = (map['total_amount'] as num?)?.toDouble() ?? 0.0;
    final totalPaid = (map['total_paid'] as num?)?.toDouble() ?? 0.0;
    final remainingBalance = totalAmount - totalPaid;

    // Parse due date from either String or DateTime
    DateTime? parsedDueDate;
    if (map['due_date'] != null) {
      if (map['due_date'] is String) {
        parsedDueDate = DateTime.tryParse(map['due_date']);
      } else if (map['due_date'] is DateTime) {
        parsedDueDate = map['due_date'];
      }
    }

    return UtangCustomer(
      id: map['customer_id'] ?? map['id'] ?? 0,
      firstName: map['first_name'] ?? '',
      middleName: map['middle_name'],
      lastName: map['last_name'],
      phoneNumber: map['phone_number'],
      municipality: map['municipality'],
      barangay: map['barangay'],
      dueDate: parsedDueDate,
      remainingDays: parsedDueDate != null
          ? DateTime(parsedDueDate.year, parsedDueDate.month, parsedDueDate.day)
                .difference(
                  DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                )
                .inDays
          : 0,
      balance: remainingBalance > 0 ? remainingBalance : 0,
      totalAmount: totalAmount,
    );
  }
}
