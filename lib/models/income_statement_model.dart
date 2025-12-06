class IncomeStatementModel {
  final double sales;
  final double merchandiseSales;
  final double kumpra;
  final double transportation;
  final double totalExpenses;
  final double netIncome;

  IncomeStatementModel({
    required this.sales,
    required this.merchandiseSales,
    required this.kumpra,
    required this.transportation,
    required this.totalExpenses,
    required this.netIncome,
  });

  factory IncomeStatementModel.fromMap(Map<String, double> data) {
    return IncomeStatementModel(
      sales: data["sales"] ?? 0,
      merchandiseSales: data["merchandise_sales"] ?? 0,
      kumpra: data["kumpra"] ?? 0,
      transportation: data["transportation"] ?? 0,
      totalExpenses: data["total_expenses"] ?? 0,
      netIncome: data["net_income"] ?? 0,
    );
  }
}
