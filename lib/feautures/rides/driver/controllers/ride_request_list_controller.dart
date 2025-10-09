import 'dart:async';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:get/get.dart';
import '../../../../main.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/driver_location_service.dart';
import '../../../shared/services/pusher_beams.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';
import '../models/request_model.dart';

class RideRequestListController extends BaseController { // ✅ CHANGED: Extend BaseController

  // final PusherBeamsService _pusherBeams = globalPusherBeams;
  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
  final DriverLocationService _driverLocationService = DriverLocationService();

  final requests = <RequestModel>[].obs;
  final remainingSeconds = <String, int>{}.obs;
  final _timers = <String, Timer>{};
  final isOnline = false.obs;
  final int offerCountdownSeconds = 60;

  bool _beamsInitialized = false;
  final Set<String> _subscribedChannels = {};

  @override
  void onInit() {
    super.onInit();
    _initializePushNotifications();
    _restoreOnlineStatus();
    _handleInitialRequest();
  }

  void _restoreOnlineStatus() {
    // Restore online status from storage
    final wasOnline = StorageService.getDriverOnlineStatus();
    if (wasOnline) {
      print('🔄 Restoring previous online status: $wasOnline');
      toggleOnline(true);
    }
  }

  void _handleInitialRequest() {
    // Check if we received an initial request from GoOnlineScreen
    final arguments = Get.arguments;
    if (arguments != null && arguments['initialRequest'] != null) {
      final RequestModel initialRequest = arguments['initialRequest'];
      print("✅ Received initial request from GoOnlineScreen: ${initialRequest.id}");

      // Add the initial request to the list and start timer
      if (!requests.any((r) => r.id == initialRequest.id)) {
        requests.add(initialRequest);
        _startTimerForRequest(initialRequest.id);
      }
    }
  }

  Future<void> _initializePushNotifications() async {
    if (!_beamsInitialized) {
      try {
        // Since we're using global instances, these might already be initialized
        // Just mark as initialized without re-initializing
        _beamsInitialized = true;
        print('ℹ️ Beams already initialized globally, skipping re-initialization');
      } catch (e) {
        print('⚠️ _initializePushNotifications: $e');
      }
    }
  }

