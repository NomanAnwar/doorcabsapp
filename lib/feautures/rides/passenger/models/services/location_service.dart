import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../location_model.dart';

class RideTypeLocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permissions
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permissions
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position with high accuracy
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Reverse geocode coordinates to get address
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'] ?? 'Unknown Location';
        }
      }
      return 'Unknown Location';
    } catch (e) {
      print('Reverse geocoding error: $e');
      return 'Unknown Location';
    }
  }

  /// Get complete user location with address
  Future<UserLocation> getCompleteUserLocation() async {
    try {
      // Check if location services are enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permissions
      LocationPermission permission = await checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      // Get current position
      final position = await getCurrentPosition();

      // Get address from coordinates
      final address = await reverseGeocode(
          position.latitude,
          position.longitude
      );

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );

    } catch (e) {
      print('Error getting user location: $e');
      rethrow;
    }
  }

}