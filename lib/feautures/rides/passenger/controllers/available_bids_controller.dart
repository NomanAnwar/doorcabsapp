import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';
import '../../../shared/services/storage_service.dart';

class AvailableBidsController extends BaseController { // ✅ CHANGED: Extend BaseController
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
  final remainingSeconds = 60.obs;
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
        // ✅ Listen for new bids live
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
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        t.cancel();
      }
    });
  }

  /// ✅ Adds bid with 20s timer (replaces if driver already exists)
  void addBidWithTimer(Map<String, dynamic> bid) {
    final bidRx = Map<String, dynamic>.from(bid);

    // Remove existing bid by same driverId
    bids.removeWhere((b) => b['driver']?['id'] == bidRx['driver']?['id']);

    bidRx['timer'] = 20.obs;
    bidRx['progressColor'] = 0xFF0066FF; // default blue
    bids.add(bidRx);

    Timer.periodic(const Duration(seconds: 1), (timer) {
      final seconds = (bidRx['timer'] as RxInt);
      if (seconds.value > 0) {
        seconds.value--;
        bidRx['progressColor'] =
        seconds.value <= 10 ? 0xFFF8DC25 : 0xFF0066FF;
      } else {
        timer.cancel();
        bids.remove(bidRx);
      }
    });
  }

  /// ✅ Accept a bid and call backend
  Future<void> acceptBid(Map bid) async {
    try {
      _timer?.cancel();

      await executeWithRetry(() async {
        final bidId = bid['bidId'];
        if (bidId == null) {
          throw Exception("Invalid bid ID.");
        }

        // ✅ stop bid-specific timer
        if (bid.containsKey('timer')) {
          (bid['timer'] as RxInt).value = 0;
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

        Get.dialog(const Center(child: CircularProgressIndicator()),
            barrierDismissible: false);

        final response = await FHttpHelper.post("ride/accept-bids", body);

        Get.back();

        if (response['message'] == "Bid accepted successfully.") {
          showSuccess("Driver ${bid['driver']?['name']?['firstName'] ?? ''} confirmed");

          final rideid = rideArgs['rideId'];

          // ✅ UPDATED: Use enhanced pusher manager
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

          Get.toNamed("/drivers-waiting", arguments: {
            ...response,
            'bid': bid,
          });
        } else {
          throw Exception(response['message'] ?? "Failed to accept bid");
        }
      }, maxRetries: 2);
    } catch (e, s) {
      print("❌ Error in acceptBid: $e");
      print(s);
      showError("Something went wrong while accepting bid.");
    }
  }

  void rejectBid(Map bid) {
    bids.remove(bid);
  }

  void cancelRequest() {
    _timer?.cancel();
    Get.back();
    showError("Your ride request was cancelled.");
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}