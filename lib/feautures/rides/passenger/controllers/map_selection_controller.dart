import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import '../../../shared/controllers/base_controller.dart'; // ✅ ADDED

class MapSelectionController extends BaseController { // ✅ CHANGED: Extend BaseController
  final mapCtrl = Completer<GoogleMapController>();

  // ✅ Fix: start with a dummy point (0,0) and update once location is ready
  final center = const LatLng(0, 0).obs;

  final address = ''.obs;
  final activeField = 'dropoff'.obs;
  final isLoadingLocation = false.obs; // 🔥 for spinner

  BitmapDescriptor? _markerIcon;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map?;
    activeField.value = args?['activeField'] ?? 'dropoff';
    _initUserLocation();
    _loadMarkerIcon(); // ✅ preload marker
  }

  // ✅ marker loader (same as RideHomeScreen)
  Future<void> _loadMarkerIcon() async {
    try {
      await executeWithRetry(() async {
        final data = await rootBundle.load("assets/images/position_marker.png");
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: 100, // adjust size as needed
        );
        final fi = await codec.getNextFrame();
        final bytes = await fi.image.toByteData(format: ui.ImageByteFormat.png);
        _markerIcon = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
      });
    } catch (e) {
      print('❌ Error loading marker icon: $e');
      _markerIcon = BitmapDescriptor.defaultMarker;
    }
  }

  BitmapDescriptor get markerIcon =>
      _markerIcon ?? BitmapDescriptor.defaultMarker;

  // ✅ method to recenter to user's location
  Future<void> recenter() async {
    try {
      await executeWithRetry(() async {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final userLatLng = LatLng(pos.latitude, pos.longitude);
        center.value = userLatLng;

        if (mapCtrl.isCompleted) {
          final ctrl = await mapCtrl.future;
          ctrl.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 15));
        }
      });
    } catch (e) {
      print("Error recentering: $e");
      showError('Failed to get current location');
    }
  }

  Future<void> _initUserLocation() async {
    try {
      isLoadingLocation(true);

      await executeWithRetry(() async {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            // ✅ Fix: fallback to Karachi only if denied
            center.value = const LatLng(24.8607, 67.0011);
            isLoadingLocation.value = false;
            return;
          }
        }

        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final userLatLng = LatLng(pos.latitude, pos.longitude);

        center.value = userLatLng;

        if (mapCtrl.isCompleted) {
          final controller = await mapCtrl.future;
          controller.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 15));
        }

        final placemarks = await geo.placemarkFromCoordinates(
          userLatLng.latitude,
          userLatLng.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final name = [p.name, p.locality, p.administrativeArea]
              .where((e) => (e ?? '').toString().trim().isNotEmpty)
              .join(', ');
          address.value = name.isEmpty ? "Selected location" : name;
        }
      });
    } catch (e) {
      print("Error getting user location: $e");
      showError('Failed to get your location');

      // ✅ fallback to Karachi if error
      center.value = const LatLng(24.8607, 67.0011);
    } finally {
      isLoadingLocation.value = false;
    }
  }

  void onMapCreated(GoogleMapController c) {
    if (!mapCtrl.isCompleted) mapCtrl.complete(c);
  }

  void onCameraMove(CameraPosition pos) => center.value = pos.target;

  Future<void> onCameraIdle() async {
    try {
      await executeWithRetry(() async {
        final placemarks = await geo.placemarkFromCoordinates(
          center.value.latitude,
          center.value.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final name = [p.name, p.locality, p.administrativeArea]
              .where((e) => (e ?? '').toString().trim().isNotEmpty)
              .join(', ');
          address.value = name.isEmpty ? "Selected location" : name;
        } else {
          address.value = "Selected location";
        }
      });
    } catch (_) {
      address.value = "Selected location";
    }
  }

  void confirm() {
    Get.back(result: {
      'field': activeField.value,
      'lat': center.value.latitude,
      'lng': center.value.longitude,
      'address': address.value,
    });
  }
}