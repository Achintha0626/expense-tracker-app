class CategoryBreakdownItem {
  final String category;
  final double amount;

  CategoryBreakdownItem({
    required this.category,
    required this.amount,
  });

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItem(
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class MonthlySummaryItem {
  final String month;
  final double income;
  final double expense;

  MonthlySummaryItem({
    required this.month,
    required this.income,
    required this.expense,
  });

  factory MonthlySummaryItem.fromJson(Map<String, dynamic> json) {
    return MonthlySummaryItem(
      month: json['month'] as String,
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
    );
  }
}
