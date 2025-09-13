// In your ride_type.dart model
class RideType {
  final String title;
  final String image;
  final bool isBase64;
  final double fareValue; // Add this field

  RideType(this.title, this.image, {this.isBase64 = false, this.fareValue = 0.0});

  // Update fromJson method
  factory RideType.fromJson(Map<String, dynamic> json) {
    return RideType(
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