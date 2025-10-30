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
  void _processDriverData(Map<String, dynamic> data) {
    try {
      if (data["drivers"] != null) {
        final drivers = data["drivers"] as List;
        viewingDrivers.value = drivers.length;

        driverAvatars.clear();

        // Process driver avatars
        for (var driver in drivers) {
          // ✅ UPDATED: Use profile image from event or fallback to asset
          final profileImage = driver["profileImage"]?.toString();
          driverAvatars.add(profileImage ?? "assets/images/profile_img_sample.png");
        }

        debugPrint("✅ AvailableBidsScreen: Processed ${drivers.length} drivers from event");
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

  /// Adds bid with 10s timer, stores timer object and an isProcessing flag
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

    // We will store the Timer object on this map so we can cancel it later
    bids.add(bidRx);

    // Start the per-bid timer and keep reference
    Timer periodic = Timer.periodic(const Duration(seconds: 1), (timer) {
      try {
        final seconds = (bidRx['timer'] as RxInt);
        if (seconds.value > 0) {
          seconds.value--;
          bidRx['progressColor'] =
          seconds.value <= 10 ? 0xFFF8DC25 : 0xFF0066FF; // keep same logic
        } else {
          // Timer completed for this bid
          timer.cancel();

          // store timerObj nullified (optional)
          bidRx['timerObj'] = null;

          // If already processing (accept/reject started), skip auto-reject
          final isProcessing =
              (bidRx['isProcessing'] is RxBool && (bidRx['isProcessing'] as RxBool).value) ||
                  (bidRx['isProcessing'] == true);
          if (isProcessing) {
            print(
                "⏱️ Timer ended for bid ${bidRx['bidId']} but it's already being processed — skipping auto-reject.");
            // Remove from UI only if not already removed
            bids.removeWhere((b) => b['bidId'] == bidRx['bidId']);
            return;
          }

          print(
              "⏱️ Timer ended for bid ${bidRx['bidId']}. Auto-rejecting in background.");

          // Mark processing so accept/reject won't race
          if (bidRx['isProcessing'] is RxBool) {
            (bidRx['isProcessing'] as RxBool).value = true;
          } else {
            bidRx['isProcessing'] = true.obs;
          }

          // Remove from local list first for immediate UX
          bids.removeWhere((b) => b['bidId'] == bidRx['bidId']);

          // Call reject in background (don't await)
          rejectBid(bid);
        }
      } catch (e, s) {
        print("❌ Error in per-bid timer for ${bidRx['bidId']}: $e");
        print(s);
        try {
          timer.cancel();
        } catch (_) {}
        bids.removeWhere((b) => b['bidId'] == bidRx['bidId']);
      }
    });

    // attach timer object so we can cancel it when needed
    bidRx['timerObj'] = periodic;
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

      final response = await FHttpHelper.post('ride/ride-cancelled/$rideId', cancelBody);
      debugPrint("  Cancel Ride API Response : $response");

      // Cancel all timers and clear data
      _cancelAllTimers();

      FSnackbar.show(title: "Success", message: "Ride cancelled successfully");

      isCancellingRide.value = false;
      await Future.delayed(Duration(milliseconds: 20));

      _clearAllRideControllers();
      Get.offAll(() => RideTypeScreen());
    } catch (e) {
      isCancellingRide.value = false;
      showError("Failed to cancel ride: ${e.toString()}");
    }
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