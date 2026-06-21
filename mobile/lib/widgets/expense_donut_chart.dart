import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/analytics_models.dart';
import '../core/utils/category_data.dart';

class ExpenseDonutChart extends StatelessWidget {
  final List<CategoryBreakdownItem> items;

  const ExpenseDonutChart({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final expenseItems = items.where((item) => item.amount > 0).toList();
    final total = expenseItems.fold<double>(0, (sum, item) => sum + item.amount);
    if (expenseItems.isEmpty || total <= 0) {
      return Center(
        child: Text(
          'No expenses yet',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final sections = expenseItems
        .take(6)
        .map((item) {
          final percentage = item.amount / total;
          return PieChartSectionData(
            color: getCategoryColor(item.category),
            value: item.amount,
            radius: 54,
            title: '${(percentage * 100).toStringAsFixed(0)}%',
            titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          );
        })
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 60,
                  sectionsSpace: 6,
                  borderData: FlBorderData(show: false),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Expenses',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    NumberFormat.currency(locale: 'en_LK', symbol: 'LKR ').format(total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...expenseItems.take(6).map((item) {
          final percentage = total > 0 ? item.amount / total : 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.category,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  NumberFormat.currency(locale: 'en_LK', symbol: 'LKR ').format(item.amount),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
