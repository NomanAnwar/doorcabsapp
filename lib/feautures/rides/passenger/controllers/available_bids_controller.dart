import 'dart:async';
import 'package:doorcab/feautures/rides/passenger/controllers/ride_booking_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/http/http_client.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';
import '../../../shared/services/pusher_background_service.dart';
import '../../../shared/services/storage_service.dart';
import '../screens/ride_type_screen.dart';
import 'available_drivers_controller.dart';
import 'drivers_waiting_controller.dart';

class AvailableBidsController extends BaseController {
  final bids = <Map<String, dynamic>>[].obs;

  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();

  final driverAvatars = <String>[].obs;
  final viewingDrivers = 0.obs;
  final autoAccept = false.obs;
  final remainingSeconds = 60.obs;
  Timer? _timer;

  // ✅ ADDED: New observables for cancellation
  final isCancellingRide = false.obs;
  final hasReceivedEvent = false.obs;

  late final Map<String, dynamic> rideArgs;
  final currentFare = 0.obs;

  @override
  void onInit() {
    super.onInit();

    rideArgs = Map<String, dynamic>.from(Get.arguments ?? {});

    // ✅ ADDED: Get current fare from arguments
    currentFare.value = rideArgs['fare'] ?? 0;

    autoAccept.value = StorageService.getAutoAcceptStatus();

    print("📌 Ride args in AvailableBidsController: $rideArgs");
    print("💰 Current fare: $currentFare");

    final argBids = rideArgs['bids'];
    if (argBids != null) {
      if (argBids is RxList<Map<String, dynamic>>) {
        ever(argBids, (_) {
          _syncBids(argBids);
        });
        _syncBids(argBids);
      } else if (argBids is List<Map<String, dynamic>>) {
        _syncBids(argBids);
      }
    }

    print("📌 Initial bids: $bids");

    _startCountdown();
    _listenForNearbyDriversEvent(); // ✅ ADDED: Listen for nearby drivers
    _startBackgroundService();
  }

  void _startBackgroundService() {
    final passengerId = StorageService.getSignUpResponse()?.userId;
    if (passengerId != null) {
      PusherBackgroundService().startBackgroundMode(passengerId);
    }
  }

  // ✅ ADDED: Listen to nearby-drivers Pusher events (same as previous screen)
  void _listenForNearbyDriversEvent() {
    final passengerId = StorageService.getSignUpResponse()?.userId;
    if (passengerId != null) {
      _pusherManager.subscribeOnce(
        "passenger-$passengerId",
        events: {
          "nearby-drivers": (data) {
            debugPrint("📍 AvailableBidsScreen: Received nearby-drivers event: $data");
            hasReceivedEvent.value = true;
            _processDriverData(data);
          },
          "new-bid": (data) {
            debugPrint("📨 AvailableBidsScreen: Received new bid: $data");
            try {
              // Add bid with timer when new bid arrives
              addBidWithTimer(Map<String, dynamic>.from(data));
            } catch (e) {
              debugPrint("❌ Error storing bid: $e");
            }
          },
        },
      );
    }
  }

  // ✅ ADDED: Process driver data from events (same as previous screen)
// In AvailableBidsController - for driverAvatars
  void _processDriverData(Map<String, dynamic> data) {
    try {
      if (data["drivers"] != null) {
        final drivers = data["drivers"] as List;

        // ✅ Track existing avatars to avoid duplicates
        final existingAvatars = driverAvatars.toSet();
        final newAvatars = <String>{};

        for (var driver in drivers) {
          final profileImage = driver["profileImage"]?.toString();
          final avatarUrl = profileImage ?? "assets/images/profile_img_sample.png";

          // ✅ Only add if not already in list
          if (!existingAvatars.contains(avatarUrl)) {
            newAvatars.add(avatarUrl);
          }
        }

        // ✅ Add only new unique avatars
        if (newAvatars.isNotEmpty) {
          driverAvatars.addAll(newAvatars);
        }

        viewingDrivers.value = driverAvatars.length;
        debugPrint("✅ AvailableBidsScreen: ${newAvatars.length} new drivers, total: ${driverAvatars.length}");
      }
    } catch (e) {
      debugPrint("❌ Error processing driver data in AvailableBidsScreen: $e");
    }
  }

