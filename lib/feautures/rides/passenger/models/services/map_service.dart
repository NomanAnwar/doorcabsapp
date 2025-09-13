import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  final String mapsApiKey = const String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4',
  );

  Future<Map<String, dynamic>?> getRouteDetails(LatLng origin, LatLng destination) async {
    final url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&key=$mapsApiKey";

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0] as Map<String, dynamic>;
          final legs = (route['legs'] ?? []) as List;
          if (legs.isEmpty) return null;
          final leg = legs[0] as Map<String, dynamic>;

          final distanceValue = ((leg['distance'] ?? {})['value'] ?? 0);
          final durationValue = ((leg['duration'] ?? {})['value'] ?? 0);

          final distance = (distanceValue is num) ? (distanceValue / 1000.0) : 0.0;
          final duration = (durationValue is num) ? (durationValue / 60.0) : 0.0;
          final polylinePoints = (route['overview_polyline'] ?? {})['points'] ?? '';

          return {
            'distance': distance,
            'duration': duration.round(),
            'polylinePoints': polylinePoints,
          };
        }
      }
    } catch (e) {
      print('Error getting route details: $e');
    }
    return null;
  }
}