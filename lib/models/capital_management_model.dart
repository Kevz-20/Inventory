class CapitalManagementModel {
  int? id;
  int accountId;
  double cashOnHand;
  double capital;
  double bankCash;
  String? remarks;

  CapitalManagementModel({
    this.id,
    required this.accountId,
    required this.cashOnHand,
    required this.capital,
    required this.bankCash,
    this.remarks,
  });

  // Convert model to map for DB
  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = {
      'account_id': accountId,
      'cash_on_hand': cashOnHand,
      'capital': capital,
      'bank_cash': bankCash,
      'remarks': remarks,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }

  // Create model from DB map
  factory CapitalManagementModel.fromMap(Map<String, dynamic> map) {
    return CapitalManagementModel(
      id: map['id'],
      accountId: map['account_id'],
      cashOnHand: map['cash_on_hand'],
      capital: map['capital'],
      bankCash: map['bank_cash'],
      remarks: map['remarks'],
    );
  }
}
