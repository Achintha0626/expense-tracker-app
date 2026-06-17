import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'auth_service.dart';

class TransactionService {
  final AuthService _authService = AuthService();

  Future<http.Response> createTransaction({
    required String title,
    required double amount,
    required String transactionType,
    required String category,
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
        'description': description,
      },
      token: token,
    );
  }
}
