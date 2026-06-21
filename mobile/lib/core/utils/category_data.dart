import 'package:flutter/material.dart';

const Map<String, IconData> categoryIcons = {
  'food': Icons.fastfood,
  'transport': Icons.directions_car,
  'bills': Icons.receipt_long,
  'phone': Icons.phone_android,
  'shopping': Icons.shopping_bag,
  'health': Icons.health_and_safety,
  'education': Icons.school,
  'salary': Icons.attach_money,
  'freelance': Icons.work_outline,
  'gift': Icons.card_giftcard,
  'investment': Icons.trending_up,
  'other': Icons.category,
};

const Map<String, Color> categoryColors = {
  'food': Color(0xFFFFA726),
  'transport': Color(0xFF29B6F6),
  'bills': Color(0xFF7E57C2),
  'phone': Color(0xFF5C6BC0),
  'shopping': Color(0xFFEC407A),
  'health': Color(0xFFEF5350),
  'education': Color(0xFF66BB6A),
  'salary': Color(0xFF26A69A),
  'freelance': Color(0xFF42A5F5),
  'gift': Color(0xFFAB47BC),
  'investment': Color(0xFFFFCA28),
  'other': Color(0xFF90A4AE),
};

IconData getCategoryIcon(String category) {
  return categoryIcons[category.toLowerCase()] ?? Icons.category;
}

Color getCategoryColor(String category) {
  return categoryColors[category.toLowerCase()] ?? const Color(0xFF90A4AE);
}
