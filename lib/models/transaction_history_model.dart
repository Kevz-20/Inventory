class TransactionHistoryModel {
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> salesCash;
  final List<Map<String, dynamic>> salesCredit;
  final List<Map<String, dynamic>> capitalManagement;
  final List<Map<String, dynamic>> utangPayments;
  final List<Map<String, dynamic>> ownerPayments;
  final List<Map<String, dynamic>> downPayments;

  TransactionHistoryModel({
    required this.expenses,
    required this.salesCash,
    required this.salesCredit,
    required this.capitalManagement,
    this.utangPayments = const [],
    this.ownerPayments = const [],
    this.downPayments = const [],
  });
}
