import 'dart:async';
import 'package:doorcab/feautures/rides/driver/models/request_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../utils/http/http_client.dart';
import '../../../shared/services/storage_service.dart';

class RideRequestDetailController extends GetxController {
  final Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  final Rx<Polyline?> routePolyline = Rx<Polyline?>(null);
  final markers = <Marker>{}.obs;
  var isLoading = false.obs;

  // Ride request model
  late final RequestModel request;

  final RxString passengerName = "".obs;
  final RxDouble passengerRating = 0.0.obs;
  final RxString pickupAddress = "".obs;
  final RxString dropoffAddress = "".obs;

  final RxString estimatedPickupTime = "".obs;
  final RxString estimatedDropoffTime = "".obs;
  final RxString distance = "".obs;

  final RxInt fare = 0.obs;
  final RxBool isAccepting = false.obs;

  /// Countdown for Accept button
  final RxInt offerSecondsLeft = 120.obs;
  Timer? _offerTimer;

  /// Custom offer input
  final TextEditingController offerController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    // ✅ Receive data from previous screen
    request = Get.arguments['request'] as RequestModel;

    // ✅ Bind request fields
    passengerName.value = request.passengerName;
    passengerRating.value = request.rating;
    pickupAddress.value = request.pickupAddress.address;
    dropoffAddress.value = request.dropoffAddress[0].address;
    distance.value = "${request.distanceKm.toStringAsFixed(2)} km";
    fare.value = request.offerAmount.toInt();

    estimatedPickupTime.value = "${request.etaMinutes} min";
    estimatedDropoffTime.value = "${request.etaMinutes + 15} min"; // Example only

    // ✅ Setup map route
    _setMapData();

    _startOfferCountdown();
  }

  void _setMapData() {
    // TODO: Replace with real geocoding for pickup/dropoff
    // Mock: Show marker on (31.5204, 74.3587) = Lahore
    final pickupLatLng = const LatLng(31.5204, 74.3587);
    final dropoffLatLng = const LatLng(31.4504, 74.3556);

    currentPosition.value = pickupLatLng;

    markers.add(Marker(
      markerId: const MarkerId("pickup"),
      position: pickupLatLng,
      infoWindow: const InfoWindow(title: "Pickup"),
    ));

    markers.add(Marker(
      markerId: const MarkerId("dropoff"),
      position: dropoffLatLng,
      infoWindow: const InfoWindow(title: "Dropoff"),
    ));

    routePolyline.value = Polyline(
      polylineId: const PolylineId("route"),
      color: const Color(0xFF003566),
      width: 4,
      points: [pickupLatLng, dropoffLatLng],
    );
  }

  void _startOfferCountdown() {
    _offerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (offerSecondsLeft.value > 0) {
        offerSecondsLeft.value--;
      } else {
        timer.cancel();
        Get.back(); // Auto remove request if time ends
      }
    });
  }

  void onAcceptRequest() {
    isAccepting.value = true;
    Get.snackbar("Accepted", "You accepted this ride request!");
  }

  Future<void> acceptRide(String rideId, double fareOffered) async {
    try {
      isLoading.value = true;

      // ✅ Ensure auth token is set
      final token = StorageService.getAuthToken();
      if (token == null) {
        Get.snackbar("Error", "User not authenticated. Please login again.");
        return;
      }
      FHttpHelper.setAuthToken(token, useBearer: true);


      print("rideId :"+rideId.toString());
      // ✅ Call API
      final response = await FHttpHelper.post('ride/submit-bids', {
        "rideId": rideId,
        "fareOffered": fareOffered,
      });

      print("🚀 Ride bid response: $response");

      // ✅ Show success message
      Get.snackbar("Success", "Your bid was submitted successfully!");

    } catch (e) {
      print("❌ Failed to submit bid: $e");
      Get.snackbar("Error", "Failed to submit ride bid. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  void onSubmitOffer() {
    final entered = int.tryParse(offerController.text);
    if (entered == null) {
      Get.snackbar("Invalid", "Enter a valid fare");
      return;
    }
    fare.value = entered;
    Get.back();
  }

  @override
  void onClose() {
    _offerTimer?.cancel();
    offerController.dispose();
    super.onClose();
  }
}
