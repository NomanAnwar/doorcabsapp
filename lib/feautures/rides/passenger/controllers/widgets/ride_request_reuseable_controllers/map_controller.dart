// mapcontroller.dart
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
  final markers = <Marker>{}.obs; // instead of <Marker>[].obs


  LatLng? lastPickupCoords;
  LatLng? lastDropoffCoords;

  // FIXED: Add property to store stop coordinates
  final stopCoords = <LatLng>[].obs;

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

      // FIXED: Get coordinates for pickup/dropoff if not provided
      if (pickupLatLng == null) {
        pickupLatLng = await geocodingService.getLatLngFromAddress(pickup);
        if (pickupLatLng != null) {
          lastPickupCoords = pickupLatLng;
        }
      }
      if (dropoffLatLng == null) {
        dropoffLatLng = await geocodingService.getLatLngFromAddress(dropoff);
        if (dropoffLatLng != null) {
          lastDropoffCoords = dropoffLatLng;
        }
      }

      if (pickupLatLng == null || dropoffLatLng == null) {
        print(' Could not get coordinates for addresses');
        return null;
      }

      // FIXED: Get coordinates for stops and store them
      final List<LatLng> waypoints = await _getStopCoordinates(stops, geocodingService);
      stopCoords.assignAll(waypoints); // FIXED: Store for later use

      print('📍 Calculating route with ${waypoints.length} stops');

      // FIXED: Pass waypoints to getRouteDetails
      final routeDetails = await _mapService.getRouteDetails(
        pickupLatLng,
        dropoffLatLng,
        waypoints: waypoints, // ADD THIS
      );

      if (routeDetails != null) {
        distanceKm.value = routeDetails['distance'];
        durationMinutes.value = routeDetails['duration'];

        // FIXED: Don't draw route here - just update polyline
        final pts = _mapUtils.convertToLatLngList(routeDetails['polylinePoints']);
        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: pts,
          color: FColors.secondaryColor,
          width: 4,
        );

        routePolyline.value = polyline;

        print('🔄 Route calculated - ${pts.length} points, ${waypoints.length} stops');

        return routeDetails;
      }
    } catch (e) {
      print(' Error calculating route: $e');
    }
    return null;
  }

  // FIXED: New method to get coordinates for stops
  // FIXED: New method to get coordinates for stops
  Future<List<LatLng>> _getStopCoordinates(
      List<Map<String, dynamic>> stops,
      GeocodingService geocodingService,
      ) async {
    final List<LatLng> waypoints = [];

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      LatLng? stopLatLng;

      // Try to get coordinates from existing stop data
      if (stop['lat'] != null && stop['lng'] != null) {
        stopLatLng = LatLng(
          (stop['lat'] as num).toDouble(),
          (stop['lng'] as num).toDouble(),
        );
        print('📍 Using coordinates from stop $i: $stopLatLng');
      }
      // If no coordinates, try to geocode from description
      else if (stop['description'] != null && stop['description'].toString().isNotEmpty) {
        final address = stop['description'].toString();
        stopLatLng = await geocodingService.getLatLngFromAddress(address);
        if (stopLatLng != null) {
          // Update stop with coordinates
          stops[i]['lat'] = stopLatLng.latitude;
          stops[i]['lng'] = stopLatLng.longitude;
          print('📍 Geocoded stop $i: $address -> $stopLatLng');
        } else {
          print('❌ Failed to geocode stop $i: $address');
        }
      } else {
        print('⚠️ Stop $i has no description to geocode');
      }

      if (stopLatLng != null) {
        waypoints.add(stopLatLng);
        print('✅ Added stop $i to waypoints: $stopLatLng');
      } else {
        print('⚠️ Could not get coordinates for stop $i');
      }
    }

    print('📍 Total waypoints for route: ${waypoints.length}');
    return waypoints;
  }
}