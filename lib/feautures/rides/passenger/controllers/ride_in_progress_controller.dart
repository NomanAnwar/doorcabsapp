import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../shared/services/pusher_channels.dart';
import '../models/driver_model.dart';

class RideInProgressController extends GetxController {
  final currentPosition = Rxn<LatLng>();
  final driverMarkers = <String, Marker>{}.obs;
  final polylines = <Polyline>{}.obs; // ✅ add polyline state
  final fareController = TextEditingController();

  final driver = Rxn<DriverModel>(); // ✅ driver model from args
  GoogleMapController? _mapController;
  Timer? _autoNavTimer;
  String? _rideId;

  @override
  void onInit() {
    super.onInit();
    currentPosition.value = const LatLng(31.5204, 74.3587);

    // ✅ If arguments were passed, set driver + subscribe
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      setDriverFromArgs(args);
      if (args['rideId'] != null) {
        _rideId = args['rideId'];
        _subscribeToRideChannel(_rideId!);
      }
    }
  }

  void setDriverFromArgs(Map? args) {
    if (args != null) {
      driver.value = DriverModel.fromMap(args);
      fareController.text = driver.value!.fare.toString();
    }
  }

  void onMapCreated(GoogleMapController g) {
    _mapController = g;
  }

  void _subscribeToRideChannel(String rideId) {
    PusherChannelsService().subscribe("ride-$rideId", events: {
      "driver-location": (data) async {
        try {
          print("📨 RideInProgress driver-location: $data");

          double? lat;
          double? lng;

          if (data['lat'] != null && data['lng'] != null) {
            lat = (data['lat'] is num)
                ? (data['lat'] as num).toDouble()
                : double.tryParse(data['lat'].toString());
            lng = (data['lng'] is num)
                ? (data['lng'] as num).toDouble()
                : double.tryParse(data['lng'].toString());
          } else if (data['location'] != null) {
            final loc = data['location'];
            lat = (loc['lat'] is num)
                ? (loc['lat'] as num).toDouble()
                : double.tryParse(loc['lat'].toString());
            lng = (loc['lng'] is num)
                ? (loc['lng'] as num).toDouble()
                : double.tryParse(loc['lng'].toString());
          }

          if (lat != null && lng != null) {
            final pos = LatLng(lat, lng);
            currentPosition.value = pos;

            // ✅ update marker
            driverMarkers["driver"] = Marker(
              markerId: const MarkerId("driver"),
              position: pos,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              infoWindow: const InfoWindow(title: "Driver"),
            );
            driverMarkers.refresh();

            // ✅ draw polyline to dropoff
            if (driver.value?.dropoffLat != null && driver.value?.dropoffLng != null) {
              final dropoffPos = LatLng(driver.value!.dropoffLat!, driver.value!.dropoffLng!);
              final polyPoints = await _fetchRoutePolyline(pos, dropoffPos);
              _setPolyline(polyPoints);
              _fitMapToBounds([pos, dropoffPos]);
            }
          }
        } catch (e) {
          print("❌ RideInProgress driver-location parse error: $e");
        }
      },
      "driver-arrived": (data) {
        print("📢 RideInProgress driver-arrived: $data");
        Get.snackbar("Driver Arrived", "Driver arrived at pickup.");
      },
      "ride-started": (data) {
        print("🚦 RideInProgress ride-started: $data");
        Get.snackbar("Ride Started", "Your ride is now in progress.");
      },
      "ride-ended": (data) {
        print("🏁 RideInProgress ride-ended: $data");
        Get.offAllNamed('/rate-driver', arguments: driver.value?.toMap() ?? {});
      },
      "ride-cancelled": (data) {
        print("❌ RideInProgress ride-cancelled: $data");
        Get.offAllNamed('/ride-type');
        // Get.offAllNamed('/ride-home');
      },
    });
  }

  // ✅ Fetch route using Directions API
  Future<List<LatLng>> _fetchRoutePolyline(LatLng origin, LatLng destination) async {
    const apiKey = "AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4";
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception("Directions API failed");

    final data = jsonDecode(response.body);
    final points = data['routes'][0]['overview_polyline']['points'];
    return _decodePolyline(points);
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  void _setPolyline(List<LatLng> points) {
    final polyline = Polyline(
      polylineId: const PolylineId("driver_to_dropoff"),
      color: Colors.blue,
      width: 5,
      points: points,
    );
    polylines.value = {polyline};
  }

  Future<void> _fitMapToBounds(List<LatLng> points) async {
    if (_mapController == null || points.isEmpty) return;
    final bounds = _boundsFromLatLngList(points);
    if (bounds != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  LatLngBounds? _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) return null;
    double x0 = list.first.latitude, x1 = list.first.latitude;
    double y0 = list.first.longitude, y1 = list.first.longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  void startAutoNavigateToRating({int delaySeconds = 30}) {
    _autoNavTimer?.cancel();
    _autoNavTimer = Timer(Duration(seconds: delaySeconds), () {
      if (driver.value != null) {
        Get.offNamed('/rate-driver', arguments: driver.value!.toMap());
      } else {
        Get.offNamed('/rate-driver');
      }
    });
  }

  void cancelRide() {
    _autoNavTimer?.cancel();
    Get.offAllNamed('/ride-type');
    // Get.offAllNamed('/ride-home');
  }

  @override
  void onClose() {
    fareController.dispose();
    _autoNavTimer?.cancel();
    super.onClose();
  }
}
