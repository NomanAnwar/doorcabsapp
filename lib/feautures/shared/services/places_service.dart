import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/place_suggestion.dart';
import '../../../utils/http/api_retry_helper.dart'; // ✅ ADDED

class PlacesService {
  final String apiKey;

  PlacesService(this.apiKey);

  /// ✅ UPDATED: Get autocomplete suggestions with retry
  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    return await ApiRetryHelper.executeWithRetry(
          () async {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
              '?input=$input&key=$apiKey',
        );

        final res = await http.get(url);
        if (res.statusCode != 200) return [];

        final data = jsonDecode(res.body);
        if (data['status'] != 'OK') return [];

        return (data['predictions'] as List).map((p) {
          return PlaceSuggestion(
            placeId: p['place_id'],
            description: p['description'],
          );
        }).toList();
      },
      maxRetries: 2,
    );
  }

  /// ✅ UPDATED: Get place details (lat/lng) + enrich with city/country/ETA with retry
  Future<PlaceSuggestion?> placeDetails(
      PlaceSuggestion place, {
        LatLng? origin,
      }) async {
    try {
      return await ApiRetryHelper.executeWithRetry(
            () async {
          final url = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/details/json'
                '?place_id=${place.placeId}&key=$apiKey',
          );

          final res = await http.get(url);
          if (res.statusCode != 200) return null;

          final data = jsonDecode(res.body);
          if (data['status'] != 'OK') return null;

          final loc = data['result']['geometry']['location'];
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();

          final basePlace = place.copyWith(latLng: LatLng(lat, lng));

          // Also enrich with reverse geocode + ETA if origin is provided
          if (origin != null) {
            return await enrichPlace(basePlace, origin);
          }
          return basePlace;
        },
        maxRetries: 2,
      );
    } catch (e) {
      print("Error in placeDetails: $e");
      return null;
    }
  }

  /// ✅ UPDATED: Enrich with city, province, country, ETA with retry
  Future<PlaceSuggestion?> enrichPlace(
      PlaceSuggestion place,
      LatLng origin,
      ) async {
    try {
      if (place.latLng == null) return place;

      // 1) Reverse geocode to get city/province/country
      final geoUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
            '?latlng=${place.latLng!.latitude},${place.latLng!.longitude}'
            '&key=$apiKey',
      );

      final geoRes = await ApiRetryHelper.executeWithRetry(
            () => http.get(geoUrl),
        maxRetries: 2,
      );

      String? city, province, country;
      if (geoRes.statusCode == 200) {
        final geoData = jsonDecode(geoRes.body);
        if (geoData['status'] == 'OK' && geoData['results'].isNotEmpty) {
          final comps = geoData['results'][0]['address_components'] as List;
          for (var c in comps) {
            final types = List<String>.from(c['types']);
            if (types.contains('locality')) city = c['long_name'];
            if (types.contains('administrative_area_level_1')) {
              province = c['long_name'];
            }
            if (types.contains('country')) country = c['long_name'];
          }
        }
      }

      // 2) Distance Matrix for ETA
      String? eta;
      final dmUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
            '?origins=${origin.latitude},${origin.longitude}'
            '&destinations=${place.latLng!.latitude},${place.latLng!.longitude}'
            '&key=$apiKey',
      );

      final dmRes = await ApiRetryHelper.executeWithRetry(
            () => http.get(dmUrl),
        maxRetries: 2,
      );

      if (dmRes.statusCode == 200) {
        final dmData = jsonDecode(dmRes.body);
        print("Distance Matrix Response: "+ dmData.toString());
        if (dmData['status'] == 'OK' &&
            dmData['rows']?.isNotEmpty == true &&
            dmData['rows'][0]['elements'][0]['status'] == 'OK') {
          eta = dmData['rows'][0]['elements'][0]['duration']['text'];
        }
      }

      return place.copyWith(
        city: city,
        province: province,
        country: country,
        eta: eta,
      );
    } catch (e) {
      print("Error enriching place: $e");
      return place;
    }
  }
}


