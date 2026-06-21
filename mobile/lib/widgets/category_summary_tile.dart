import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/utils/category_data.dart';
import '../models/analytics_models.dart';

class CategorySummaryTile extends StatelessWidget {
  final CategoryBreakdownItem item;
  final double progressBase;

  const CategorySummaryTile({
    super.key,
    required this.item,
    required this.progressBase,
  });

  @override
  Widget build(BuildContext context) {
    final color = getCategoryColor(item.category);
    final label = item.category;
    final progress = progressBase > 0 ? (item.amount / progressBase).clamp(0.0, 1.0) : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withAlpha(41),
            child: Icon(getCategoryIcon(label), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  color: color,
                  backgroundColor: color.withAlpha(46),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ').format(item.amount),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
