class CapitalManagementModel {
  int? id;
  double cashOnHand;
  double capital;
  double bankCash;
  String? remarks;
  DateTime createdAt;

  CapitalManagementModel({
    this.id,
    required this.cashOnHand,
    required this.capital,
    required this.bankCash,
    this.remarks,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert model to map for DB insertion
  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = {
      'cash_on_hand': cashOnHand,
      'capital': capital,
      'bank_cash': bankCash,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }

  // Create model from DB map
  factory CapitalManagementModel.fromMap(Map<String, dynamic> map) {
    return CapitalManagementModel(
      id: map['id'] as int?,
      cashOnHand: (map['cash_on_hand'] as num).toDouble(),
      capital: (map['capital'] as num).toDouble(),
      bankCash: (map['bank_cash'] as num).toDouble(),
      remarks: map['remarks'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// ✅ copyWith method to update fields easily
  CapitalManagementModel copyWith({
    int? id,
    int? accountId,
    double? cashOnHand,
    double? capital,
    double? bankCash,
    String? remarks,
    DateTime? createdAt,
  }) {
    return CapitalManagementModel(
      id: id ?? this.id,
      cashOnHand: cashOnHand ?? this.cashOnHand,
      capital: capital ?? this.capital,
      bankCash: bankCash ?? this.bankCash,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