// import 'dart:convert';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import '../models/place_suggestion.dart';
//
// class PlacesService {
//   final String apiKey;
//
//   PlacesService(this.apiKey);
//
//   /// 🔍 Get autocomplete suggestions
//   Future<List<PlaceSuggestion>> autocomplete(String input) async {
//     final url = Uri.parse(
//       'https://maps.googleapis.com/maps/api/place/autocomplete/json'
//           '?input=$input&key=$apiKey',
//     );
//
//     final res = await http.get(url);
//     if (res.statusCode != 200) return [];
//
//     final data = jsonDecode(res.body);
//     if (data['status'] != 'OK') return [];
//
//     return (data['predictions'] as List).map((p) {
//       return PlaceSuggestion(
//         placeId: p['place_id'],
//         description: p['description'],
//       );
//     }).toList();
//   }
//
//   /// 📍 Get place details (lat/lng) + enrich with city/country/ETA
//   Future<PlaceSuggestion?> placeDetails(
//       PlaceSuggestion place, {
//         LatLng? origin,
//       }) async {
//     try {
//       final url = Uri.parse(
//         'https://maps.googleapis.com/maps/api/place/details/json'
//             '?place_id=${place.placeId}&key=$apiKey',
//       );
//
//       final res = await http.get(url);
//       if (res.statusCode != 200) return null;
//
//       final data = jsonDecode(res.body);
//       if (data['status'] != 'OK') return null;
//
//       final loc = data['result']['geometry']['location'];
//       final lat = (loc['lat'] as num).toDouble();
//       final lng = (loc['lng'] as num).toDouble();
//
//       final basePlace = place.copyWith(latLng: LatLng(lat, lng));
//
//       // Also enrich with reverse geocode + ETA if origin is provided
//       if (origin != null) {
//         return await enrichPlace(basePlace, origin);
//       }
//       return basePlace;
//     } catch (e) {
//       print("Error in placeDetails: $e");
//       return null;
//     }
//   }
//
//   /// 🏙️ Enrich with city, province, country, ETA
//   Future<PlaceSuggestion?> enrichPlace(
//       PlaceSuggestion place,
//       LatLng origin,
//       ) async {
//     try {
//       if (place.latLng == null) return place;
//
//       // 1) Reverse geocode to get city/province/country
//       final geoUrl = Uri.parse(
//         'https://maps.googleapis.com/maps/api/geocode/json'
//             '?latlng=${place.latLng!.latitude},${place.latLng!.longitude}'
//             '&key=$apiKey',
//       );
//       final geoRes = await http.get(geoUrl);
//
//       String? city, province, country;
//       if (geoRes.statusCode == 200) {
//         final geoData = jsonDecode(geoRes.body);
//         if (geoData['status'] == 'OK' && geoData['results'].isNotEmpty) {
//           final comps = geoData['results'][0]['address_components'] as List;
//           for (var c in comps) {
//             final types = List<String>.from(c['types']);
//             if (types.contains('locality')) city = c['long_name'];
//             if (types.contains('administrative_area_level_1')) {
//               province = c['long_name'];
//             }
//             if (types.contains('country')) country = c['long_name'];
//           }
//         }
//       }
//
//       // 2) Distance Matrix for ETA
//       String? eta;
//       final dmUrl = Uri.parse(
//         'https://maps.googleapis.com/maps/api/distancematrix/json'
//             '?origins=${origin.latitude},${origin.longitude}'
//             '&destinations=${place.latLng!.latitude},${place.latLng!.longitude}'
//             '&key=$apiKey',
//       );
//
//       final dmRes = await http.get(dmUrl);
//       if (dmRes.statusCode == 200) {
//         final dmData = jsonDecode(dmRes.body);
//         print("Distance Matrix Response: "+ dmData.toString());
//         if (dmData['status'] == 'OK' &&
//             dmData['rows']?.isNotEmpty == true &&
//             dmData['rows'][0]['elements'][0]['status'] == 'OK') {
//           eta = dmData['rows'][0]['elements'][0]['duration']['text'];
//         }
//       }
//
//       return place.copyWith(
//         city: city,
//         province: province,
//         country: country,
//         eta: eta,
//       );
//     } catch (e) {
//       print("Error enriching place: $e");
//       return place;
//     }
//   }
// }
