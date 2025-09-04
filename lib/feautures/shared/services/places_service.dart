import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place_suggestion.dart';

class PlacesService {
  final String apiKey;
  PlacesService(this.apiKey);

  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    if (input.trim().isEmpty) return [];
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(input)}'
          '&components=country:pk'
          '&key=$apiKey',
    );
    try {
      final res = await http.get(url);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      if (data['status'] != 'OK') {
        print('Places API error: ${data['status']} - ${data['error_message']}');
        return [];
      }
      final preds = (data['predictions'] as List?) ?? [];
      return preds
          .map((p) => PlaceSuggestion(
        placeId: p['place_id'],
        description: p['description'],
      ))
          .toList();
    } catch (e) {
      print('Autocomplete error: $e');
      return [];
    }
  }

  Future<PlaceSuggestion?> placeDetails(PlaceSuggestion place) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=${place.placeId}&fields=geometry,formatted_address&key=$apiKey',
    );
    try {
      final res = await http.get(url);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data['status'] != 'OK') {
        print('Place details error: ${data['status']} - ${data['error_message']}');
        return null;
      }
      final result = data['result'];
      if (result == null) return null;
      final loc = result['geometry']?['location'];
      if (loc == null) return null;
      return place.copyWith(
        description: result['formatted_address'] ?? place.description,
        latLng: LatLng(loc['lat'] * 1.0, loc['lng'] * 1.0),
      );
    } catch (e) {
      print('PlaceDetails error: $e');
      return null;
    }
  }
}
