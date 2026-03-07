class IncomeStatementModel {
  final double merchandiseSales;
  final double sales;

  // dynamic expense categories
  final Map<String, double> expenseCategories;

  final double netIncome;

  IncomeStatementModel({
    required this.merchandiseSales,
    required this.sales,
    required this.expenseCategories,
    required this.netIncome,
  });

  factory IncomeStatementModel.fromMap(Map<String, dynamic> map) {
    final categories = <String, double>{};

    if (map['expense_categories'] != null) {
      final raw = Map<String, dynamic>.from(map['expense_categories']);
      raw.forEach((key, value) {
        categories[key] = (value ?? 0).toDouble();
      });
    }

    return IncomeStatementModel(
      merchandiseSales: (map['merchandise_sales'] ?? 0).toDouble(),
      sales: (map['sales'] ?? 0).toDouble(),
      expenseCategories: categories,
      netIncome: (map['net_income'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchandise_sales': merchandiseSales,
      'sales': sales,
      'expense_categories': expenseCategories,
      'net_income': netIncome,
    };
  }

  double get totalExpenses =>
      expenseCategories.values.fold(0.0, (sum, item) => sum + item);
}