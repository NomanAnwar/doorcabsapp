// lib/feautures/rides/controllers/drivers_waiting_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class DriversWaitingController extends GetxController {
  final currentPosition = Rxn<LatLng>();
  final driverMarkers = <String, Marker>{}.obs;
  final fareController = TextEditingController();

  Timer? _waitingTimer;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>;
    final bid = args['bid'];
    final driverResponse = args; // contains both response + bid

    // Mock current position
    currentPosition.value = const LatLng(31.5204, 74.3587);

    // Auto move after 20 seconds → RideInProgress
    _waitingTimer = Timer(const Duration(seconds: 30), () {
      Get.toNamed('/ride-in-progress');
    });
  }

  void onMapCreated(GoogleMapController c) {}

  void cancelRide() {
    _waitingTimer?.cancel();
    Get.offAllNamed('/ride-home');
  }

  @override
  void onClose() {
    _waitingTimer?.cancel();
    fareController.dispose();
    super.onClose();
  }
}