  void _syncBids(List<Map<String, dynamic>> newBids) {
    for (final b in newBids) {
      addBidWithTimer(b);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        t.cancel();
        // Handle timeout logic if needed
      }
    });
  }

  void addBidWithTimer(Map<String, dynamic> bid) {
    // Create a mutable copy to avoid accidental shared references
    final bidRx = Map<String, dynamic>.from(bid);

    // Remove existing bid by same driverId (replace)
    bids.removeWhere((b) => b['driver']?['id'] == bidRx['driver']?['id']);

    // Check for auto-accept before adding the bid
    if (autoAccept.value) {
      final bidFare = bidRx['fareOffered'];
      if (bidFare != null && bidFare == currentFare.value) {
        print("🎯 Auto-accepting new matching bid: PKR $bidFare");
        // Add to bids first so acceptBid can find it
        bids.add(bidRx);
        acceptBid(bidRx);
        return; // Don't set up timer for auto-accepted bid
      }
    }

    // Reactive timer count
    bidRx['timer'] = 10.obs;

    // Processing flag to avoid double accept/reject (RxBool)
    bidRx['isProcessing'] = false.obs;

    // default progress color
    bidRx['progressColor'] = 0xFF0066FF;

    // ✅ REPLACED: Use the new reusable timer method
    _startBidTimer(bidRx, 10);

    bids.add(bidRx);
  }


  /// Accept a bid and call backend
  Future<void> acceptBid(Map bid) async {
    try {
      // If already processing this bid, skip
      if (bid['isProcessing'] is RxBool) {
        if ((bid['isProcessing'] as RxBool).value) {
          print("⚠️ Bid ${bid['bidId']} is already being processed — skipping accept.");
          return;
        } else {
          (bid['isProcessing'] as RxBool).value = true;
        }
      } else if (bid['isProcessing'] == true) {
        print("⚠️ Bid ${bid['bidId']} is already being processed — skipping accept.");
        return;
      } else {
        bid['isProcessing'] = true.obs;
      }

      // Cancel global countdown (you already did this in original code)
      _timer?.cancel();

      // stop bid-specific timer if present
      try {
        final timerObj = bid['timerObj'];
        if (timerObj is Timer && timerObj.isActive) {
          timerObj.cancel();
          bid['timerObj'] = null;
          print("🕐 Cancelled per-bid timer for ${bid['bidId']} before accept.");
        } else if (bid.containsKey('timer')) {
          // also set countdown to 0 to update UI if necessary
          if (bid['timer'] is RxInt) (bid['timer'] as RxInt).value = 0;
        }
      } catch (e) {
        print("❗ Error cancelling bid timer for ${bid['bidId']}: $e");
      }

      await executeWithRetry(() async {
        final bidId = bid['bidId'];
        if (bidId == null) {
          throw Exception("Invalid bid ID.");
        }

        // ETA calculation
        DateTime etaDateTime = DateTime.now().toUtc();
        if (bid['eta'] != null && bid['eta'].toString().contains("min")) {
          final parts = bid['eta'].toString().split(" ");
          final minutes = int.tryParse(parts[0]) ?? 0;
          etaDateTime = etaDateTime.add(Duration(minutes: minutes));
        }
        final etaIso =
        DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(etaDateTime);

        final body = {
          "bidId": bidId,
          "rideId": rideArgs['rideId'],
          "pickup": rideArgs['pickup'],
          "dropoffs": rideArgs['dropoffs'],
          "fare": rideArgs['fare'],
          "passengers": rideArgs['passengers'],
          "payment": rideArgs['payment'],
          "rideType": rideArgs['rideType'],
          "estimated_arrival_time": etaIso,
        };

        print("🚀 Sending accept-bid request: $body");

        // Show loading dialog
        Get.dialog(const Center(child: CircularProgressIndicator()),
            barrierDismissible: false);

        final response = await FHttpHelper.post("ride/accept-bids", body);

        // close dialog
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        if (response['message'] == "Bid accepted successfully.") {
          print("✅ Accept bid API Response : " + response.toString());
          showSuccess("Driver ${bid['driver']?['name']?['firstName'] ?? ''} confirmed");

          // Clear all bids and cancel their timers to avoid stray timers calling reject
          for (final b in List<Map<String, dynamic>>.from(bids)) {
            try {
              final t = b['timerObj'];
              if (t is Timer && t.isActive) {
                t.cancel();
              }
            } catch (_) {}
          }
          bids.clear();

          final rideid = rideArgs['rideId'];

          // Subscribe to pusher channel (enhanced manager)
          await _pusherManager.subscribeOnce(
            "ride-$rideid",
            events: {
              "pusher:subscription_succeeded": (data) {
                print("✅ Subscribed successfully to ride-$rideid channel");
              },
              "driver-location": (data) {
                print("🚖 Driver location update: $data");
              },
            },
          );

          // navigate
          Get.toNamed("/drivers-waiting", arguments: {
            ...response,
            'bid': bid,
            'rideType': rideArgs['rideType'],
          });
        } else {
          throw Exception(response['message'] ?? "Failed to accept bid");
        }
      }, maxRetries: 2);
    } catch (e, s) {
      print("❌ Error in acceptBid: $e");
      print(s);

      // In case of failure, try to clear processing flag so user can retry
      try {
        if (bid['isProcessing'] is RxBool) {
          (bid['isProcessing'] as RxBool).value = false;
        } else {
          bid['isProcessing'] = false.obs;
        }
      } catch (_) {}

      showError("Something went wrong while accepting bid.");
    }
  }

  void rejectBid(Map bid) async {
    try {
      // If bid already processing, skip
      if (bid['isProcessing'] is RxBool) {
        if ((bid['isProcessing'] as RxBool).value) {
          print("⚠️ Bid ${bid['bidId']} is already being processed — skipping reject.");
          return;
        } else {
          (bid['isProcessing'] as RxBool).value = true;
        }
      } else if (bid['isProcessing'] == true) {
        print("⚠️ Bid ${bid['bidId']} is already being processed — skipping reject.");
        return;
      } else {
        bid['isProcessing'] = true.obs;
      }

      // Remove from UI immediately for good UX
      bids.removeWhere((b) => b['bidId'] == bid['bidId']);
      print("🚫 Removed bid ${bid['bidId']} from UI and will reject in background.");

      // Cancel per-bid timer if active
      try {
        final timerObj = bid['timerObj'];
        if (timerObj is Timer && timerObj.isActive) {
          timerObj.cancel();
          bid['timerObj'] = null;
          print("🕐 Cancelled per-bid timer for ${bid['bidId']} before reject.");
        }
      } catch (e) {
        print("❗ Error cancelling bid timer for ${bid['bidId']} at reject: $e");
      }

      // Call API in background with retry
      await executeWithRetry(() async {
        // Ensure auth token is set
        final token = StorageService.getAuthToken();
        if (token == null) {
          throw Exception("User not authenticated. Please login again.");
        }
        FHttpHelper.setAuthToken(token, useBearer: true);

        final bidId = bid['bidId']?.toString();
        if (bidId == null || bidId.isEmpty) {
          throw Exception("Invalid bidId");
        }

        final requestBody = {
          "bidId": bidId,
        };

        print("🚀 Sending reject-bid request: $requestBody");

        final response = await FHttpHelper.post('ride/reject-bid', requestBody);

        print("🚫 Reject bid API Response: $response");

        if (response['message'] == "Bid rejected successfully" ||
            response['message']?.toString().toLowerCase().contains("rejected") == true) {
          print("✅ Bid $bidId rejected on server.");
        } else {
          throw Exception(response['message'] ?? "Failed to reject bid");
        }
      }, maxRetries: 2);
    } catch (e, s) {
      print("❌ Error in rejectBid: $e");
      print(s);
      // Already removed from UI; log error and move on.
    }
  }

