import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/analytics_models.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<MonthlySummaryItem> data;

  const MonthlyBarChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No summary available for this period.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final highestValue = data
        .map((item) => [item.income, item.expense].reduce((a, b) => a > b ? a : b))
        .fold<double>(0, (prev, next) => next > prev ? next : prev);
    final interval = 5000.0;
    final yMax = highestValue <= interval ? interval : ((highestValue / interval).ceil() * interval);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 18,
              maxY: yMax > 0 ? yMax : interval,
              minY: 0,
              barGroups: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: item.income,
                      color: Colors.greenAccent.shade700,
                      width: 12,
                    ),
                    BarChartRodData(
                      toY: item.expense,
                      color: Colors.redAccent.shade200,
                      width: 12,
                    ),
                  ],
                  barsSpace: 6,
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > yMax) return const SizedBox.shrink();
                      if ((value % interval).abs() > 0.1) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          NumberFormat.compact(locale: 'en_US').format(value),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final month = data[index].month;
                      final date = DateTime.tryParse('$month-01');
                      final label = date != null ? DateFormat.MMM().format(date) : month;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: interval,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLegend(color: Colors.greenAccent.shade700, label: 'Income'),
            const SizedBox(width: 16),
            _buildLegend(color: Colors.redAccent.shade200, label: 'Expense'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend({required Color color, required String label}) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
