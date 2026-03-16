class CashflowPoint {
  final DateTime day;      // date (YYYY-MM-DD)
  final double net;        // sales - expenses

  CashflowPoint({required this.day, required this.net});
}