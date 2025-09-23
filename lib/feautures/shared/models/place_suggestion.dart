import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;
  final LatLng? latLng;

  /// Extra fields we enrich later
  final String? city;
  final String? province;
  final String? country;
  final String? eta; // e.g., "25 min"

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.latLng,
    this.city,
    this.province,
    this.country,
    this.eta,
  });

  ///  CopyWith to update values without losing old ones
  PlaceSuggestion copyWith({
    String? placeId,
    String? description,
    LatLng? latLng,
    String? city,
    String? province,
    String? country,
    String? eta,
  }) {
    return PlaceSuggestion(
      placeId: placeId ?? this.placeId,
      description: description ?? this.description,
      latLng: latLng ?? this.latLng,
      city: city ?? this.city,
      province: province ?? this.province,
      country: country ?? this.country,
      eta: eta ?? this.eta,
    );
  }

  ///  Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'description': description,
      'lat': latLng?.latitude,
      'lng': latLng?.longitude,
      'city': city,
      'province': province,
      'country': country,
      'eta': eta,
    };
  }

  ///  Create from JSON
  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['placeId'] ?? '',
      description: json['description'] ?? '',
      latLng: (json['lat'] != null && json['lng'] != null)
          ? LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      )
          : null,
      city: json['city'],
      province: json['province'],
      country: json['country'],
      eta: json['eta'],
    );
  }
}
