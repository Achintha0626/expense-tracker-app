import 'dart:convert';

import 'package:intl/intl.dart';

import 'api_service.dart';
import 'auth_service.dart';
import '../../models/analytics_models.dart';

class AnalyticsService {
  final AuthService _authService = AuthService();

  Future<List<CategoryBreakdownItem>> getCategoryBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await _authService.getToken();
    final params = <String, String>{};
    final formatter = DateFormat('yyyy-MM-dd');

    if (startDate != null) {
      params['start_date'] = formatter.format(startDate);
    }
    if (endDate != null) {
      params['end_date'] = formatter.format(endDate);
    }

    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final endpoint = query.isEmpty ? '/analytics/category-breakdown' : '/analytics/category-breakdown?$query';
    final response = await ApiService.get(endpoint, token: token);
    final jsonList = jsonDecode(response.body) as List<dynamic>;
    return jsonList
        .map((item) => CategoryBreakdownItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MonthlySummaryItem>> getMonthlySummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await _authService.getToken();
    final params = <String, String>{};
    final formatter = DateFormat('yyyy-MM-dd');

    if (startDate != null) {
      params['start_date'] = formatter.format(startDate);
    }
    if (endDate != null) {
      params['end_date'] = formatter.format(endDate);
    }

    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final endpoint = query.isEmpty ? '/analytics/monthly-summary' : '/analytics/monthly-summary?$query';
    final response = await ApiService.get(endpoint, token: token);
    final jsonList = jsonDecode(response.body) as List<dynamic>;
    return jsonList
        .map((item) => MonthlySummaryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
