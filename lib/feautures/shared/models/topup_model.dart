class TopUpModel {
  final String paymentMethod;
  final String paymentMethodIcon;
  final double currentBalance;
  final List<int> quickAmounts;

  TopUpModel({
    required this.paymentMethod,
    required this.paymentMethodIcon,
    required this.currentBalance,
    required this.quickAmounts,
  });

  factory TopUpModel.fromJson(Map<String, dynamic> json) {
    return TopUpModel(
      paymentMethod: json['paymentMethod'] ?? 'Jazzcash',
      paymentMethodIcon: json['paymentMethodIcon'] ?? '',
      currentBalance: (json['currentBalance'] ?? 0.0).toDouble(),
      quickAmounts: List<int>.from(json['quickAmounts'] ?? [320, 640, 960]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentMethod': paymentMethod,
      'paymentMethodIcon': paymentMethodIcon,
      'currentBalance': currentBalance,
      'quickAmounts': quickAmounts,
    };
  }
}

class TopUpRequest {
  final int amount;
  final String paymentMethod;
  final String userId;

  TopUpRequest({
    required this.amount,
    required this.paymentMethod,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'paymentMethod': paymentMethod,
      'userId': userId,
    };
  }
}

class TopUpResponse {
  final bool success;
  final String message;
  final String? transactionId;
  final double? newBalance;

  TopUpResponse({
    required this.success,
    required this.message,
    this.transactionId,
    this.newBalance,
  });

  factory TopUpResponse.fromJson(Map<String, dynamic> json) {
    return TopUpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      transactionId: json['transactionId'],
      newBalance: json['newBalance']?.toDouble(),
    );
  }
}
