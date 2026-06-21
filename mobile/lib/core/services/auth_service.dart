import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

  Future<http.Response> register(
    String name,
    String email,
    String password,
  ) async {
    return ApiService.post(
      '/auth/register',
      {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  Future<http.Response> login(
    String email,
    String password,
  ) async {
    return ApiService.post(
      '/auth/login',
      {
        'email': email,
        'password': password,
      },
    );
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<http.Response> getCurrentUser() async {
    final token = await getToken();
    return ApiService.get('/me', token: token);
  }

  Future<bool> healthCheck() async {
    try {
      final response = await ApiService.get('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
