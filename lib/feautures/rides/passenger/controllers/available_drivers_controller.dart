import 'dart:async';
import 'dart:typed_data' show ByteData;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/storage_service.dart';
import '../screens/available_bids_screen.dart';

class AvailableDriversController extends BaseController {
  final currentPosition = Rxn<LatLng>();
  final viewingDrivers = 0.obs;
  final driverAvatars = <String>[].obs;
  final driverMarkers = <String, Marker>{}.obs;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final fareController = TextEditingController();
  final remainingSeconds = 60.obs;
  Timer? _timer;

  final bids = <Map<String, dynamic>>[].obs;

  late final Map<String, dynamic> rideArgs;

  /// Custom marker icon for drivers
  late BitmapDescriptor customDriverIcon;
  late BitmapDescriptor customPickupIcon;

  int initialMinimumFare = 0;

  // ✅ ADDED: New observables for button states and loading
  final isRaisingFare = false.obs;
  final maxFareLimit = 0.obs;

  // ✅ FIXED: Use observable variables instead of getters
  final isDecrementDisabled = false.obs;
  final isIncrementDisabled = false.obs;
  final isRaiseFareDisabled = false.obs;

  @override
  void onInit() async {
    super.onInit();

    // ✅ UPDATED: Load custom marker with retry
    await _loadCustomMarkerWithRetry();

    // ✅ pickup lat/lng passed as arguments from RideRequestController
    final args = Get.arguments;
    rideArgs = Map<String, dynamic>.from(args ?? {});

    if (args != null) {
      if (args['fare'] != null) {
        final fare = args['fare'].toString();

        // ✅ FIXED: Handle double fare values like "190.0"
        try {
          // Parse as double first to handle "190.0" case
          final doubleFare = double.tryParse(fare);
          if (doubleFare != null) {
            initialMinimumFare = doubleFare.round(); // Convert to int
            fareController.text = initialMinimumFare.toString(); // Set as integer string
            // ✅ ADDED: Set max fare limit to double the initial fare
            maxFareLimit.value = initialMinimumFare * 2;
            print('💰 Initial fare from args: $fare -> parsed as: $initialMinimumFare, Max fare limit: ${maxFareLimit.value}');
          } else {
            // Fallback to integer parsing
            initialMinimumFare = int.tryParse(fare) ?? 0;
            fareController.text = initialMinimumFare.toString();
            maxFareLimit.value = initialMinimumFare * 2;
            print('💰 Initial fare from args: $fare -> parsed as: $initialMinimumFare, Max fare limit: ${maxFareLimit.value}');
          }
        } catch (e) {
          // Final fallback
          initialMinimumFare = 0;
          fareController.text = "0";
          maxFareLimit.value = 0;
          print('❌ Error parsing fare, using default: 0');
        }
      } else {
        // ✅ FIXED: Use proper number instead of "000"
        initialMinimumFare = 0;
        fareController.text = "0";
        maxFareLimit.value = 0;
        print('⚠️ No fare in args, using default: 0');
      }

      // Pickup position
      if (args['pickupLat'] != null && args['pickupLng'] != null) {
        currentPosition.value = LatLng(
          (args['pickupLat'] as num).toDouble(),
          (args['pickupLng'] as num).toDouble(),
        );

        await _fetchNearbyDriversWithRetry(currentPosition.value!);
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

    // ✅ ADDED: Listen to fare controller changes to update button states
    fareController.addListener(_updateButtonStates);
    _updateButtonStates(); // Initial update

    startCountdown();
  }

  // ✅ ADDED: Method to update button states
  void _updateButtonStates() {
    final currentFare = _parseFareText(fareController.text);

    isDecrementDisabled.value = currentFare <= initialMinimumFare;
    isIncrementDisabled.value = currentFare >= maxFareLimit.value;
    isRaiseFareDisabled.value = currentFare <= initialMinimumFare || isRaisingFare.value;
  }

  void onMapCreated(GoogleMapController controller) {}

  /// ✅ UPDATED: Load custom marker from assets with retry
  Future<void> _loadCustomMarkerWithRetry() async {
    try {
      await executeWithRetry(() async {
        // ---- DRIVER ICON ----
        final ByteData driverData = await rootBundle.load('assets/images/car.png');
        final Uint8List driverBytes = driverData.buffer.asUint8List();
        final Codec driverCodec = await instantiateImageCodec(driverBytes, targetWidth: 100);
        final FrameInfo driverFrame = await driverCodec.getNextFrame();
        final ByteData? driverResized = await driverFrame.image.toByteData(format: ImageByteFormat.png);
        customDriverIcon = BitmapDescriptor.fromBytes(driverResized!.buffer.asUint8List());

        // ---- PICKUP ICON ----
        final ByteData pickupData = await rootBundle.load('assets/images/place.png');
        final Uint8List pickupBytes = pickupData.buffer.asUint8List();
        final Codec pickupCodec = await instantiateImageCodec(pickupBytes, targetWidth: 90);
        final FrameInfo pickupFrame = await pickupCodec.getNextFrame();
        final ByteData? pickupResized = await pickupFrame.image.toByteData(format: ImageByteFormat.png);
        customPickupIcon = BitmapDescriptor.fromBytes(pickupResized!.buffer.asUint8List());

        print('✅ Custom markers loaded successfully');
      }, maxRetries: 2);
    } catch (e) {
      print('❌ Error loading custom markers: $e');
      // Fallbacks
      customDriverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      customPickupIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  /// ✅ UPDATED: Call backend to fetch nearby drivers with retry
  Future<void> _fetchNearbyDriversWithRetry(LatLng pickupCoords) async {
    try {
      await executeWithRetry(() async {
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
            icon: customPickupIcon,
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
              icon: customDriverIcon, // ✅ use custom marker here
              infoWindow: InfoWindow(title: "Driver $driverId"),
            );

            // Placeholder avatar (replace with API avatar if available)
            driverAvatars.add("assets/images/profile_img_sample.png");
          }
        }
      }, maxRetries: 2);
    } catch (e) {
      print("❌ Error fetching drivers after retries: $e");
      showError("Failed to fetch nearby drivers");
    }
  }

  // ✅ EXISTING: Your original methods (unchanged)
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

  // ✅ FIXED: Proper fare adjustment with button state updates
  void adjustFare(int delta) {
    final currentFare = _parseFareText(fareController.text);
    int newFare = currentFare + delta;

    // These checks should now be redundant due to button disabling, but keep for safety
    if (delta < 0 && newFare < initialMinimumFare) {
      return;
    }
    if (delta > 0 && newFare > maxFareLimit.value) {
      return;
    }

    fareController.text = newFare.toString();
    _updateButtonStates(); // ✅ Update button states after fare change

    if (delta > 0) {
      print('➕ Fare increased from PKR $currentFare to: PKR $newFare');
    } else {
      print('➖ Fare decreased from PKR $currentFare to: PKR $newFare');
    }
  }

  // ✅ ADDED: Robust fare text parsing helper
  int _parseFareText(String fareText) {
    if (fareText.isEmpty) return initialMinimumFare;

    // First try to parse as double (handles "190.0" case)
    final doubleFare = double.tryParse(fareText);
    if (doubleFare != null) {
      return doubleFare.round();
    }

    // Then try to parse as integer
    return int.tryParse(fareText) ?? initialMinimumFare;
  }

  // ✅ UPDATED: Raise fare with loading state and button disabling
  Future<void> raiseFare() async {
    final currentFare = _parseFareText(fareController.text);

    // Check if button should be disabled (redundant but safe)
    if (currentFare <= initialMinimumFare) {
      return;
    }

    isRaisingFare.value = true;
    _updateButtonStates(); // ✅ Update button states when raising starts

    try {
      final args = Get.arguments;
      final token = StorageService.getAuthToken();

      if (token == null) {
        throw Exception("User token not found. Please login again.");
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      final raiseFareBody = {
        "rideId": args['rideId'],
        "newFare": currentFare,
      };

      final response = await FHttpHelper.post('ride/raise-fare', raiseFareBody);
      debugPrint("  Raise Fare API Response : $response");

      showSuccess("Your new fare is PKR ${fareController.text}");
    } catch (e) {
      showError("Failed to raise fare: ${e.toString()}");
    } finally {
      isRaisingFare.value = false;
      _updateButtonStates(); // ✅ Update button states when raising ends
    }
  }

  void _goToBids(Map<String, dynamic> parentArgs) {
    if (bids.isEmpty) return;

    // ✅ FIXED: Use the same parsing logic for navigation
    final fareValue = _parseFareText(fareController.text);

    Get.off(() => const AvailableBidsScreen(), arguments: {
      ...parentArgs, // pass everything received from RideRequestController
      'fare': fareValue,
      'bids': bids, // updated bids
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    fareController.removeListener(_updateButtonStates); // ✅ Remove listener
    fareController.dispose();
    super.onClose();
  }
}

// import 'dart:async';
// import 'dart:typed_data' show ByteData;
// import 'dart:ui';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../../../../utils/http/http_client.dart';
// import '../screens/available_bids_screen.dart';
//
// class AvailableDriversController extends GetxController {
//   final currentPosition = Rxn<LatLng>();
//   final viewingDrivers = 0.obs;
//   final driverAvatars = <String>[].obs;
//   final driverMarkers = <String, Marker>{}.obs;
//
//   final fareController = TextEditingController();
//   final remainingSeconds = 60.obs;
//   Timer? _timer;
//
//   final bids = <Map<String, dynamic>>[].obs;
//
//   late final Map<String, dynamic> rideArgs;
//
//   /// Custom marker icon for drivers
//   late BitmapDescriptor customDriverIcon;
//
//   int initialMinimumFare = 0;
//
//   @override
//   void onInit() async {
//     super.onInit();
//
//     // ✅ load custom marker before adding drivers
//     await _loadCustomMarker();
//
//     // ✅ pickup lat/lng passed as arguments from RideRequestController
//     final args = Get.arguments;
//     rideArgs = Map<String, dynamic>.from(args ?? {});
//
//     if (args != null) {
//
//       if (args['fare'] != null) {
//         final fare = args['fare'].toString();
//         fareController.text = fare;
//         initialMinimumFare = int.tryParse(fare) ?? 0;
//         print('💰 Initial fare from args: $fare');
//       } else {
//         // Fallback if no fare in args
//         fareController.text = "000";
//         initialMinimumFare = 000;
//         print('⚠️ No fare in args, using default: 250');
//       }
//
//       // Pickup position
//       if (args['pickupLat'] != null && args['pickupLng'] != null) {
//         currentPosition.value = LatLng(
//           (args['pickupLat'] as num).toDouble(),
//           (args['pickupLng'] as num).toDouble(),
//         );
//
//         fetchNearbyDrivers(currentPosition.value!);
//       }
//
//       // ✅ Store bids observable
//       final argBids = args['bids'];
//       if (argBids != null && argBids is RxList<Map<String, dynamic>>) {
//         ever(argBids, (_) {
//           if (argBids.isNotEmpty) {
//             bids.assignAll(argBids);
//             _goToBids(args); // pass args forward
//           }
//         });
//       }
//     }
//
//     startCountdown();
//   }
//
//   void onMapCreated(GoogleMapController controller) {}
//
//   /// Load custom marker from assets
//   // Future<void> _loadCustomMarker() async {
//   //   customDriverIcon = await BitmapDescriptor.fromAssetImage(
//   //     const ImageConfiguration(size: Size(120, 120)), // Adjust size if needed
//   //     "assets/images/car.png",
//   //   );
//   // }
//
//   /// Load custom marker from assets with proper sizing
//   Future<void> _loadCustomMarker() async {
//     try {
//       // ✅ METHOD 1: Load and resize the image properly
//       final ByteData data = await rootBundle.load('assets/images/car.png');
//       final Uint8List bytes = data.buffer.asUint8List();
//
//       // Resize the image to desired dimensions
//       final Codec codec = await instantiateImageCodec(bytes, targetWidth: 100); // Adjust width as needed
//       final FrameInfo frame = await codec.getNextFrame();
//       final ByteData? resizedByteData = await frame.image.toByteData(
//         format: ImageByteFormat.png,
//       );
//
//       final Uint8List resizedBytes = resizedByteData!.buffer.asUint8List();
//
//       customDriverIcon = BitmapDescriptor.fromBytes(resizedBytes);
//
//       print('✅ Custom driver marker loaded with size 80px');
//     } catch (e) {
//       print('❌ Error loading custom marker: $e');
//       // Fallback to default marker
//       customDriverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
//     }
//   }
//
//   /// 🔥 Call backend to fetch nearby drivers
//   Future<void> fetchNearbyDrivers(LatLng pickupCoords) async {
//     try {
//       final body = {
//         "lat": pickupCoords.latitude,
//         "lng": pickupCoords.longitude,
//       };
//
//       final response = await FHttpHelper.post("ride/get-nearby-drivers", body);
//
//       print("Fetch Drivers API Response : " + response.toString());
//
//       if (response != null && response["drivers"] != null) {
//         final drivers = response["drivers"] as List;
//         viewingDrivers.value = drivers.length;
//
//         driverMarkers.clear();
//         driverAvatars.clear();
//
//         // 🔴 Add pickup marker first
//         driverMarkers["pickup"] = Marker(
//           markerId: const MarkerId("pickup"),
//           position: pickupCoords,
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//           infoWindow: const InfoWindow(title: "Pickup Location"),
//         );
//
//         // 🔵 Add all drivers
//         for (var driver in drivers) {
//           final driverId =
//               driver["driverId"]?.toString() ?? UniqueKey().toString();
//           final loc = driver["location"];
//           if (loc == null) continue;
//
//           final latRaw = loc["lat"];
//           final lngRaw = loc["lng"];
//           if (latRaw == null || lngRaw == null) continue;
//
//           final lat = (latRaw is num)
//               ? latRaw.toDouble()
//               : double.tryParse(latRaw.toString());
//           final lng = (lngRaw is num)
//               ? lngRaw.toDouble()
//               : double.tryParse(lngRaw.toString());
//           if (lat == null || lng == null) continue;
//
//           final markerId = MarkerId("driver_$driverId");
//           final driverPosition = LatLng(lat, lng);
//
//           driverMarkers[driverId] = Marker(
//             markerId: markerId,
//             position: driverPosition,
//             icon: customDriverIcon, // ✅ use custom marker here
//             infoWindow: InfoWindow(title: "Driver $driverId"),
//           );
//
//           // Placeholder avatar (replace with API avatar if available)
//           driverAvatars.add("assets/images/profile_img_sample.png");
//         }
//       }
//     } catch (e) {
//       print("❌ Error fetching drivers: $e");
//     }
//   }
//
//   void startCountdown() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (remainingSeconds.value > 0) {
//         remainingSeconds.value--;
//       } else {
//         t.cancel();
//         _goToBids(rideArgs);
//       }
//     });
//   }
//
//   // ✅ UPDATED: Prevent decreasing below initial fare
//   void adjustFare(int delta) {
//     final currentFare = int.tryParse(fareController.text) ?? initialMinimumFare;
//     int newFare = currentFare + delta;
//
//     // Prevent going below initial minimum fare
//     if (newFare < initialMinimumFare) {
//       Get.snackbar(
//         'Minimum Fare',
//         'Cannot decrease below PKR $initialMinimumFare',
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//         duration: Duration(seconds: 2),
//       );
//       return; // Don't update the fare
//     }
//
//     // Optional: Set upper limit if needed
//     final maxFare = 10000; // You can adjust this
//     if (newFare > maxFare) {
//       Get.snackbar(
//         'Maximum Fare',
//         'Cannot increase above PKR $maxFare',
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//         duration: Duration(seconds: 2),
//       );
//       return; // Don't update the fare
//     }
//
//     fareController.text = newFare.toString();
//
//     // Show feedback for successful adjustment
//     if (delta > 0) {
//       print('➕ Fare increased to: PKR $newFare');
//     } else {
//       print('➖ Fare decreased to: PKR $newFare');
//     }
//   }
//
//   void raiseFare() {
//     Get.snackbar("Fare Raised", "Your new fare is PKR ${fareController.text}");
//   }
//
//   void _goToBids(Map<String, dynamic> parentArgs) {
//     if (bids.isEmpty) return;
//
//     Get.off(() => const AvailableBidsScreen(), arguments: {
//       ...parentArgs, // pass everything received from RideRequestController
//       'fare': int.tryParse(fareController.text) ?? 250,
//       'bids': bids, // updated bids
//     });
//   }
//
//   @override
//   void onClose() {
//     _timer?.cancel();
//     fareController.dispose();
//     super.onClose();
//   }
// }
