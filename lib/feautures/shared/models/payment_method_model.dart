class PaymentMethodModel {
  bool isCardEnabled;
  String cardNumber;
  String expiryDate;
  String cvv;
  bool isJazzcashEnabled;
  String jazzcashNumber;
  bool isEasypasaEnabled;
  String easypasaNumber;
  String activeMethod; // 'card', 'jazzcash', 'easypasa', or ''

  PaymentMethodModel({
    this.isCardEnabled = false,
    this.cardNumber = '',
    this.expiryDate = '',
    this.cvv = '',
    this.isJazzcashEnabled = false,
    this.jazzcashNumber = '',
    this.isEasypasaEnabled = false,
    this.easypasaNumber = '',
    this.activeMethod = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'isCardEnabled': isCardEnabled,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'isJazzcashEnabled': isJazzcashEnabled,
      'jazzcashNumber': jazzcashNumber,
      'isEasypasaEnabled': isEasypasaEnabled,
      'easypasaNumber': easypasaNumber,
      'activeMethod': activeMethod,
    };
  }

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      isCardEnabled: json['isCardEnabled'] ?? false,
      cardNumber: json['cardNumber'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      cvv: json['cvv'] ?? '',
      isJazzcashEnabled: json['isJazzcashEnabled'] ?? false,
      jazzcashNumber: json['jazzcashNumber'] ?? '',
      isEasypasaEnabled: json['isEasypasaEnabled'] ?? false,
      easypasaNumber: json['easypasaNumber'] ?? '',
      activeMethod: json['activeMethod'] ?? '',
    );
  }
}