import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodingService {
  final String mapsApiKey = const String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4',
  );

  Future<LatLng?> getLatLngFromAddress(String address) async {
    if (address.isEmpty) return null;
    final url = "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$mapsApiKey";
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final location = (data['results'][0]['geometry']['location']) as Map<String, dynamic>;
          return LatLng((location['lat'] as num).toDouble(), (location['lng'] as num).toDouble());
        }
      }
    } catch (e) {
      print('Error getting coordinates: $e');
    }
    return null;
  }
}