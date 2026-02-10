class Payable {
  final int id;
  final String name; // supplier / owner
  final String item;
  final double amount;
  
  // -------------------------
  // Optional installment info
  // -------------------------
  final double? remainingAmount;
  final double? planMonthly;
  final int? planMonths;

  final String? dueDate;
  final String? nextDueDate;

  final bool isInstallment;
  final bool isPaid;
  final String? createdAt; // optional

  // -------------------------
  // Installment progress
  // -------------------------
  final int? totalInstallments;
  final int? paidInstallments;

  // -------------------------
  // Creator info for multi-user DB
  // -------------------------
  final String? createdByFirstName;
  final String? createdByMiddleName;
  final String? createdByLastName;

  Payable({
    required this.id,
    required this.name,
    required this.item,
    required this.amount,
    this.remainingAmount,
    this.planMonthly,
    this.planMonths,
    this.dueDate,
    this.nextDueDate,
    this.isInstallment = false,
    this.isPaid = false,
    this.createdAt,
    this.totalInstallments,
    this.paidInstallments,
    this.createdByFirstName,
    this.createdByMiddleName,
    this.createdByLastName,
  });

  // -------------------------
  // Computed properties
  // -------------------------
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

  DateTime? get createdAtDate =>
      createdAt != null ? DateTime.tryParse(createdAt!) : null;

  String get installmentProgress {
    if (!isInstallment || totalInstallments == null || paidInstallments == null) {
      return "";
    }
    return "$paidInstallments/$totalInstallments";
  }

  // -------------------------
  // Factory from DB
  // -------------------------
  factory Payable.fromMap(Map<String, dynamic> map) {
    return Payable(
      id: map['id'] as int,
      name: map['supplier_name'] ?? 'Unknown',
      item: map['item'] ?? 'No item',
      amount: (map['original_amount'] ?? 0).toDouble(),

      remainingAmount: (map['remaining_amount'] as num?)?.toDouble(),
      planMonthly: (map['plan_monthly'] as num?)?.toDouble(),
      planMonths: map['plan_months'] as int?,

      dueDate: map['due_date'] as String?,
      nextDueDate: map['next_due_date'] as String?,

      isInstallment: (map['has_plan'] ?? 0) == 1,
      isPaid: (map['is_paid'] ?? 0) == 1,
      createdAt: map['created_at'] as String?,

      totalInstallments: map['total_installments'] as int?,
      paidInstallments: map['paid_installments'] as int?,

      createdByFirstName: map['created_by_first_name'] as String?,
      createdByMiddleName: map['created_by_middle_name'] as String?,
      createdByLastName: map['created_by_last_name'] as String?,
    );
  }

  // -------------------------
  // Convert to DB map
  // -------------------------
  Map<String, dynamic> toMap() {
    return {
      'supplier_name': name,
      'item': item,
      'original_amount': amount,
      'remaining_amount': remainingAmount,
      'plan_monthly': planMonthly,
      'plan_months': planMonths,
      'due_date': dueDate,
      'next_due_date': nextDueDate,
      'has_plan': isInstallment ? 1 : 0,
      'is_paid': isPaid ? 1 : 0,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),

      // Creator info
      'created_by_first_name': createdByFirstName,
      'created_by_middle_name': createdByMiddleName,
      'created_by_last_name': createdByLastName,

      'total_installments': totalInstallments,
      'paid_installments': paidInstallments,
    };
  }
}
