class DashboardSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;

  DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
    );
  }
}
