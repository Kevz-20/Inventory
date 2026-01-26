class Payable {
  final int id;
  final String name; // supplier / owner
  final String item; // ✅ NEW
  final double amount;
  final String? dueDate;
  final bool isInstallment;
  final bool isPaid;

  Payable({
    required this.id,
    required this.name,
    required this.item,
    required this.amount,
    this.dueDate,
    this.isInstallment = false,
    this.isPaid = false,
  });

  int get remainingDays {
    if (dueDate == null) return 0;
    final due = DateTime.tryParse(dueDate!);
    if (due == null) return 0;
    return due.difference(DateTime.now()).inDays;
  }

  String get status {
    if (isPaid) return "Paid";
    if (remainingDays <= 0) return "Overdue";
    return "Due Soon";
  }

  factory Payable.fromMap(Map<String, dynamic> map) {
    return Payable(
      id: map['id'],
      name: map['supplier_name'] ?? 'Unknown',
      item: map['item'] ?? 'No item', // ✅ MAP ITEM
      amount: (map['original_amount'] ?? 0).toDouble(),
      dueDate: map['due_date'],
      isInstallment: (map['has_plan'] ?? 0) == 1,
      isPaid: (map['is_paid'] ?? 0) == 1,
    );
  }
}