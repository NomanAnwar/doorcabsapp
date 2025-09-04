// lib/features/profile_completion/models/cnic_response.dart
class CNICResponse {
  final String message;
  final Map<String, dynamic> driver;

  CNICResponse({required this.message, required this.driver});

  factory CNICResponse.fromJson(Map<String, dynamic> json) {
    return CNICResponse(
      message: json['message'] ?? '',
      driver: json['driver'] != null ? Map<String,dynamic>.from(json['driver']) : {},
    );
  }
}
