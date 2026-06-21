import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_item.dart';

class RecentTransactionTile extends StatelessWidget {
  final TransactionItem transaction;
  final VoidCallback? onTap;

  const RecentTransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.isExpense;
    final amountColor = isExpense ? Colors.redAccent : Colors.green;
    final subtitle = transaction.subCategory?.isNotEmpty == true
        ? '${transaction.category} • ${transaction.subCategory}'
        : transaction.category;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(31),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                  color: amountColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subtitle • ${DateFormat.yMMMd().format(transaction.transactionDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                NumberFormat.currency(locale: 'en_LK', symbol: 'LKR ').format(transaction.amount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: amountColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
