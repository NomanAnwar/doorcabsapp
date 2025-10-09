// mapservice.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  final String mapsApiKey = const String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4',
  );

  // FIXED: Add waypoints parameter to include stops in route calculation
  Future<Map<String, dynamic>?> getRouteDetails(
      LatLng origin,
      LatLng destination, {
        List<LatLng> waypoints = const [], // ADD THIS PARAMETER
      }) async {

    // FIXED: Proper waypoint handling for Google Directions API
    String waypointsParam = '';
    if (waypoints.isNotEmpty) {
      final waypointsString = waypoints.map((wp) => 'via:${wp.latitude},${wp.longitude}').join('|');
      waypointsParam = '&waypoints=optimize:true|$waypointsString';
    }

    final url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "$waypointsParam" // FIXED: ADD WAYPOINTS TO URL
        "&key=$mapsApiKey";

    print('🛣️ Calculating route URL: ${url.replaceAll(mapsApiKey, 'HIDDEN')}');

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📍 Directions API Response: ${data['status']}');

        if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0] as Map<String, dynamic>;
          final legs = (route['legs'] ?? []) as List;
          if (legs.isEmpty) return null;

          // FIXED: Calculate total distance and duration across all legs (for routes with waypoints)
          double totalDistance = 0.0;
          int totalDuration = 0;

          for (final leg in legs) {
            final legMap = leg as Map<String, dynamic>;
            final distanceValue = ((legMap['distance'] ?? {})['value'] ?? 0);
            final durationValue = ((legMap['duration'] ?? {})['value'] ?? 0);

            totalDistance += (distanceValue is num) ? (distanceValue / 1000.0) : 0.0;
            totalDuration += (durationValue is num) ? (durationValue ~/ 60) : 0;
          }

          final polylinePoints = (route['overview_polyline'] ?? {})['points'] ?? '';

          print('📍 Route calculated: ${totalDistance.toStringAsFixed(2)} km, $totalDuration min, ${legs.length} legs');

          return {
            'distance': totalDistance,
            'duration': totalDuration,
            'polylinePoints': polylinePoints,
          };
        } else {
          print('❌ Directions API error: ${data['status']} - ${data['error_message']}');
        }
      }
    } catch (e) {
      print('Error getting route details: $e');
    }
    return null;
  }
}