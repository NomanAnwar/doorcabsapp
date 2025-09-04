import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../screens/available_bids_screen.dart';

class AvailableDriversController extends GetxController {
  final currentPosition = Rxn<LatLng>();
  final viewingDrivers = 6.obs;
  final driverAvatars = <String>[
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
  ].obs;
  final driverMarkers = <String, Marker>{}.obs;

  final fareController = TextEditingController(text: "250");
  final remainingSeconds = 20.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // Set initial position (in a real app, this would come from GPS)
    currentPosition.value = const LatLng(37.7749, -122.4194);

    // Create driver markers on map
    _createDriverMarkers();

    // Start countdown timer
    startCountdown();
  }

  void onMapCreated(GoogleMapController controller) {}

  void _createDriverMarkers() {
    // Add markers for nearby drivers (simulated)
    for (int i = 0; i < 6; i++) {
      final markerId = MarkerId('driver_$i');
      final driverPosition = LatLng(
        currentPosition.value!.latitude + (0.005 * (i - 3)),
        currentPosition.value!.longitude + (0.005 * (i % 2 == 0 ? 1 : -1)),
      );

      driverMarkers[markerId.value] = Marker(
        markerId: markerId,
        position: driverPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: "Driver ${i + 1}"),
      );
    }
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        t.cancel();
        gotoBids();
      }
    });
  }

  void adjustFare(int delta) {
    final currentFare = int.tryParse(fareController.text) ?? 0;
    final newFare = (currentFare + delta).clamp(100, 1000);
    fareController.text = newFare.toString();
  }

  void raiseFare() {
    Get.snackbar("Fare Raised", "Your new fare is PKR ${fareController.text}");
  }

  void gotoBids() {
    Get.off(() => const AvailableBidsScreen(), arguments: {
      'fare': int.tryParse(fareController.text) ?? 250,
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    fareController.dispose();
    super.onClose();
  }
}