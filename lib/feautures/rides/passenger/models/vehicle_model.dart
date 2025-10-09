// class VehicleModel {
//   final String id;
//   final String name;
//   final double? fareValue;   // make it nullable if not provided
//   final String description;
//   final String? iconBase64;  // make it nullable if not provided
//   final List<String> supportsRideType;
//
//   VehicleModel({
//     required this.id,
//     required this.name,
//     this.fareValue,
//     required this.description,
//     this.iconBase64,
//     required this.supportsRideType,
//   });
//
//   factory VehicleModel.fromJson(Map<String, dynamic> json) {
//     return VehicleModel(
//       id: json["_id"] ?? "",
//       name: json["category_name"] ?? "",
//       fareValue: (json["fare_value"] != null)
//           ? double.tryParse(json["fare_value"].toString())
//           : null,
//       description: json["category_description"] ?? "",
//       iconBase64: json["category_icon"], // may be null
//       supportsRideType: List<String>.from(json["supports_ride_type"] ?? []),
//     );
//   }
// }




class VehicleModel {
  final String id;
  final String name;
  final double fareValue;
  final String description;
  final String iconBase64;
  final List<String> supportsRideType;

  VehicleModel({
    required this.id,
    required this.name,
    required this.fareValue,
    required this.description,
    required this.iconBase64,
    required this.supportsRideType,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json["_id"],
      name: json["category_name"],
      fareValue: (json["fare_value"] ?? 0).toDouble(),
      description: json["category_description"] ?? "",
      iconBase64: json["category_icon"] ?? "",
      supportsRideType: List<String>.from(json["supports_ride_type"] ?? []),
    );
  }
}
