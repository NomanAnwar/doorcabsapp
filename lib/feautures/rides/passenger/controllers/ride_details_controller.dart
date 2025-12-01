import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:doorcab/utils/http/http_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/screens/submit_complaint_screen.dart';
import '../models/ride_model.dart';

class RideDetailController extends BaseController {
  final Rx<RideModel?> rideDetails = Rx<RideModel?>(null);
  var polylines = <Polyline>{}.obs;
  var markers = <Marker>{}.obs;

  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? dropIcon;
  BitmapDescriptor? stopIcon;

  var iconsLoaded = false.obs;
  var routeLoaded = false.obs;

  // Google Maps Directions API key - ADD YOUR OWN API KEY
  final String googleMapsApiKey = 'AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4';

  @override
  void onInit() {
    super.onInit();
    _loadCustomIcons();
  }

  Future<void> _loadCustomIcons() async {
    try {
      print('🔄 Loading custom map icons...');

      // Load pickup icon
      pickupIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        "assets/images/position_marker2.png",
      );

      // Load dropoff icon
      dropIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(60, 60)),
        "assets/images/place.png",
      );

      // Load stop icon
      stopIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        "assets/images/place.png",
      );

      iconsLoaded.value = true;
      print('🎉 All custom icons loaded successfully');

    } catch (e, stackTrace) {
      print('❌ Error loading custom icons: $e');

      // Fallback to default markers
      pickupIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      dropIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      stopIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);

      iconsLoaded.value = true;
    }
  }

  GoogleMapController? _mapController;

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    print('🗺️ Google Map controller created');

    // Fit bounds after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      _fitBoundsToMarkers();
    });
  }

  void _fitBoundsToMarkers() {
    if (_mapController == null || rideDetails.value == null) {
      return;
    }

    final bounds = _calculateBounds();
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0), // Increased padding
    );
  }

  LatLngBounds _calculateBounds() {
    if (rideDetails.value == null) {
      return LatLngBounds(
        northeast: LatLng(0, 0),
        southwest: LatLng(0, 0),
      );
    }

    double minLat = rideDetails.value!.pickupLocation.lat;
    double maxLat = rideDetails.value!.pickupLocation.lat;
    double minLng = rideDetails.value!.pickupLocation.lng;
    double maxLng = rideDetails.value!.pickupLocation.lng;

    // Include all dropoff locations
    for (final dropoff in rideDetails.value!.dropoffLocations) {
      minLat = minLat < dropoff.lat ? minLat : dropoff.lat;
      maxLat = maxLat > dropoff.lat ? maxLat : dropoff.lat;
      minLng = minLng < dropoff.lng ? minLng : dropoff.lng;
      maxLng = maxLng > dropoff.lng ? maxLng : dropoff.lng;
    }

    // Add generous padding
    double latPadding = (maxLat - minLat) * 0.2;
    double lngPadding = (maxLng - minLng) * 0.2;

    // Ensure minimum padding
    if (latPadding < 0.01) latPadding = 0.01;
    if (lngPadding < 0.01) lngPadding = 0.01;

    return LatLngBounds(
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
    );
  }

  void getRideDetails(RideModel ride) {
    rideDetails.value = ride;
    print('🚗 Ride details set for route calculation');

    if (iconsLoaded.value) {
      _updateMapWithRoute();
    } else {
      ever(iconsLoaded, (loaded) {
        if (loaded) {
          _updateMapWithRoute();
        }
      });
    }
  }
  void _updateMapWithRoute() {
    if (rideDetails.value == null) {
      return;
    }

    print('🗺️ Starting map update with route calculation...');
    _updateMarkers();
    _calculateRoute();
  }

  void _updateMarkers() {
    if (rideDetails.value == null) return;

    markers.clear();

    // Pickup marker
    final pickupLatLng = LatLng(
      rideDetails.value!.pickupLocation.lat,
      rideDetails.value!.pickupLocation.lng,
    );

    markers.add(
      Marker(
        markerId: const MarkerId("pickup"),
        position: pickupLatLng,
        icon: pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: "Pickup",
          snippet: rideDetails.value!.location,
        ),
      ),
    );

    // Dropoff markers
    if (rideDetails.value!.dropoffLocations.isNotEmpty) {
      for (int i = 0; i < rideDetails.value!.dropoffLocations.length; i++) {
        final dropoff = rideDetails.value!.dropoffLocations[i];
        final dropoffLatLng = LatLng(dropoff.lat, dropoff.lng);

        final bool isFinalDropoff = i == rideDetails.value!.dropoffLocations.length - 1;

        markers.add(
          Marker(
            markerId: MarkerId("dropoff_$i"),
            position: dropoffLatLng,
            icon: isFinalDropoff
                ? (dropIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed))
                : (stopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)),
            infoWindow: InfoWindow(
              title: isFinalDropoff ? "Dropoff" : "Stop ${i + 1}",
              snippet: dropoff.address,
            ),
          ),
        );
      }
    }

    markers.refresh();
  }

  // FIXED: Calculate actual route using Directions API
  Future<void> _calculateRoute() async {
    if (rideDetails.value == null) return;

    try {
      routeLoaded.value = false;
      print('🔄 Starting route calculation...');

      // Check if we have valid coordinates
      if (rideDetails.value!.pickupLocation.lat == 0.0 ||
          rideDetails.value!.pickupLocation.lng == 0.0) {
        print('❌ Invalid pickup coordinates');
        _createStraightLinePolyline();
        return;
      }

      if (rideDetails.value!.dropoffLocations.isEmpty) {
        print('❌ No dropoff locations available');
        _createStraightLinePolyline();
        return;
      }

      final List<LatLng> waypoints = [];

      // Add intermediate stops as waypoints (all except the last one)
      if (rideDetails.value!.dropoffLocations.length > 1) {
        for (int i = 0; i < rideDetails.value!.dropoffLocations.length - 1; i++) {
          final dropoff = rideDetails.value!.dropoffLocations[i];
          if (dropoff.lat != 0.0 && dropoff.lng != 0.0) {
            waypoints.add(LatLng(dropoff.lat, dropoff.lng));
          }
        }
      }

      final LatLng origin = LatLng(
        rideDetails.value!.pickupLocation.lat,
        rideDetails.value!.pickupLocation.lng,
      );

      final LatLng destination = LatLng(
        rideDetails.value!.dropoffLocations.last.lat,
        rideDetails.value!.dropoffLocations.last.lng,
      );

      print('📍 Route from: $origin to: $destination');
      print('📍 Waypoints: ${waypoints.length}');

      final List<LatLng> routePoints = await _getRouteFromDirectionsAPI(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
      );

      if (routePoints.isNotEmpty && routePoints.length >= 2) {
        _updatePolylinesWithRoute(routePoints);
        routeLoaded.value = true;
        print('✅ Route calculated successfully with ${routePoints.length} points');

        // Fit bounds after route is calculated
        Future.delayed(const Duration(milliseconds: 1000), () {
          _fitBoundsToMarkers();
        });
      } else {
        print('⚠️ No route points returned, using straight line');
        _createStraightLinePolyline();
        routeLoaded.value = true;
      }

    } catch (e, stackTrace) {
      print('❌ Error calculating route: $e');
      print('Stack trace: $stackTrace');
      _createStraightLinePolyline();
      routeLoaded.value = true;
    }
  }

  // FIXED: Improved Directions API call
  Future<List<LatLng>> _getRouteFromDirectionsAPI({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> waypoints = const [],
  }) async {
    try {
      // Validate coordinates
      if (origin.latitude == 0.0 || origin.longitude == 0.0 ||
          destination.latitude == 0.0 || destination.longitude == 0.0) {
        print('❌ Invalid coordinates for Directions API');
        return [];
      }

      // Construct waypoints parameter
      String waypointsParam = '';
      if (waypoints.isNotEmpty) {
        final validWaypoints = waypoints.where((wp) => wp.latitude != 0.0 && wp.longitude != 0.0);
        if (validWaypoints.isNotEmpty) {
          waypointsParam = '&waypoints=${validWaypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|')}';
          print('📍 Valid waypoints: ${validWaypoints.length}');
        }
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${origin.latitude},${origin.longitude}'
            '&destination=${destination.latitude},${destination.longitude}'
            '$waypointsParam'
            '&mode=driving'  // Added mode parameter
            '&key=$googleMapsApiKey',
      );

      print('🌐 Calling Directions API...');
      print('URL: ${url.toString().replaceAll(googleMapsApiKey, 'HIDDEN')}');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('📡 API Response status: ${data['status']}');

        if (data['status'] == 'OK') {
          final List<LatLng> points = [];
          final List<dynamic> routes = data['routes'];

          for (final route in routes) {
            final List<dynamic> legs = route['legs'];
            for (final leg in legs) {
              final List<dynamic> steps = leg['steps'];
              for (final step in steps) {
                final String polyline = step['polyline']['points'];
                final List<LatLng> decoded = _decodePolyline(polyline);
                points.addAll(decoded);
              }
            }
          }

          print('📍 Decoded ${points.length} route points');
          return points;
        } else {
          print('❌ Directions API error: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
          return [];
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Directions API call failed: $e');
      return [];
    }
  }

  // FIXED: Improved polyline decoding
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      // Decode latitude
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  void _updatePolylinesWithRoute(List<LatLng> routePoints) {
    polylines.clear();

    if (routePoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: routePoints,
          color: FColors.secondaryColor,
          width: 6, // Slightly thicker for better visibility
          geodesic: false, // Important: false for road routes
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
      print('✅ Route polyline created with ${routePoints.length} points');
    } else {
      print('⚠️ Not enough route points to create polyline');
    }
  }

  // Fallback method - straight line between points
  void _createStraightLinePolyline() {
    if (rideDetails.value == null) return;

    polylines.clear();
    final points = <LatLng>[];

    // Start from pickup
    points.add(LatLng(
      rideDetails.value!.pickupLocation.lat,
      rideDetails.value!.pickupLocation.lng,
    ));

    // Add all dropoff locations
    for (final dropoff in rideDetails.value!.dropoffLocations) {
      if (dropoff.lat != 0.0 && dropoff.lng != 0.0) {
        points.add(LatLng(dropoff.lat, dropoff.lng));
      }
    }

    if (points.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: points,
          color: FColors.secondaryColor.withOpacity(0.6),
          width: 3,
          geodesic: true,
        ),
      );
      print('⚠️ Straight line polyline created with ${points.length} points');
    }
  }


  Future<void> sendRideReport() async {
    try {
      if (rideDetails.value == null) {
        showError('No ride details available');
        return;
      }

      // Get user profile for email
      final profile = StorageService.getProfile();
      if (profile == null || profile['email'] == null) {
        showError('Email not found in profile');
        return;
      }

      final email = profile['email'] as String;
      final ride = rideDetails.value!;

      if(email.isEmpty) {
        FSnackbar.show(title: "Email Not Found", message: 'Please add email to your profile first.', isError: true);
        return;
      }

      // Prepare request body
      final requestBody = {
        "email": email,
        "rideId": ride.id,
        "pickup": ride.location,
        "dropoff": ride.firstDropoffAddress,
        "fare": ride.totalFare,
      };

      // Make API call
      await executeWithRetry(() async {
        final response = await FHttpHelper.post(
          'email/send-ride',
          requestBody,
        );

        if (response['message'] == "Ride information sent successfully") {
          FSnackbar.show(title: "Email Sent Successfully", message: 'Ride report sent successfully to $email');
        } else {
          throw Exception('Failed to send ride report');
        }
      });

    } catch (e) {
      print('Error sending ride report: $e');
      showError('Failed to send ride report: ${e.toString()}');
    }
  }

  // Get other user info based on role
  Map<String, dynamic> getOtherUserInfo() {
    final ride = rideDetails.value;
    if (ride == null) return {};

    // final role = StorageService.getRole();

    // Use the new smart getters from the unified model
    return {
      'name': ride.displayName,
      'profileImage': ride.displayProfileImage,
      'role': ride.displayRole,
      'vehicle': ride.vehicleType,
      'rating': (ride.displayRole == " Driver" || ride.displayRole == "driver") ? ride.driverRating : ride.passengerRating,
      'total_rides': (ride.displayRole == " Driver" || ride.displayRole == "driver") ? ride.driverTotalRatings : ride.passengerTotalRides,
      'license_plate': ride.vehicleModel,
    };
  }

  // 🎯 NEW: Get current user's role for UI logic
  String getCurrentUserRole() {
    return StorageService.getRole()?.toLowerCase() ?? 'passenger';
  }

  // 🎯 NEW: Check if current user is driver
  bool get isCurrentUserDriver {
    return getCurrentUserRole() == 'driver';
  }

  // 🎯 NEW: Check if current user is passenger
  bool get isCurrentUserPassenger {
    return getCurrentUserRole() == 'passenger';
  }

  // String getFormattedArrivalTime() {
  //   final ride = rideDetails.value;
  //   if (ride == null || ride.estimatedArrivalTime == null) return 'N/A';
  //
  //   return '${ride.estimatedArrivalTime} min';
  // }

  String getFormattedArrivalTime() {
    final ride = rideDetails.value;
    if (ride == null || ride.rideStartTime == null) return 'N/A';

    final hour = ride.rideStartTime!.hour % 12 == 0 ? 12 : ride.rideStartTime!.hour % 12;
    final period = ride.rideStartTime!.hour < 12 ? 'AM' : 'PM';
    final minute = ride.rideStartTime!.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";

    // return '${ride.estimatedArrivalTime} min';
  }

  // Format drop time
  String getFormattedDropTime() {
    final ride = rideDetails.value;
    if (ride == null || ride.rideEndTime == null) return 'N/A';

    final hour = ride.rideEndTime!.hour % 12 == 0 ? 12 : ride.rideEndTime!.hour % 12;
    final period = ride.rideEndTime!.hour < 12 ? 'AM' : 'PM';
    final minute = ride.rideEndTime!.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  // Add this method to your RideDetailController class
  void navigateToSubmitComplaint() {
    try {
      final ride = rideDetails.value;
      if (ride == null) {
        FSnackbar.show(title: "Error", message: "Ride details not available", isError: true);
        return;
      }

      // Prepare arguments for complaint screen
      final arguments = {
        'rideId': ride.id,
        'driverId': ride.isDriverRole ? null : ride.driverInfo?.id, // Only if passenger is complaining against driver
        'passengerId': ride.isDriverRole ? ride.passengerId : null, // Only if driver is complaining against passenger
        'complaintForId': ride.isDriverRole ? ride.passengerId : ride.driverInfo?.id, // ID of person being complained against
        'details': ride, // ID of person being complained against
        'name': ride.displayName,
        'profileImage': ride.displayProfileImage,
        'rating': (ride.displayRole == " Driver" || ride.displayRole == "driver") ? ride.driverRating : ride.passengerRating,
        'total_rides': (ride.displayRole == " Driver" || ride.displayRole == "driver") ? ride.driverTotalRatings : ride.passengerTotalRides,
      };


      final rideargs = Get.arguments;
      print('🚀 Navigating to SubmitComplaintScreen with arguments: $arguments');
      print('🚀 Navigating to SubmitComplaintScreen with arguments: $rideargs');



      Get.to(() => const SubmitComplaintScreen(), arguments: arguments);

    } catch (e) {
      print('❌ Error navigating to complaint screen: $e');
      FSnackbar.show(
          title: "Error",
          message: "Failed to open complaint form",
          isError: true
      );
    }
  }

  bool get shouldShowComplaintButton {
    final ride = rideDetails.value;
    if (ride == null) return false;

    final currentUserId = StorageService.getSignUpResponse()?.userId;
    if (currentUserId == null) return false;

    // Get the complaintForId based on role
    final complaintForId = ride.isDriverRole ? ride.passengerId : ride.driverInfo?.id;

    // Check conditions for showing complaint button
    return complaintForId != null &&
        complaintForId.isNotEmpty &&
        complaintForId != currentUserId;
  }
}