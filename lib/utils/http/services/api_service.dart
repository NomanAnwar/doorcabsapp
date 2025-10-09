// lib/utils/services/api_service.dart

import '../http_client.dart';

class ApiService {
  static Future<Map<String, dynamic>> signUp(String phone, String role, String language) async {
    final body = {
      "phone_no": phone,
      "role": role,
      "preferred_language": language,
    };
    return await FHttpHelper.post("service/signUp", body);
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp, String role) async {
    final body = {"phone_no": phone, "otp": otp, "role": role};
    return await FHttpHelper.post("service/verify-otp", body);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    return await FHttpHelper.get("passenger/get-profile-info");
  }

  static Future<Map<String, dynamic>> getRideTypes() async {
    return await FHttpHelper.get('vehicle/list');
  }

  static Future<Map<String, dynamic>> getCities() async {
    return await FHttpHelper.get("city/list-cities");
  }

  static Future<Map<String, dynamic>> requestRide(Map<String, dynamic> body) async {
    return await FHttpHelper.post('ride/request', body);
  }
}