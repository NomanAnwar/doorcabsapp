
class SignUpResponse {
  final String message;
  final String userId;
  final String phoneNo; //  added

  SignUpResponse({
    required this.message,
    required this.userId,
    required this.phoneNo,
  });

  factory SignUpResponse.fromJson(Map<String, dynamic> json) {
    return SignUpResponse(
      message: json['message'] ?? '',
      userId: json['userId'] ?? '',
      phoneNo: json['phone_no'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'userId': userId,
    'phone_no': phoneNo,
  };
}
