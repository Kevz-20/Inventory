class HistoryModel {
  final String title;
  final double amount;
  final String category;
  final String method;
  final DateTime date;

  HistoryModel({
    required this.title,
    required this.amount,
    required this.category,
    required this.method,
    required this.date,
  });

  bool get isExpense => amount < 0;
}
