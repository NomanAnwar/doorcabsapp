import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../../common/widgets/snakbar/snackbar.dart';

class FHttpHelper {
  static String _baseUrl = '';

  /// Call this at app startup to set base URL dynamically
  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  static String get baseUrl => _baseUrl;

  /// Optional auth token
  static String? _authToken;
  static bool _useBearer = true; // default is Bearer

  /// Configure token
  static void setAuthToken(String token, {bool useBearer = true}) {
    _authToken = token;
    _useBearer = useBearer;
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
    };

    if (_authToken != null) {
      if (_useBearer) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $_authToken';
      } else {
        headers['token'] = _authToken!;
      }
    }

    http.Response response;

    try {
      if (kDebugMode) {
        print('[FHttpHelper] $method $uri');
        if (body != null) print('Body: $body');
        print('Headers: $headers');
      }

      switch (method) {
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: json.encode(body))
              .timeout(const Duration(seconds: 120));
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: json.encode(body))
              .timeout(const Duration(seconds: 45));
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 45));
          break;
        default:
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 120));
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
    // FSnackbar.show(title: 'Request', message: response.body.toString());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      if (kDebugMode) {
        print("API Error Response : $error");
      }
      throw Exception(error['message'] ?? 'Error: ${response.statusCode}');
    }
  }

  /// GET request with body (non-standard but required by some APIs)
  static Future<Map<String, dynamic>> getWithBody(String endpoint, dynamic data) async {
    return _requestWithBody(
      method: 'GET',
      endpoint: endpoint,
      body: data,
    );
  }

  /// Core request handler for methods that need body (like GET with body)
  static Future<Map<String, dynamic>> _requestWithBody({
    required String method,
    required String endpoint,
    dynamic body,
  }) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');

    final headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
    };

    if (_authToken != null) {
      if (_useBearer) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $_authToken';
      } else {
        headers['token'] = _authToken!;
      }
    }

    try {
      if (kDebugMode) {
        print('[FHttpHelper] $method with body: $uri');
        if (body != null) print('Body: $body');
        print('Headers: $headers');
      }

      // Create a custom request for GET with body
      final request = http.Request(method, uri);
      request.headers.addAll(headers);
      if (body != null) {
        request.body = json.encode(body);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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

}
