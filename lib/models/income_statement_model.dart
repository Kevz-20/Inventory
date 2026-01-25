class IncomeStatementModel {
  final double merchandiseSales;
  final double sales;
  final double kompra; // <- must exist
  final double electricity; // <- must exist
  final double transportation;
  final double rentPayment;
  final double miscExpenses;
  final double netIncome;

  IncomeStatementModel({
    required this.merchandiseSales,
    required this.sales,
    required this.kompra,
    required this.electricity,
    required this.transportation,
    required this.rentPayment,
    required this.miscExpenses,
    required this.netIncome,
  });

  factory IncomeStatementModel.fromMap(Map<String, dynamic> map) {
    return IncomeStatementModel(
      merchandiseSales: (map['merchandise_sales'] ?? 0).toDouble(),
      sales: (map['sales'] ?? 0).toDouble(),
      kompra: (map['kompra'] ?? 0).toDouble(),
      electricity: (map['electricity'] ?? 0).toDouble(),
      transportation: (map['transportation'] ?? 0).toDouble(),
      rentPayment: (map['rent_payment'] ?? 0).toDouble(),
      miscExpenses: (map['misc_expenses'] ?? 0).toDouble(),
      netIncome: (map['net_income'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchandise_sales': merchandiseSales,
      'sales': sales,
      'kompra': kompra,
      'electricity': electricity,
      'transportation': transportation,
      'rent_payment': rentPayment,
      'misc_expenses': miscExpenses,
      'net_income': netIncome,
    };
  }
}
