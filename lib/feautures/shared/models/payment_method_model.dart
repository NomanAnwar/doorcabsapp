class PaymentMethodModel {
  bool isCardEnabled;
  String cardNumber;
  String expiryDate;
  String cvv;
  bool isJazzcashEnabled;
  String jazzcashNumber;
  bool isEasypasaEnabled;
  String easypasaNumber;

  PaymentMethodModel({
    this.isCardEnabled = false,
    this.cardNumber = '',
    this.expiryDate = '',
    this.cvv = '',
    this.isJazzcashEnabled = false,
    this.jazzcashNumber = '',
    this.isEasypasaEnabled = false,
    this.easypasaNumber = '',
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
    );
  }
}
