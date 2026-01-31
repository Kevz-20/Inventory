class Payable {
  final int id;
  final String name; // supplier / owner
  final String item;
  final double amount;

  final String? dueDate;
  final String? nextDueDate;

  final bool isInstallment;
  final bool isPaid;
  final String? createdAt; // ✅ updated from createAt

  // -------------------------
  // NEW FIELDS FOR INSTALLMENT PROGRESS
  // -------------------------
  final int? totalInstallments;
  final int? paidInstallments;

  Payable({
    required this.id,
    required this.name,
    required this.item,
    required this.amount,
    this.dueDate,
    this.nextDueDate,
    this.isInstallment = false,
    this.isPaid = false,
    this.createdAt,
    this.totalInstallments,   // ✅ new
    this.paidInstallments,    // ✅ new
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

  // ✅ optional getter for easy DateTime conversion
  DateTime? get createdAtDate =>
      createdAt != null ? DateTime.tryParse(createdAt!) : null;

  // -------------------------
  // NEW GETTER: installment progress
  // -------------------------
  String get installmentProgress {
    if (!isInstallment || totalInstallments == null || paidInstallments == null) {
      return "";
    }
    return "$paidInstallments/$totalInstallments";
  }

  factory Payable.fromMap(Map<String, dynamic> map) {
    return Payable(
      id: map['id'] as int,
      name: map['supplier_name'] ?? 'Unknown',
      item: map['item'] ?? 'No item',
      amount: (map['original_amount'] ?? 0).toDouble(),

      dueDate: map['due_date'] as String?,
      nextDueDate: map['next_due_date'] as String?,

      isInstallment: (map['has_plan'] ?? 0) == 1,
      isPaid: (map['is_paid'] ?? 0) == 1,
      createdAt: map['created_at'] as String?,

      // -------------------------
      // MAP NEW FIELDS FROM DB
      // -------------------------
      totalInstallments: map['total_installments'] as int?,
      paidInstallments: map['paid_installments'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supplier_name': name,
      'item': item,
      'original_amount': amount,
      'due_date': dueDate,
      'next_due_date': nextDueDate,
      'has_plan': isInstallment ? 1 : 0,
      'is_paid': isPaid ? 1 : 0,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),

      // -------------------------
      // NEW FIELDS TO MAP
      // -------------------------
      'total_installments': totalInstallments,
      'paid_installments': paidInstallments,
    };
  }
}
