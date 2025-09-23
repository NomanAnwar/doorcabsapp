import 'dart:async';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../../../shared/services/pusher_beams.dart';
import '../../../shared/services/pusher_channels.dart';
import '../models/request_model.dart';
import '../../../shared/services/driver_location_service.dart'; // ✅ use service

class RideRequestListController extends GetxController {
  final PusherBeamsService _pusherBeams = PusherBeamsService();
  final PusherChannelsService _pusherChannels = PusherChannelsService();
  final DriverLocationService _driverLocationService = DriverLocationService(); // ✅ instance

  final requests = <RequestModel>[].obs;
  final remainingSeconds = <String, int>{}.obs;
  final _timers = <String, Timer>{};
  final isOnline = false.obs;
  final int offerCountdownSeconds = 120;

  @override
  void onInit() {
    super.onInit();
    _initializePushNotifications();
  }

  Future<void> _initializePushNotifications() async {
    await _pusherBeams.initialize();
    await _pusherBeams.registerDevice();
  }

  void _startTimerForRequest(String requestId) {
    _timers[requestId]?.cancel();
    remainingSeconds[requestId] = offerCountdownSeconds;

    _timers[requestId] = Timer.periodic(const Duration(seconds: 1), (t) {
      final current = remainingSeconds[requestId] ?? 0;
      if (current <= 1) {
        t.cancel();
        remainingSeconds[requestId] = 0;
        _handleRequestTimeout(requestId);
      } else {
        remainingSeconds[requestId] = current - 1;
      }
    });
  }

  void stopTimerForRequest(String requestId) {
    _timers[requestId]?.cancel();
    _timers.remove(requestId);
    remainingSeconds.remove(requestId);
  }

  void _handleRequestTimeout(String requestId) {
    final idx = requests.indexWhere((r) => r.id == requestId);
    if (idx >= 0) {
      requests.removeAt(idx);
    }
    Get.snackbar('Request timed out', 'Request $requestId has been removed.');
  }

  void acceptRequest(RequestModel request) {
    stopTimerForRequest(request.id);
    Get.toNamed('/ride-request-detail', arguments: {'request': request});
  }

  void rejectRequest(String requestId) {
    stopTimerForRequest(requestId);
    final idx = requests.indexWhere((r) => r.id == requestId);
    if (idx >= 0) requests.removeAt(idx);
    Get.snackbar('Request rejected', 'You rejected the request');
  }

  /// 🚖 Driver Online/Offline Toggle
  void toggleOnline(bool val) async {
    isOnline.value = val;

    if (val) {
      final driverId = StorageService.getSignUpResponse()!.userId;
      print("Driver Id : $driverId");

      // Initialize and register for push notifications
      await _pusherBeams.initialize();
      await _pusherBeams.registerDevice();

      // ✅ Configure + Start location service
      await _driverLocationService.configure();
      await _driverLocationService.start();

      // ✅ Connect to Pusher
      await _pusherChannels.initialize(
        driverId: driverId,
        onRideRequest: (data) {
          print("🚖 New ride request: $data");

          try {
            final request = RequestModel(
              id: data["rideId"]?.toString() ?? "",
              passengerName: data["passengerName"]?.toString() ?? "",
              passengerImage: data["passengerImage"]?.toString() ?? "",
              rating: (data["rating"] is num) ? (data["rating"] as num).toDouble() : 0.0,

              // ✅ Proper parsing for pickup
              pickupAddress: LocationPoint.fromJson(data["pickupAddress"] ?? {}),

              // ✅ Proper parsing for multiple dropoffs
              dropoffAddress: (data["dropoffAddress"] is List)
                  ? (data["dropoffAddress"] as List)
                  .map((e) => DropoffPoint.fromJson(e))
                  .toList()
                  : [],

              phone: data["phone"]?.toString() ?? "",
              etaMinutes: (data["etaMinutes"] is int) ? data["etaMinutes"] as int : 0,
              distanceKm: (data["distanceKm"] is num) ? (data["distanceKm"] as num).toDouble() : 0.0,
              offerAmount: (data["offerAmount"] is num) ? (data["offerAmount"] as num).toDouble() : 0.0,

              // backend sends createdAt as timestamp → parse safely
              createdAt: (data["createdAt"] is int)
                  ? DateTime.fromMillisecondsSinceEpoch(data["createdAt"])
                  : DateTime.now(),
            );

            requests.add(request);
            _startTimerForRequest(request.id);
          } catch (e, s) {
            print("❌ Error parsing ride request: $e");
            print(s);
          }
        },
      );
    } else {
      // ❌ Stop location service
      await _driverLocationService.stop();

      // ❌ Disconnect Pusher
      await _pusherChannels.disconnect();
      requests.clear();
      remainingSeconds.clear();
      _timers.forEach((_, t) => t.cancel());
      _timers.clear();
      print("🚫 Driver is offline, unsubscribed from ride requests");
    }
  }

  @override
  void onClose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _driverLocationService.stop(); // ✅ cleanup
    super.onClose();
  }

  // ❌ keep method but unused, so no error
  List<RequestModel> _sampleRequests() {
    final now = DateTime.now();
    return [
      RequestModel(
        id: 'req_1',
        passengerName: '',
        passengerImage: '',
        rating: 0.0,
        pickupAddress: LocationPoint(lat: 0.0, lng: 0.0, address: ""),
        dropoffAddress: [],
        phone: '',
        etaMinutes: 0,
        distanceKm: 0.0,
        offerAmount: 0.0,
        createdAt: now,
      ),
    ];
  }
}
