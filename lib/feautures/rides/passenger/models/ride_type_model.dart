// In your ride_type_model.dart model
class RideTypeModel {
  final String title;
  final String image;
  final bool isBase64;
  final double fareValue; // Add this field

  RideTypeModel(this.title, this.image, {this.isBase64 = false, this.fareValue = 0.0});

  // Update fromJson method
  factory RideTypeModel.fromJson(Map<String, dynamic> json) {
    return RideTypeModel(
      json['name'] ?? '',
      json['iconBase64'] ?? '',
      isBase64: (json['iconBase64'] ?? '').isNotEmpty,
      fareValue: (json['fare_value'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': title,
      'iconBase64': image,
      'fare_value': fareValue,
    };
  }
}