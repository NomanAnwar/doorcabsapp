import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';
import '../../../shared/services/storage_service.dart';

class AvailableBidsController extends BaseController {
  final bids = <Map<String, dynamic>>[].obs;

  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();

  final driverAvatars = <String>[
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
  ].obs;
  final viewingDrivers = 3.obs;
  final autoAccept = false.obs;
  final remainingSeconds = 10.obs;
  Timer? _timer;

  late final Map<String, dynamic> rideArgs;

  @override
  void onInit() {
    super.onInit();

    rideArgs = Map<String, dynamic>.from(Get.arguments ?? {});
    print("📌 Ride args in AvailableBidsController: $rideArgs");

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
      }
    });
  }

  /// Adds bid with 10s timer, stores timer object and an isProcessing flag
  void addBidWithTimer(Map<String, dynamic> bid) {
    // Create a mutable copy to avoid accidental shared references
    final bidRx = Map<String, dynamic>.from(bid);

    // Remove existing bid by same driverId (replace)
    bids.removeWhere((b) => b['driver']?['id'] == bidRx['driver']?['id']);

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

  void cancelRequest() {
    // Cancel all per-bid timers
    for (final b in List<Map<String, dynamic>>.from(bids)) {
      try {
        final t = b['timerObj'];
        if (t is Timer && t.isActive) t.cancel();
      } catch (_) {}
    }
    _timer?.cancel();
    bids.clear();
    Get.back();
    showError("Your ride request was cancelled.");
  }

  @override
  void onClose() {
    // Cancel global timer
    _timer?.cancel();

    // Cancel per-bid timers
    for (final b in List<Map<String, dynamic>>.from(bids)) {
      try {
        final t = b['timerObj'];
        if (t is Timer && t.isActive) t.cancel();
      } catch (_) {}
    }
    super.onClose();
  }
}