  void _startTimerForRequest(String requestId) {
    // Cancel existing timer first
    _timers[requestId]?.cancel();

    remainingSeconds[requestId] = offerCountdownSeconds;

    _timers[requestId] = Timer.periodic(const Duration(seconds: 1), (t) {
      final current = remainingSeconds[requestId] ?? 0;
      if (current <= 1) {
        t.cancel();
        _timers.remove(requestId);
        remainingSeconds.remove(requestId);
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
      showError('Request $requestId has been removed.');
    }
  }

  void acceptRequest(RequestModel request) {
    // Stop timer immediately when accepting to navigate
    stopTimerForRequest(request.id);

    Get.toNamed('/ride-request-detail', arguments: {'request': request})?.then((result) {
      try {
        if (result == 'accepted') {
          // Remove from list if accepted
          final idx = requests.indexWhere((r) => r.id == request.id);
          if (idx >= 0) requests.removeAt(idx);
        } else {
          // If user went back without accepting, restart timer if request still exists
          print('ℹ️ Returned from detail screen, result: $result');
          if (requests.any((r) => r.id == request.id)) {
            _startTimerForRequest(request.id);
          }
        }
      } catch (e) {
        print('❌ Error handling result from detail screen: $e');
      }
    });
  }

  void rejectRequest(String requestId) {
    stopTimerForRequest(requestId);
    requests.removeWhere((r) => r.id == requestId);
    showError('You rejected the request');
  }

  /// 🚖 Driver Online/Offline Toggle - IMPROVED
  void toggleOnline(bool val) async {
    if (isOnline.value == val) {
      print('ℹ️ Driver already ${val ? 'online' : 'offline'}, skipping');
      return; // Prevent duplicate operations
    }

    isOnline.value = val;

    // Save online status
    StorageService.setDriverOnlineStatus(val);

    if (val) {
      await _goOnline();
    } else {
      await _goOffline();
    }
  }

  Future<void> _goOnline() async {
    final driverId = StorageService.getSignUpResponse()!.userId;
    print("🚖 Driver going online: $driverId");

    try {
      await executeWithRetry(() async {
        // ✅ Start location service (already configured in main.dart)
        await _driverLocationService.start();
        print("📍 Location service started");

        // ✅ Subscribe to channels
        await _subscribeToChannels(driverId);

        showSuccess('You are now online and receiving ride requests');
      });
    } catch (e) {
      print('❌ Error going online: $e');
      isOnline.value = false; // Revert on error
      showError('Failed to go online: $e');
    }
  }

  Future<void> _goOffline() async {
    print("🚫 Driver going offline");

    try {
      await executeWithRetry(() async {
        // ✅ Pause location service (but keep it configured)
        _driverLocationService.pause();
        print("📍 Location service paused");

        // ✅ Unsubscribe from channels
        await _unsubscribeFromChannels();

        // ✅ Clear all data
        _clearAllRequestsAndTimers();

        showSuccess('You are now offline');
      });
    } catch (e) {
      print('❌ Error going offline: $e');
      showError('Failed to go offline');
    }
  }

  Future<void> _subscribeToChannels(String driverId) async {
    final privateChannel = "private-driver-$driverId";
    final driverChannel = "driver-$driverId";

    try {
      await executeWithRetry(() async {
        // Subscribe to private driver channel for ride requests
        if (!_subscribedChannels.contains(privateChannel)) {
          await _pusherManager.subscribeOnce(
            privateChannel,
            events: {
              "ride-request": (data) {
                _handleNewRideRequest(data);
              },
            },
          );
          _subscribedChannels.add(privateChannel);
          print("✅ Subscribed to: $privateChannel");
        }

        // Subscribe to driver channel for bid acceptance
        if (!_subscribedChannels.contains(driverChannel)) {
          await _pusherManager.subscribeOnce(
            driverChannel,
            events: {
              "bid-accepted": (eventData) {
                _handleBidAccepted(eventData);
              },
            },
          );
          _subscribedChannels.add(driverChannel);
          print("✅ Subscribed to: $driverChannel");
        }
      });
    } catch (e) {
      print('❌ Error subscribing to channels: $e');
      rethrow;
    }
  }

  Future<void> _unsubscribeFromChannels() async {
    try {
      await executeWithRetry(() async {
        // Unsubscribe from all channels
        for (final channel in _subscribedChannels) {
          _pusherManager.unsubscribeSafely(channel);
          print("✅ Unsubscribed from: $channel");
        }
        _subscribedChannels.clear();
      });
    } catch (e) {
      print('❌ Error unsubscribing from channels: $e');
    }
  }

  void _handleNewRideRequest(Map<String, dynamic> data) {
    print("🚖 New ride request: $data");

    try {
      final request = RequestModel.fromJson(data);

      // Check for duplicate requests
      if (requests.any((r) => r.id == request.id)) {
        print('ℹ️ Request ${request.id} already exists, skipping');
        return;
      }

      requests.add(request);
      _startTimerForRequest(request.id);

      print("✅ Added request: ${request.id}, Passenger: ${request.passengerName}");

      // Show notification
      Get.snackbar(
        'New Ride Request',
        'From ${request.passengerName} - ${request.offerAmount} PKR',
        duration: const Duration(seconds: 5),
      );
    } catch (e, s) {
      print("❌ Error parsing ride request: $e");
      print("📦 Raw data: $data");
      print(s);
    }
  }

  void _handleBidAccepted(Map<String, dynamic> eventData) {
    print("✅ bid-accepted event received: $eventData");

    try {
      final rideId = eventData['rideId']?.toString() ?? "";

      // Stop timer for this specific request
      if (rideId.isNotEmpty) {
        stopTimerForRequest(rideId);
      }

      // Clear all other requests and timers
      _clearAllRequestsAndTimers();

      // Navigate to pickup screen
      Get.offNamed('/go-to-pickup', arguments: {"rideData": eventData});
    } catch (e, s) {
      print("❌ Error handling bid-accepted: $e");
      print(s);
      showError("Error handling bid acceptance");
    }
  }

  void _clearAllRequestsAndTimers() {
    // Cancel all timers
    _timers.forEach((requestId, timer) {
      timer.cancel();
    });
    _timers.clear();

    // Clear data
    requests.clear();
    remainingSeconds.clear();
  }

  // Helper method to manually refresh requests
  void refreshRequests() {
    // You can add API call here to fetch current requests
    print("🔄 Refreshing ride requests");
  }

  @override
  void onClose() {
    // Cleanup timers
    _clearAllRequestsAndTimers();

    // Note: Don't stop the global location service here
    // It should continue running throughout the app lifecycle

    super.onClose();
  }
}