class UtangCustomer {
  final int id;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? municipality;
  final String? barangay; // 🔥 NEW
  final String? phoneNumber;
  final double totalAmount;
  final String? dueDate; // NEW

  UtangCustomer({
    required this.id,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.municipality,
    this.barangay, // 🔥 NEW
    this.phoneNumber,
    required this.totalAmount,
    this.dueDate,
  });

  String get fullName => [
    firstName,
    middleName,
    lastName,
  ].where((e) => e != null && e.isNotEmpty).join(' ');

  // Compute remaining days
  int get remainingDays {
    if (dueDate == null) return 0;
    final due = DateTime.tryParse(dueDate!);
    if (due == null) return 0;
    return due.difference(DateTime.now()).inDays;
  }

  factory UtangCustomer.fromMap(Map<String, dynamic> map) {
    return UtangCustomer(
      id: map['id'],
      firstName: map['first_name'],
      middleName: map['middle_name'],
      lastName: map['last_name'],
      municipality: map['municipality'],
      barangay: map['barangay'],
      phoneNumber: map['phone_number'],
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      dueDate: map['due_date'], // NEW
    );
  }
}