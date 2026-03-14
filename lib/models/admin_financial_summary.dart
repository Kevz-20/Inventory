class AdminFinancialSummary {
  final String organizationId;
  final double totalSales;
  final double outstandingReceivables;
  final double collectedPayments;
  final int salesCount;
  final int unpaidReceivablesCount;

  const AdminFinancialSummary({
    required this.organizationId,
    this.totalSales = 0,
    this.outstandingReceivables = 0,
    this.collectedPayments = 0,
    this.salesCount = 0,
    this.unpaidReceivablesCount = 0,
  });
}
