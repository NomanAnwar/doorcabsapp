// maputils.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/ride_request_controller.dart';
import '../../models/city_model.dart';
import '../../models/services/polyline_service.dart';

class MapUtils {
  final PolylineService _polylineService = PolylineService();

  String determineUserCity(List<CityModel> cities, String pickupAddress) {
    final address = pickupAddress.toLowerCase();

    for (var city in cities) {
      if (address.contains(city.cityName.toLowerCase())) {
        return city.cityName;
      }
    }

    return cities.isNotEmpty ? cities.first.cityName : '';
  }

  List<LatLng> convertToLatLngList(String polyline) {
    return _polylineService.convertToLatLngList(polyline);
  }

  // FIXED: This method should return empty list to avoid overriding custom markers
  List<Marker> createMarkers(
      LatLng pickupLatLng,
      LatLng dropoffLatLng,
      String pickupLocation,
      String dropoffLocation,
      List<Map<String, dynamic>> stops
      ) {
    // FIXED: Return empty list - let RideRequestController handle custom markers
    print('🔄 MapUtils.createMarkers called - returning empty list to preserve custom markers');
    return [];

    // OLD CODE (COMMENTED OUT TO PREVENT OVERRIDING CUSTOM MARKERS):
    /*
    final markers = [
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickupLatLng,
        infoWindow: InfoWindow(title: 'Pickup: $pickupLocation'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: dropoffLatLng,
        infoWindow: InfoWindow(title: 'Dropoff: $dropoffLocation'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    ];

    for (int i = 0; i < stops.length; i++) {
      final s = stops[i];
      if (s['lat'] != null && s['lng'] != null) {
        final pos = LatLng((s['lat'] as num).toDouble(), (s['lng'] as num).toDouble());
        markers.add(Marker(
          markerId: MarkerId('stop_$i'),
          position: pos,
          infoWindow: InfoWindow(title: s['description'] ?? 'Stop'),
        ));
      }
    }

    return markers;
    */
  }

  void animateCameraToRoute(List<LatLng> pts, LatLng pickupLatLng, LatLng dropoffLatLng) {
    final controller = Get.find<RideRequestController>().mapController.future;
    controller.then((mapController) {
      try {
        LatLngBounds bounds;
        if (pts.isNotEmpty) {
          double minLat = pts.first.latitude, minLng = pts.first.longitude;
          double maxLat = pts.first.latitude, maxLng = pts.first.longitude;
          for (final p in pts) {
            minLat = min(minLat, p.latitude);
            minLng = min(minLng, p.longitude);
            maxLat = max(maxLat, p.latitude);
            maxLng = max(maxLng, p.longitude);
          }
          bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
        } else {
          final swLat = min(pickupLatLng.latitude, dropoffLatLng.latitude);
          final swLng = min(pickupLatLng.longitude, dropoffLatLng.longitude);
          final neLat = max(pickupLatLng.latitude, dropoffLatLng.latitude);
          final neLng = max(pickupLatLng.longitude, dropoffLatLng.longitude);
          bounds = LatLngBounds(southwest: LatLng(swLat, swLng), northeast: LatLng(neLat, neLng));
        }

        mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      } catch (e) {
        print('Error animating camera to route: $e');
      }
    });
  }
}