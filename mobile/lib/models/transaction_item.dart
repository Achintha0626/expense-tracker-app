class TransactionItem {
  final int id;
  final int userId;
  final String title;
  final double amount;
  final String transactionType;
  final String category;
  final String? description;
  final DateTime transactionDate;
  final DateTime createdAt;

  TransactionItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.transactionType,
    required this.category,
    required this.description,
    required this.transactionDate,
    required this.createdAt,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionType: json['transaction_type'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isExpense => transactionType.toLowerCase() == 'expense';
  bool get isIncome => transactionType.toLowerCase() == 'income';
}
