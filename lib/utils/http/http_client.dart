import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class FHttpHelper {
  static String _baseUrl = '';

  /// Call this at app startup to set base URL dynamically
  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// Optional auth token
  static String? _authToken;
  static void setAuthToken(String token) {
    _authToken = token;
  }

  /// GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    return _request(
      method: 'GET',
      endpoint: endpoint,
    );
  }

  /// POST request
  static Future<Map<String, dynamic>> post(String endpoint, dynamic data) async {
    return _request(
      method: 'POST',
      endpoint: endpoint,
      body: data,
    );
  }

  /// PUT request
  static Future<Map<String, dynamic>> put(String endpoint, dynamic data) async {
    return _request(
      method: 'PUT',
      endpoint: endpoint,
      body: data,
    );
  }

  /// DELETE request
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    return _request(
      method: 'DELETE',
      endpoint: endpoint,
    );
  }

  /// Core request handler
  static Future<Map<String, dynamic>> _request({
    required String method,
    required String endpoint,
    dynamic body,
  }) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');

    final headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      if (_authToken != null) HttpHeaders.authorizationHeader: 'Bearer $_authToken',
    };

    http.Response response;

    try {
      if (kDebugMode) {
        print('[FHttpHelper] $method $uri');
        if (body != null) print('Body: $body');
      }

      switch (method) {
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: json.encode(body))
              .timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: json.encode(body))
              .timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;
        default:
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
      }

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } on TimeoutException {
      throw Exception('Request timed out');
    }
  }

  /// Handle API response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Error: ${response.statusCode}');
    }
  }
}
