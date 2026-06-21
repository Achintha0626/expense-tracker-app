import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'api_service.dart';
import 'auth_service.dart';
import 'dart:convert';

import '../../models/transaction_item.dart';

class TransactionService {
  final AuthService _authService = AuthService();

  Future<http.Response> createTransaction({
    required String title,
    required double amount,
    required String transactionType,
    required String category,
    String? subCategory,
    String? description,
  }) async {
    final token = await _authService.getToken();
    return ApiService.post(
      '/transactions',
      {
        'title': title,
        'amount': amount,
        'transaction_type': transactionType,
        'category': category,
        'sub_category': subCategory,
        'description': description,
      },
      token: token,
    );
  }

  Future<List<TransactionItem>> getTransactions({
    String? type,
    String? category,
    String? subCategory,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _authService.getToken();
    final params = <String, String>{};
    final dateFormat = DateFormat('yyyy-MM-dd');
    if (type != null && type.isNotEmpty) params['transaction_type'] = type;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (subCategory != null && subCategory.isNotEmpty) params['sub_category'] = subCategory;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (startDate != null) params['start_date'] = dateFormat.format(startDate);
    if (endDate != null) params['end_date'] = dateFormat.format(endDate);
    params['page'] = page.toString();
    params['limit'] = limit.toString();

    final query = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
    final endpoint = query.isEmpty ? '/transactions' : '/transactions?$query';
    final response = await ApiService.get(endpoint, token: token);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((i) => TransactionItem.fromJson(i as Map<String, dynamic>)).toList();
  }

  Future<List<String>> getCategories() async {
    final token = await _authService.getToken();
    final response = await ApiService.get('/transactions/categories', token: token);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => item.toString()).toList();
  }

  Future<List<String>> getSubCategories(String category) async {
    final token = await _authService.getToken();
    final response = await ApiService.get('/transactions/subcategories?category=${Uri.encodeQueryComponent(category)}', token: token);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => item.toString()).toList();
  }

  Future<http.Response> updateTransaction(int id, Map<String, dynamic> data) async {
    final token = await _authService.getToken();
    return ApiService.put('/transactions/$id', data, token: token);
  }

  Future<http.Response> deleteTransaction(int id) async {
    final token = await _authService.getToken();
    return ApiService.delete('/transactions/$id', token: token);
  }
}
