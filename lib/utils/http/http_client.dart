import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FHttpHelper{

  static const String _baseurl = '';

  static Future<Map<String, dynamic>> get(String endpoint) async {

    final response = await http.get(Uri.parse('$_baseurl/$endpoint'));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(String endpoint, dynamic data) async {
    final response = await http.post(
      Uri.parse('$_baseurl/$endpoint'),
      headers: {'Content-type': 'application/json'},
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(String endpoint, dynamic data) async {
    final response = await http.put(
      Uri.parse('$_baseurl/$endpoint'),
      headers: {'Content-type': 'application/json'},
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(Uri.parse('$_baseurl/$endpoint'));
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if(response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }

  }


}