class ReferralModel {
  final String message;
  // final bool success;

  ReferralModel({
    required this.message,
    // required this.success,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      message: json['message'] ?? '',
      // success: true,
    );
  }
}
