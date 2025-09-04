import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import '../models/driver_model.dart';

class RideInProgressController extends GetxController {
  final currentPosition = Rxn<LatLng>();
  final driverMarkers = <String, Marker>{}.obs;

  final fareController = TextEditingController();

  // If user opens this screen with driver data
  final driver = Rxn<DriverModel>();

  // Auto navigate to rate-driver after 30 seconds
  Timer? _autoNavTimer;

  @override
  void onInit() {
    super.onInit();
    currentPosition.value = const LatLng(31.5204, 74.3587);
  }

  void setDriverFromArgs(Map? args) {
    if (args != null) {
      driver.value = DriverModel.fromMap(args);
      fareController.text = driver.value!.fare.toString();
    }
  }

  void onMapCreated(GoogleMapController g) {}

  void startAutoNavigateToRating({int delaySeconds = 30}) {
    _autoNavTimer?.cancel();
    _autoNavTimer = Timer(Duration(seconds: delaySeconds), () {
      // move to rate-driver, pass driver info
      if (driver.value != null) {
        Get.offNamed('/rate-driver', arguments: driver.value!.toMap());
      } else {
        Get.offNamed('/rate-driver');
      }
    });
  }

  void cancelRide() {
    _autoNavTimer?.cancel();
    Get.offAllNamed('/ride-home');
  }

  @override
  void onClose() {
    fareController.dispose();
    _autoNavTimer?.cancel();
    super.onClose();
  }
}
