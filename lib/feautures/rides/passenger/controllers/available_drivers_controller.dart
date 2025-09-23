import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/http/http_client.dart';
import '../screens/available_bids_screen.dart';

class AvailableDriversController extends GetxController {
  final currentPosition = Rxn<LatLng>();
  final viewingDrivers = 0.obs;
  final driverAvatars = <String>[].obs;
  final driverMarkers = <String, Marker>{}.obs;

  final fareController = TextEditingController(text: "250");
  final remainingSeconds = 60.obs;
  Timer? _timer;

  final bids = <Map<String, dynamic>>[].obs;

  late final Map<String, dynamic> rideArgs;

  @override
  void onInit() {
    super.onInit();

    // ✅ pickup lat/lng passed as arguments from RideRequestController
    final args = Get.arguments;
    rideArgs = Map<String, dynamic>.from(args ?? {});

    if (args != null) {
      // Pickup position
      if (args['pickupLat'] != null && args['pickupLng'] != null) {
        currentPosition.value = LatLng(
          (args['pickupLat'] as num).toDouble(),
          (args['pickupLng'] as num).toDouble(),
        );

        fetchNearbyDrivers(currentPosition.value!);
      }

      // ✅ Store bids observable
      final argBids = args['bids'];
      if (argBids != null && argBids is RxList<Map<String, dynamic>>) {
        ever(argBids, (_) {
          if (argBids.isNotEmpty) {
            bids.assignAll(argBids);
            _goToBids(args); // pass args forward
          }
        });
      }
    }

    startCountdown();
  }

  void onMapCreated(GoogleMapController controller) {}

  /// 🔥 Call backend to fetch nearby drivers
  Future<void> fetchNearbyDrivers(LatLng pickupCoords) async {
    try {
      final body = {
        "lat": pickupCoords.latitude,
        "lng": pickupCoords.longitude,
      };

      final response = await FHttpHelper.post("ride/get-nearby-drivers", body);

      print("Fetch Drivers API Response : " + response.toString());

      if (response != null && response["drivers"] != null) {
        final drivers = response["drivers"] as List;
        viewingDrivers.value = drivers.length;

        driverMarkers.clear();
        driverAvatars.clear();

        // 🔴 Add pickup marker first
        driverMarkers["pickup"] = Marker(
          markerId: const MarkerId("pickup"),
          position: pickupCoords,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "Pickup Location"),
        );

        // 🔵 Add all drivers
        for (var driver in drivers) {
          final driverId =
              driver["driverId"]?.toString() ?? UniqueKey().toString();
          final loc = driver["location"];
          if (loc == null) continue;

          final latRaw = loc["lat"];
          final lngRaw = loc["lng"];
          if (latRaw == null || lngRaw == null) continue;

          final lat = (latRaw is num)
              ? latRaw.toDouble()
              : double.tryParse(latRaw.toString());
          final lng = (lngRaw is num)
              ? lngRaw.toDouble()
              : double.tryParse(lngRaw.toString());
          if (lat == null || lng == null) continue;

          final markerId = MarkerId("driver_$driverId");
          final driverPosition = LatLng(lat, lng);

          driverMarkers[driverId] = Marker(
            markerId: markerId,
            position: driverPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure), // secondary color
            infoWindow: InfoWindow(title: "Driver $driverId"),
          );

          // Placeholder avatar (replace with API avatar if available)
          driverAvatars.add("assets/images/profile_img_sample.png");
        }
      }
    } catch (e) {
      print("❌ Error fetching drivers: $e");
    }
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        t.cancel();
        _goToBids(rideArgs);
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

  void _goToBids(Map<String, dynamic> parentArgs) {
    if (bids.isEmpty) return;

    Get.off(() => const AvailableBidsScreen(), arguments: {
      ...parentArgs, // pass everything received from RideRequestController
      'fare': int.tryParse(fareController.text) ?? 250,
      'bids': bids, // updated bids
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    fareController.dispose();
    super.onClose();
  }
}
