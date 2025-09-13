import 'dart:math';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../models/city_model.dart';
import '../../../models/services/geocoding_service.dart';
import '../../../models/services/map_service.dart';
import '../../../screens/reusable_widgets/map_utils.dart';


class MapController extends GetxController {
  final pickupLocation = RxString('');
  final dropoffLocation = RxString('');
  final routePolyline = Rx<Polyline?>(null);
  final distanceKm = RxDouble(0.0);
  final durationMinutes = RxInt(0);
  final markers = <Marker>[].obs;

  LatLng? lastPickupCoords;
  LatLng? lastDropoffCoords;
  final MapService _mapService = MapService();
  final MapUtils _mapUtils = MapUtils();

  void initializeFromArgs(Map<String, dynamic> args) {
    pickupLocation.value = (args['pickup'] ?? '').toString();
    dropoffLocation.value = (args['dropoff'] ?? '').toString();

    if (args['pickupLat'] != null && args['pickupLng'] != null) {
      try {
        lastPickupCoords = LatLng(
          (args['pickupLat'] as num).toDouble(),
          (args['pickupLng'] as num).toDouble(),
        );
      } catch (_) {}
    }
    if (args['dropoffLat'] != null && args['dropoffLng'] != null) {
      try {
        lastDropoffCoords = LatLng(
          (args['dropoffLat'] as num).toDouble(),
          (args['dropoffLng'] as num).toDouble(),
        );
      } catch (_) {}
    }
  }

  void determineUserCity(List<CityModel> cities, String pickupAddress) {
    final userCity = _mapUtils.determineUserCity(cities, pickupAddress);
    print('📍 Detected user city: $userCity');
  }

  Future<Map<String, dynamic>?> calculateRoute(
      String pickup,
      String dropoff,
      GeocodingService geocodingService,
      List<Map<String, dynamic>> stops
      ) async {
    if (pickup.isEmpty || dropoff.isEmpty) {
      print('Pickup or dropoff empty, skipping route calc.');
      return null;
    }

    try {
      LatLng? pickupLatLng = lastPickupCoords;
      LatLng? dropoffLatLng = lastDropoffCoords;

      if (pickupLatLng == null) {
        pickupLatLng = await geocodingService.getLatLngFromAddress(pickup);
      }
      if (dropoffLatLng == null) {
        dropoffLatLng = await geocodingService.getLatLngFromAddress(dropoff);
      }

      if (pickupLatLng == null || dropoffLatLng == null) {
        print('❌ Could not get coordinates for addresses');
        return null;
      }

      final routeDetails = await _mapService.getRouteDetails(pickupLatLng, dropoffLatLng);

      if (routeDetails != null) {
        distanceKm.value = routeDetails['distance'];
        durationMinutes.value = routeDetails['duration'];

        _drawRouteOnMap(
            routeDetails['polylinePoints'],
            pickupLatLng,
            dropoffLatLng,
            stops
        );

        return routeDetails;
      }
    } catch (e) {
      print('❌ Error calculating route: $e');
    }
    return null;
  }

  void _drawRouteOnMap(String polylinePoints, LatLng pickupLatLng, LatLng dropoffLatLng, List<Map<String, dynamic>> stops) {
    if (polylinePoints.isEmpty) return;

    final pts = _mapUtils.convertToLatLngList(polylinePoints);
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: pts,
      color: FColors.secondaryColor,
      width: 4,
    );

    routePolyline.value = polyline;

    markers.clear();
    markers.addAll(_mapUtils.createMarkers(
        pickupLatLng,
        dropoffLatLng,
        pickupLocation.value,
        dropoffLocation.value,
        stops
    ));

    _mapUtils.animateCameraToRoute(pts, pickupLatLng, dropoffLatLng);
  }
}