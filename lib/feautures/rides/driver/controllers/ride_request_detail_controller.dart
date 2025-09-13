import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideRequestDetailController extends GetxController {
  final Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  final Rx<Polyline?> routePolyline = Rx<Polyline?>(null);
  final markers = <Marker>{}.obs;

  final RxString passengerName = "John Doe".obs;
  final RxDouble passengerRating = 4.98.obs;
  final RxString pickupAddress = "123 Model Town, Lahore".obs;
  final RxString dropoffAddress = "Liberty Market, Lahore".obs;

  final RxString estimatedPickupTime = "5 min".obs;
  final RxString estimatedDropoffTime = "20 min".obs;
  final RxString distance = "12 km".obs;

  final RxInt fare = 250.obs;
  final RxBool isAccepting = false.obs;

  // Offer button countdown
  final RxInt offerSecondsLeft = 10.obs;
  Timer? _offerTimer;

  // For custom offer amount field
  final TextEditingController offerController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _startOfferCountdown();
  }

  void _startOfferCountdown() {
    _offerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (offerSecondsLeft.value > 0) {
        offerSecondsLeft.value--;
      } else {
        timer.cancel();
        Get.back(); // Auto remove request
      }
    });
  }

  void onAcceptRequest() {
    isAccepting.value = true;
    // TODO: Call API to accept request
    Get.snackbar("Accepted", "You accepted this ride request!");
  }

  void onSubmitOffer() {
    final entered = int.tryParse(offerController.text);
    if (entered == null) {
      Get.snackbar("Invalid", "Enter a valid fare");
      return;
    }
    fare.value = entered;
    Get.back(); // Go back to list after submitting
  }

  @override
  void onClose() {
    _offerTimer?.cancel();
    offerController.dispose();
    super.onClose();
  }
}
