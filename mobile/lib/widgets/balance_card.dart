import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final String title;
  final String balance;
  final String income;
  final String expense;

  const BalanceCard({
    super.key,
    required this.title,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [colors.primary, colors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            balance,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat(
                label: 'Income',
                value: income,
                color: Colors.greenAccent.shade100,
                textColor: colors.onPrimary,
              ),
              const SizedBox(width: 12),
              _buildMiniStat(
                label: 'Expense',
                value: expense,
                color: Colors.redAccent.shade100,
                textColor: colors.onPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(46),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor.withAlpha(217),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
