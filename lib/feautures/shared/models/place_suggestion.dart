import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;
  final LatLng? latLng;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.latLng,
  });

  PlaceSuggestion copyWith({LatLng? latLng, required description}) {
    return PlaceSuggestion(
      placeId: placeId,
      description: description,
      latLng: latLng ?? this.latLng,
    );
  }

  Map<String, dynamic> toJson() => {
    'placeId': placeId,
    'description': description,
    'lat': latLng?.latitude,
    'lng': latLng?.longitude,
  };

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final lat = json['lat'];
    final lng = json['lng'];
    return PlaceSuggestion(
      placeId: json['placeId'] ?? '',
      description: json['description'] ?? '',
      latLng: (lat != null && lng != null) ? LatLng(lat, lng) : null,
    );
  }
}
