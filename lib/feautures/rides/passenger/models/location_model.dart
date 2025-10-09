import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserLocation {
  final double latitude;
  final double longitude;
  final String address;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };

  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
    latitude: json['latitude'] ?? 0.0,
    longitude: json['longitude'] ?? 0.0,
    address: json['address'] ?? '',
  );
}