// ✅ ADDED: Get current location for cancellation
  Future<void> _getCurrentLocationAndCancel(String reason) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLocation = LatLng(position.latitude, position.longitude);
      cancelRide(reason, userLocation);
    } catch (e) {
      print('❌ Error getting current location: $e');
      // Fallback to pickup location from args
      final args = Get.arguments;
      final pickupLat = args['pickupLat'] ?? 0.0;
      final pickupLng = args['pickupLng'] ?? 0.0;
      final fallbackLocation = LatLng(pickupLat, pickupLng);
      cancelRide(reason, fallbackLocation);
    }
  }

// ✅ UPDATED: Cancel ride method to accept location parameter
  Future<void> cancelRide(String cancellationReason, LatLng userLocation) async {
    // ✅ STEP 1: Immediately stop all timers
    _cancelAllTimersAndProcessing();
    isCancellingRide.value = true;

    try {
      final args = Get.arguments;
      final rideId = args['rideId'];
      final token = StorageService.getAuthToken();

      if (token == null) {
        isCancellingRide.value = false;
        _restartAllTimersAndProcessing(); // Restart if no token
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

      final response = await FHttpHelper.post('ride/ride-cancelled/$rideId', cancelBody);
      debugPrint("  Cancel Ride API Response : $response");

      // ✅ STEP 2: Only clear everything if cancellation SUCCESS
      FSnackbar.show(title: "Success", message: "Ride cancelled successfully");

      isCancellingRide.value = false;
      await Future.delayed(Duration(milliseconds: 20));

      _clearAllRideControllers();
      Get.offAll(() => RideTypeScreen());

    } catch (e) {
      // ✅ STEP 3: If cancellation FAILS, RESTART everything
      isCancellingRide.value = false;
      FSnackbar.show(title: 'Failed', message: "Failed to cancel ride: ${e.toString()}", isError: true);
      _restartAllTimersAndProcessing();
    }
  }

  // ✅ NEW: Immediately stop all timers and mark bids as non-processing
  void _cancelAllTimersAndProcessing() {
    print("🛑 Stopping all timers and processing...");

    // Stop global timer
    _timer?.cancel();
    _timer = null;

    // Stop all bid timers
    for (final bid in List<Map<String, dynamic>>.from(bids)) {
      try {
        // Cancel individual bid timer
        final timerObj = bid['timerObj'];
        if (timerObj is Timer && timerObj.isActive) {
          timerObj.cancel();
          bid['timerObj'] = null;
          print("⏹️ Stopped timer for bid ${bid['bidId']}");
        }

        // Mark as not processing so they can be restarted if needed
        if (bid['isProcessing'] is RxBool) {
          (bid['isProcessing'] as RxBool).value = false;
        } else {
          bid['isProcessing'] = false.obs;
        }
      } catch (e) {
        print("❌ Error stopping bid timer for ${bid['bidId']}: $e");
      }
    }
  }

// ✅ NEW: Restart timers after failed cancellation
  void _restartAllTimersAndProcessing() {
    print("🔄 Restarting bid timers after cancellation failed");

    // Restart global countdown
    _startCountdown();

    // Restart individual bid timers with remaining time
    for (final bid in bids) {
      try {
        final remainingTime = bid['timer'] is RxInt ? (bid['timer'] as RxInt).value : 10;

        if (remainingTime > 0) {
          // Cancel any existing timer
          final existingTimer = bid['timerObj'];
          if (existingTimer is Timer && existingTimer.isActive) {
            existingTimer.cancel();
          }

          // Restart the timer
          _startBidTimer(bid, remainingTime);
        }
      } catch (e) {
        print("❌ Error restarting bid timer: $e");
      }
    }
  }

// ✅ NEW: Extract timer logic to reusable method
  void _startBidTimer(Map<String, dynamic> bid, int initialTime) {
    bid['timer'] = initialTime.obs;
    bid['progressColor'] = 0xFF0066FF;

    Timer periodic = Timer.periodic(const Duration(seconds: 1), (timer) {
      try {
        final seconds = (bid['timer'] as RxInt);
        if (seconds.value > 0) {
          seconds.value--;
          bid['progressColor'] = seconds.value <= 10 ? 0xFFF8DC25 : 0xFF0066FF;
        } else {
          timer.cancel();
          bid['timerObj'] = null;

          final isProcessing = (bid['isProcessing'] is RxBool && (bid['isProcessing'] as RxBool).value) ||
              (bid['isProcessing'] == true);

          if (isProcessing) {
            print("⏱️ Timer ended but bid is processing — skipping auto-reject.");
            bids.removeWhere((b) => b['bidId'] == bid['bidId']);
            return;
          }

          print("⏱️ Timer ended for bid ${bid['bidId']}. Auto-rejecting.");

          if (bid['isProcessing'] is RxBool) {
            (bid['isProcessing'] as RxBool).value = true;
          } else {
            bid['isProcessing'] = true.obs;
          }

          bids.removeWhere((b) => b['bidId'] == bid['bidId']);
          rejectBid(bid);
        }
      } catch (e, s) {
        print("❌ Error in bid timer: $e");
        timer.cancel();
        bids.removeWhere((b) => b['bidId'] == bid['bidId']);
      }
    });

    bid['timerObj'] = periodic;
  }

// ✅ UPDATED: Confirm cancellation to use location
  void _confirmCancellation(String reason) {
    _getCurrentLocationAndCancel(reason); // Now gets current location
  }

  void _clearAllRideControllers() {
    try {
      Get.delete<RideBookingController>(force: true);
      Get.delete<AvailableDriversController>(force: true);
      Get.delete<AvailableBidsController>(force: true);
      Get.delete<DriversWaitingController>(force: true);
      debugPrint('🧹 Cleared all ride controllers from memory');
    } catch (e) {
      debugPrint('⚠️ Error clearing controllers: $e');
    }
  }

  // ✅ ADDED: Handle back button press (same as previous screen)
  void handleBackPress() {
    _showCancellationBottomSheet();
  }

  // ✅ ADDED: Show cancellation reasons bottom sheet (same as previous screen)
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


  // ✅ ADDED: Cancel all timers
  void _cancelAllTimers() {
    _timer?.cancel();
    for (final b in List<Map<String, dynamic>>.from(bids)) {
      try {
        final t = b['timerObj'];
        if (t is Timer && t.isActive) t.cancel();
      } catch (_) {}
    }
    bids.clear();
  }

  void cancelRequest() {
    handleBackPress(); // ✅ UPDATED: Use cancellation flow instead of direct cancel
  }

  void onAutoAcceptToggle(bool value) {
    autoAccept.value = value;
    // Save the auto-accept status to storage
    StorageService.setAutoAcceptStatus(value);

    if (value) {
      // showSuccess("Auto-accept enabled for PKR $currentFare");
      FSnackbar.show(title: 'Auto Accept Bids', message: "Now Auto-accept Bids for PKR $currentFare");
      // Check if any existing bids match the current fare
      _checkForMatchingBids();
    } else {
      FSnackbar.show(title: 'Auto Accept Bids', message: "Auto-accept Bids Disabled");
    }
  }


  // Method to check for and auto-accept matching bids
  void _checkForMatchingBids() {
    if (!autoAccept.value) return;

    for (final bid in List<Map<String, dynamic>>.from(bids)) {
      final bidFare = bid['fareOffered'];
      if (bidFare != null && bidFare == currentFare.value) {
        print("🎯 Auto-accepting matching bid: PKR $bidFare");
        acceptBid(bid);
        break; // Only accept the first matching bid
      }
    }
  }


  @override
  void onClose() {
    _cancelAllTimers();
    super.onClose();
  }
}