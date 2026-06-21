import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../models/transaction_item.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';

class TransactionService {
  static const Duration _timeout = Duration(seconds: 75);

  final AuthService _authService = AuthService();

  Future<http.Response> createTransaction({
    required String title,
    required double amount,
    required String transactionType,
    required String category,
    String? subCategory,
    String? description,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedCategory = category.trim();
    final normalizedType = transactionType.trim().toLowerCase();
    final normalizedSubCategory = subCategory?.trim();
    final normalizedDescription = description?.trim();

    if (normalizedTitle.isEmpty) {
      throw 'Title is required.';
    }
    if (!amount.isFinite || amount <= 0) {
      throw 'Amount must be a valid number greater than zero.';
    }
    if (normalizedCategory.isEmpty) {
      throw 'Category is required.';
    }
    if (normalizedType != 'income' && normalizedType != 'expense') {
      throw 'Transaction type must be "income" or "expense".';
    }

    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw 'Authentication token not found. Please login again.';
    }

    final body = <String, dynamic>{
      'title': normalizedTitle,
      'amount': amount,
      'transaction_type': normalizedType,
      'category': normalizedCategory,
      'sub_category':
          normalizedSubCategory == null || normalizedSubCategory.isEmpty
          ? null
          : normalizedSubCategory,
      'description':
          normalizedDescription == null || normalizedDescription.isEmpty
          ? null
          : normalizedDescription,
    };
    final uri = Uri.parse('${ApiConstants.baseUrl}/transactions/');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _debugLog('Request URL: $uri');
    _debugLog('Request body: ${jsonEncode(body)}');
    _debugLog('Authorization header: Bearer <token>');

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);

      _debugLog('Status code: ${response.statusCode}');
      _debugLog('Response body: ${response.body}');
      return response;
    } on TimeoutException catch (error) {
      _debugLog('Create transaction timed out: $error');
      throw 'Request timed out. Please try again.';
    } on http.ClientException catch (error) {
      _debugLog('Create transaction connection error: $error');
      throw 'Cannot connect to server. Please check your internet or try again.';
    } catch (error, stackTrace) {
      if (kDebugMode) {
        developer.log(
          'Unexpected create transaction error',
          name: 'TransactionService',
          error: error,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'TransactionService');
    }
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
    if (subCategory != null && subCategory.isNotEmpty) {
      params['sub_category'] = subCategory;
    }
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (startDate != null) params['start_date'] = dateFormat.format(startDate);
    if (endDate != null) params['end_date'] = dateFormat.format(endDate);
    params['page'] = page.toString();
    params['limit'] = limit.toString();

    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    final endpoint = query.isEmpty ? '/transactions' : '/transactions?$query';
    final response = await ApiService.get(endpoint, token: token);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((i) => TransactionItem.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getCategories() async {
    final token = await _authService.getToken();
    final response = await ApiService.get(
      '/transactions/categories',
      token: token,
    );
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => item.toString()).toList();
  }

  Future<List<String>> getSubCategories(String category) async {
    final token = await _authService.getToken();
    final response = await ApiService.get(
      '/transactions/subcategories?category=${Uri.encodeQueryComponent(category)}',
      token: token,
    );
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => item.toString()).toList();
  }

  Future<http.Response> updateTransaction(
    int id,
    Map<String, dynamic> data,
  ) async {
    final token = await _authService.getToken();
    return ApiService.put('/transactions/$id', data, token: token);
  }

  Future<http.Response> deleteTransaction(int id) async {
    final token = await _authService.getToken();
    return ApiService.delete('/transactions/$id', token: token);
  }
}
