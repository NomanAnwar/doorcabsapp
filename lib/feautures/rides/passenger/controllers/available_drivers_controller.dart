import 'dart:async';
import 'dart:typed_data' show ByteData;
import 'dart:ui';
import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:doorcab/feautures/rides/passenger/controllers/ride_booking_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/http/http_client.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';
import '../../../shared/services/pusher_background_service.dart';
import '../../../shared/services/storage_service.dart';
import '../screens/available_bids_screen.dart';
import '../screens/ride_type_screen.dart';
import 'available_bids_controller.dart';
import 'drivers_waiting_controller.dart';

class AvailableDriversController extends BaseController {
  final currentPosition = Rxn<LatLng>();
  final viewingDrivers = 0.obs;
  final driverAvatars = <String>[].obs;
  final driverMarkers = <String, Marker>{}.obs;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final fareController = TextEditingController();
  final remainingSeconds = 60.obs;
  Timer? _timer;
  Timer? _eventTimeoutTimer;

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

  // ✅ ADDED: Pusher event listener and cancellation
  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
  final hasReceivedEvent = false.obs;
  final isCancellingRide = false.obs;

  final isFareRaised = false.obs;
  final raisedFareValue = 0.obs;


  @override
  void onInit() async {
    super.onInit();

    // ✅ UPDATED: Load custom marker with retry
    await _loadCustomMarkerWithRetry();

    // ✅ pickup lat/lng passed as arguments from RideRequestController
    final args = Get.arguments;
    rideArgs = Map<String, dynamic>.from(args ?? {});
    print("Ride args in AvailableDriversController : $args");

    if (args != null) {
      if (args['fare'] != null) {
        final fare = args['fare'].toString();

        // ✅ FIXED: Handle double fare values like "190.0"
        try {
          // Parse as double first to handle "190.0" case
          final doubleFare = double.tryParse(fare);
          if (doubleFare != null) {
            initialMinimumFare = doubleFare.round(); // Convert to int
            fareController.text =
                initialMinimumFare.toString(); // Set as integer string
            // ✅ ADDED: Set max fare limit to double the initial fare
            maxFareLimit.value = initialMinimumFare * 2;
            print(
                '💰 Initial fare from args: $fare -> parsed as: $initialMinimumFare, Max fare limit: ${maxFareLimit
                    .value}');
          } else {
            // Fallback to integer parsing
            initialMinimumFare = int.tryParse(fare) ?? 0;
            fareController.text = initialMinimumFare.toString();
            maxFareLimit.value = initialMinimumFare * 2;
            print(
                '💰 Initial fare from args: $fare -> parsed as: $initialMinimumFare, Max fare limit: ${maxFareLimit
                    .value}');
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

        // ✅ UPDATED: Start both event listening and API fallback
        _startDriverUpdates();
      }

      // ✅ Store bids observable
      // final argBids = args['bids'];
      // if (argBids != null && argBids is RxList<Map<String, dynamic>>) {
      //   ever(argBids, (_) {
      //     if (argBids.isNotEmpty) {
      //       bids.assignAll(argBids);
      //       _goToBids(args); // pass args forward
      //     }
      //   });
      // }
    }

    // ✅ ADDED: Listen to fare controller changes to update button states
    fareController.addListener(_updateButtonStates);
    _updateButtonStates(); // Initial update

    startCountdown();
    _startBackgroundService();
  }

  void _startBackgroundService() {
    final passengerId = StorageService.getSignUpResponse()?.userId;
    if (passengerId != null) {
      PusherBackgroundService().startBackgroundMode(passengerId);
    }
  }

  // ✅ ADDED: Start both event listening and API fallback
  void _startDriverUpdates() {
    _listenForNearbyDriversEvent();
    _startEventTimeoutTimer();
  }

  // ✅ ADDED: Listen to nearby-drivers Pusher events
  void _listenForNearbyDriversEvent() {
    final passengerId = StorageService.getSignUpResponse()?.userId;
    if (passengerId != null) {
      _pusherManager.subscribeOnce(
        "passenger-$passengerId",
        events: {
          "nearby-drivers": (data) {
            debugPrint("📍 Received nearby-drivers event: $data");
            hasReceivedEvent.value = true;
            _processDriverData(data);
          },
          "new-bid": (data) {
            debugPrint("📨 Passenger received new bid in driver controller : $data");
            try {
              bids.add(data);

              // ✅ NAVIGATE IMMEDIATELY ON FIRST BID
              if (bids.length == 1) { // Only on the very first bid
                debugPrint("🚀 First bid received! Auto-navigating to bids screen...");
                _goToBidsImmediately(rideArgs);
              }
            } catch (e) {
              debugPrint("❌ Error storing bid: $e");
            }
          },
        },
      );
    }
  }

// ✅ ADDED: Navigate immediately when first bid is received
  void _goToBidsImmediately(Map<String, dynamic> parentArgs) {
    // Cancel all timers since we're navigating now
    _timer?.cancel();
    _eventTimeoutTimer?.cancel();

    final fareValue = isFareRaised.value ? raisedFareValue.value : initialMinimumFare;

    print("🚀 AUTO-NAVIGATING with ${bids.length} bids!");
    print("   - First bid fare: PKR ${bids.first['fareOffered']}");
    print("   - Total bids: ${bids.length}");

    Get.off(() => const AvailableBidsScreen(), arguments: {
      ...parentArgs,
      'fare': fareValue,
      'bids': List<Map<String, dynamic>>.from(bids), // Copy all current bids
      'autoNavigated': true,
    });
  }


  // ✅ ADDED: Fallback to API if no events received
  void _startEventTimeoutTimer() {
    _eventTimeoutTimer = Timer(Duration(seconds: 3), () {
      if (!hasReceivedEvent.value) {
        debugPrint("⏰ No event received, falling back to API");
        _fetchNearbyDriversWithRetry(currentPosition.value!);
      }
    });
  }

  // ✅ ADDED: Process driver data from both events and API
  void _processDriverData(Map<String, dynamic> data) {
    try {
      if (data["drivers"] != null) {
        final drivers = data["drivers"] as List;

        // ✅ Keep existing markers, only update/add new ones
        final existingDriverIds = driverMarkers.keys.where((key) => key.startsWith('driver_')).toSet();
        final newDriverIds = <String>{};

        // Process each driver from the event
        for (var driver in drivers) {
          final driverId = driver["driverId"]?.toString();
          if (driverId == null) continue;

          final loc = driver["location"];
          if (loc == null) continue;

          final latRaw = loc["lat"];
          final lngRaw = loc["lng"];
          if (latRaw == null || lngRaw == null) continue;

          final lat = (latRaw is num) ? latRaw.toDouble() : double.tryParse(latRaw.toString());
          final lng = (lngRaw is num) ? lngRaw.toDouble() : double.tryParse(lngRaw.toString());
          if (lat == null || lng == null) continue;

          final driverPosition = LatLng(lat, lng);
          newDriverIds.add(driverId);

          // ✅ Only add/update if driver doesn't exist or position changed
          if (!driverMarkers.containsKey(driverId) ||
              _hasPositionChanged(driverMarkers[driverId]!.position, driverPosition)) {

            driverMarkers[driverId] = Marker(
              markerId: MarkerId("driver_$driverId"),
              position: driverPosition,
              icon: customDriverIcon,
              infoWindow: InfoWindow(title: "Driver ${driver['name']?['firstName'] ?? driverId}"),
            );

            debugPrint("📍 Updated driver $driverId position: $driverPosition");
          }
        }

        // ✅ Remove drivers that are no longer in the nearby list
        final driversToRemove = existingDriverIds.where((id) => !newDriverIds.contains(id.replaceFirst('driver_', '')));
        for (final driverId in driversToRemove) {
          driverMarkers.remove(driverId);
          debugPrint("🗑️ Removed driver: $driverId");
        }

        // ✅ Ensure pickup marker is always present (only add once)
        if (currentPosition.value != null && !driverMarkers.containsKey("pickup")) {
          driverMarkers["pickup"] = Marker(
            markerId: const MarkerId("pickup"),
            position: currentPosition.value!,
            icon: customPickupIcon,
            infoWindow: const InfoWindow(title: "Pickup Location"),
          );
        }

        viewingDrivers.value = newDriverIds.length;
        debugPrint("✅ Processed ${newDriverIds.length} drivers (${driversToRemove.length} removed)");
      }
    } catch (e) {
      debugPrint("❌ Error processing driver data: $e");
    }
  }

// ✅ Helper to check if driver position changed significantly
  bool _hasPositionChanged(LatLng oldPos, LatLng newPos) {
    const threshold = 0.0001; // ~11 meters
    return (oldPos.latitude - newPos.latitude).abs() > threshold ||
        (oldPos.longitude - newPos.longitude).abs() > threshold;
  }

  // ✅ ADDED: Method to update button states
  void _updateButtonStates() {
    final currentFare = _parseFareText(fareController.text);

    isDecrementDisabled.value = currentFare <= initialMinimumFare;
    isIncrementDisabled.value = currentFare >= maxFareLimit.value;
    isRaiseFareDisabled.value =
        currentFare <= initialMinimumFare || isRaisingFare.value;
  }

  void onMapCreated(GoogleMapController controller) {}

  /// ✅ UPDATED: Load custom marker from assets with retry
  Future<void> _loadCustomMarkerWithRetry() async {
    try {
      await executeWithRetry(() async {
        // ---- DRIVER ICON ----
        final ByteData driverData = await rootBundle.load(
            'assets/images/car.png');
        final Uint8List driverBytes = driverData.buffer.asUint8List();
        final Codec driverCodec = await instantiateImageCodec(
            driverBytes, targetWidth: 100);
        final FrameInfo driverFrame = await driverCodec.getNextFrame();
        final ByteData? driverResized = await driverFrame.image.toByteData(
            format: ImageByteFormat.png);
        customDriverIcon =
            BitmapDescriptor.fromBytes(driverResized!.buffer.asUint8List());

        // ---- PICKUP ICON ----
        final ByteData pickupData = await rootBundle.load(
            'assets/images/place.png');
        final Uint8List pickupBytes = pickupData.buffer.asUint8List();
        final Codec pickupCodec = await instantiateImageCodec(
            pickupBytes, targetWidth: 90);
        final FrameInfo pickupFrame = await pickupCodec.getNextFrame();
        final ByteData? pickupResized = await pickupFrame.image.toByteData(
            format: ImageByteFormat.png);
        customPickupIcon =
            BitmapDescriptor.fromBytes(pickupResized!.buffer.asUint8List());

        print('✅ Custom markers loaded successfully');
      }, maxRetries: 2);
    } catch (e) {
      print('❌ Error loading custom markers: $e');
      // Fallbacks
      customDriverIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      customPickupIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  /// ✅ UPDATED: Call backend to fetch nearby drivers with retry (fallback)
  Future<void> _fetchNearbyDriversWithRetry(LatLng pickupCoords) async {
    try {
      await executeWithRetry(() async {
        final body = {
          "lat": pickupCoords.latitude,
          "lng": pickupCoords.longitude,
          "vehicle_type": rideArgs['rideType'],
        };

        final response = await FHttpHelper.post(
            "ride/get-nearby-drivers", body);

        print("Fetch Drivers API Response : " + response.toString());

        if (response != null && response["drivers"] != null) {
          // ✅ Process API response same as event data
          _processDriverData(response);
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

        // ✅ Optional: Show warning when time is running out
        if (remainingSeconds.value == 10 && bids.isEmpty) {
          debugPrint("⏰ Only 10 seconds left - no bids received yet");
        }
      } else {
        t.cancel();

        // ✅ TIMER ENDED - Handle based on whether we got bids
        if (bids.isNotEmpty) {
          // We have bids but didn't auto-navigate (shouldn't happen, but safety)
          debugPrint("⏰ Timer ended with ${bids.length} bids - navigating now");
          _goToBids(rideArgs);
        } else {

          debugPrint("⏰ Timer ended - NO BIDS RECEIVED");
          FSnackbar.show(
              title: "No Drivers Responded",
              message: "No drivers accepted your ride request. Try to raise fare."
          );
        }
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

      // ✅ ADDED: Mark fare as successfully raised
      isFareRaised.value = true;
      raisedFareValue.value = currentFare;

      showSuccess("Your new fare is PKR ${fareController.text}");
    } catch (e) {
      // ✅ ADDED: Ensure fare raised status is false if API fails
      isFareRaised.value = false;
      showError("Failed to raise fare: ${e.toString()}");
    } finally {
      isRaisingFare.value = false;
      _updateButtonStates(); // ✅ Update button states when raising ends
    }
  }


  // ✅ ADDED: Cancel ride method
  Future<void> cancelRide(String cancellationReason,
      LatLng userLocation) async {
    isCancellingRide.value = true;

    try {
      final args = Get.arguments;
      final rideId = args['rideId'];
      final token = StorageService.getAuthToken();

      if (token == null) {
        isCancellingRide.value = false;
        throw Exception("User token not found. Please login again.");
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      final cancelBody = {
        "cancellationReason": cancellationReason,
        "location": {
          "lat": userLocation.latitude,
          "lng": userLocation.longitude,
        },
      };

      final response = await FHttpHelper.post(
          'ride/ride-cancelled/$rideId', cancelBody);
      debugPrint("  Cancel Ride API Response : $response");

      FSnackbar.show(title: "Success", message: "Ride cancelled successfully");

      // Reset state first
      isCancellingRide.value = false;

      // Wait for UI to update
      // await Future.delayed(Duration(milliseconds: 500));
      // ✅ FIXED: Close ALL overlays and navigate back properly
      _navigateAfterCancellation();
    } catch (e) {
      isCancellingRide.value = false;
      showError("Failed to cancel ride: ${e.toString()}");
    }
  }

  void _navigateAfterCancellation() {
    // Close any open overlays
    if (Get.isDialogOpen == true) Get.back();
    if (Get.isBottomSheetOpen == true) Get.back();

    // Navigate back to ride booking screen
    // Get.offAllNamed('/ride-type'); // Make sure this matches your actual route name

    _clearAllRideControllers();
    Get.offAll(() => RideTypeScreen());
  }

  void _clearAllRideControllers() {
    try {
      // Clear all controllers from the ride flow
      Get.delete<RideBookingController>(force: true);
      Get.delete<AvailableDriversController>(force: true);
      Get.delete<AvailableBidsController>(force: true);
      Get.delete<DriversWaitingController>(force: true);

      debugPrint('🧹 Cleared all ride controllers from memory');
    } catch (e) {
      debugPrint('⚠️ Error clearing controllers: $e');
    }
  }

  // ✅ ADDED: Handle back button press
  void handleBackPress() {
    _showCancellationBottomSheet();
  }

  // ✅ UPDATED: Show cancellation reasons bottom sheet with OTP pattern
  void _showCancellationBottomSheet() {
    final screenWidth = Get.width;
    final screenHeight = Get.height;
    final baseWidth = 440.0;

    double sw(double w) => w * screenWidth / baseWidth;

    final cancellationReasons = [
      "Change of plans",
      "Found another ride",
      "Driver taking too long",
      "Price too high",
      "Emergency",
      "Other reason"
    ];

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(sw(20)),
            topRight: Radius.circular(sw(20)),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: sw(20), vertical: sw(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Title
            Text(
              "Cancel Ride",
              style: FTextTheme.lightTextTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: FTextTheme.lightTextTheme.titleLarge!.fontSize! * screenWidth / baseWidth,
              ),
            ),

            SizedBox(height: sw(10)),

            /// Subtitle
            Text(
              "Please select a reason for cancellation:",
              style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                color: Colors.grey[600],
                fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! * screenWidth / baseWidth,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: sw(20)),

            /// Reasons list
            ...cancellationReasons.map((reason) => Column(
              children: [
                ListTile(
                  title: Text(
                    reason,
                    style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                      fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! * screenWidth / baseWidth,
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    _confirmCancellation(reason);
                  },
                ),
                Divider(height: sw(1), color: Colors.grey[300]),
              ],
            )).toList(),

            SizedBox(height: sw(20)),

            /// Continue Waiting button
            SizedBox(
              width: double.infinity,
              height: sw(48),
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(sw(14)),
                  ),
                ),
                child: Text(
                  "Continue Waiting",
                  style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! * screenWidth / baseWidth,
                  ),
                ),
              ),
            ),

            SizedBox(height: sw(10)),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmCancellation(String reason) {
    // Get REAL current location instead of pickup location
    _getCurrentLocationAndCancel(reason);
  }

  Future<void> _getCurrentLocationAndCancel(String reason) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLocation = LatLng(position.latitude, position.longitude);

      Future.delayed(Duration(milliseconds: 50), () {
        cancelRide(reason, userLocation);
      });
    } catch (e) {
      print('❌ Error getting current location: $e');
      // Fallback to pickup location if GPS fails
      final fallbackLocation = currentPosition.value ?? LatLng(0, 0);
      cancelRide(reason, fallbackLocation);
    }
  }

  void _goToBids(Map<String, dynamic> parentArgs) {
    if (bids.isEmpty) return;

    // ✅ FIXED: Use raised fare if successfully raised, otherwise use received fare
    // final fareValue = isFareRaised.value ? raisedFareValue.value : _parseFareText(fareController.text);
    final fareValue = isFareRaised.value ? raisedFareValue.value : initialMinimumFare;

    print("🎯 Navigating to bids screen with fare:");
    print("   - Fare raised: ${isFareRaised.value}");
    print("   - Sending fare: PKR $fareValue");
    print("   - Original fare: PKR ${_parseFareText(fareController.text)}");
    print("   - Raised fare: PKR ${raisedFareValue.value}");
    print("   - Initial Raised fare: PKR ${initialMinimumFare}");
    print("   - Initial bid : ${bids}");

    Get.off(() => const AvailableBidsScreen(), arguments: {
      ...parentArgs, // pass everything received from RideRequestController
      'fare': initialMinimumFare,
      'bids': bids, // updated bids
    });
  }


  @override
  void onClose() {
    _timer?.cancel();
    _eventTimeoutTimer?.cancel();
    fareController.removeListener(_updateButtonStates); // ✅ Remove listener
    fareController.dispose();
    super.onClose();
  }
}