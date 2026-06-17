import 'dart:convert';

import '../../models/dashboard_summary.dart';
import '../../models/transaction_item.dart';
import 'api_service.dart';
import 'auth_service.dart';

class DashboardService {
  final AuthService _authService = AuthService();

  Future<DashboardSummary> getSummary() async {
    final token = await _authService.getToken();
    final response = await ApiService.get('/dashboard/summary', token: token);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return DashboardSummary.fromJson(json);
  }

  Future<List<TransactionItem>> getRecentTransactions() async {
    final token = await _authService.getToken();
    final response = await ApiService.get('/dashboard/recent-transactions', token: token);
    final jsonList = jsonDecode(response.body) as List<dynamic>;
    return jsonList
        .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
