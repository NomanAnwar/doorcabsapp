import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

class MapSelectionController extends GetxController {
  final mapCtrl = Completer<GoogleMapController>();
  final center = const LatLng(24.8607, 67.0011).obs; // fallback (Karachi)
  final address = ''.obs;
  final activeField = 'dropoff'.obs;
  final isLoading = true.obs; // 🔥 for spinner

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map?;
    activeField.value = args?['activeField'] ?? 'dropoff';
    _initUserLocation();
  }

  Future<void> _initUserLocation() async {
    try {
      // Request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          isLoading.value = false;
          return; // fallback (Karachi)
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

      // Get address immediately
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

      isLoading.value = false; // ✅ ready
    } catch (e) {
      print("Error getting user location: $e");
      isLoading.value = false;
    }
  }

  void onMapCreated(GoogleMapController c) {
    if (!mapCtrl.isCompleted) mapCtrl.complete(c);
  }

  void onCameraMove(CameraPosition pos) => center.value = pos.target;

  Future<void> onCameraIdle() async {
    try {
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
