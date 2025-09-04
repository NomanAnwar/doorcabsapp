// lib/features/profile_completion/models/generic_response.dart
class GenericResponse {
  final String message;
  final Map<String, dynamic> payload;

  GenericResponse({required this.message, required this.payload});

  factory GenericResponse.fromJson(Map<String, dynamic> json) {
    return GenericResponse(
      message: json['message'] ?? '',
      payload: json..remove('message'),
    );
  }
}
