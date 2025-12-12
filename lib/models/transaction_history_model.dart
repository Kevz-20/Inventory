class TransactionHistoryModel {
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> salesCash;
  final List<Map<String, dynamic>> salesCredit;
  final List<Map<String, dynamic>> capitalManagement;

  TransactionHistoryModel({
    required this.expenses,
    required this.salesCash,
    required this.salesCredit,
    required this.capitalManagement,
  });
}