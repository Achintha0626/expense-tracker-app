import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 30);

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      final response = await http
          .post(uri, headers: _headers(token), body: jsonEncode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw 'Cannot connect to server. Please check your internet or try again.';
    } on http.ClientException {
      throw 'Cannot connect to server. Please check your internet or try again.';
    } on TimeoutException {
      throw 'Request timed out. Please try again.';
    } catch (_) {
      throw 'Something went wrong. Please try again.';
    }
  }

  static Future<http.Response> get(
    String endpoint, {
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw 'Cannot connect to server. Please check your internet or try again.';
    } on http.ClientException {
      throw 'Cannot connect to server. Please check your internet or try again.';
    } on TimeoutException {
      throw 'Request timed out. Please try again.';
    } catch (_) {
      throw 'Something went wrong. Please try again.';
    }
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      final response = await http
          .put(uri, headers: _headers(token), body: jsonEncode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw 'Cannot connect to server. Please check your internet or try again.';
    } on http.ClientException {
      throw 'Cannot connect to server. Please check your internet or try again.';
    } on TimeoutException {
      throw 'Request timed out. Please try again.';
    } catch (_) {
      throw 'Something went wrong. Please try again.';
    }
  }

  static Future<http.Response> delete(
    String endpoint, {
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      final response = await http
          .delete(uri, headers: _headers(token))
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw 'Cannot connect to server. Please check your internet or try again.';
    } on http.ClientException {
      throw 'Cannot connect to server. Please check your internet or try again.';
    } on TimeoutException {
      throw 'Request timed out. Please try again.';
    } catch (_) {
      throw 'Something went wrong. Please try again.';
    }
  }

  static http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    if (response.statusCode == 502 || response.statusCode == 503) {
      throw 'Server is waking up. Please wait and try again.';
    }

    final error = _decodeError(response.body);
    throw error ?? 'Something went wrong. Please try again.';
  }

  static String? _decodeError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        if (data['detail'] != null) {
          return data['detail'].toString();
        }
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  static Map<String, String> _headers(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
