import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:doorcab/feautures/shared/services/pusher_channels.dart';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:doorcab/utils/http/http_client.dart';
import 'package:get/get.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/driver_location_service.dart';
import '../../../shared/services/pusher_background_service.dart';
import '../../../shared/services/pusher_beams.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';
import '../models/request_model.dart';
import '../screens/go_online_screen.dart';
import 'package:collection/collection.dart';


class RideRequestListController extends BaseController {
  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
  final DriverLocationService _driverLocationService = DriverLocationService();

  final requests = <RequestModel>[].obs;
  final isOnline = false.obs;
  final isLoadingToggle = false.obs; // ADD THIS for loading state

  bool _beamsInitialized = false;
  final Set<String> _subscribedChannels = {};

  @override
  void onInit() {
    super.onInit();

    _subscribedChannels.clear();
    _initializePushNotifications();
    _restoreOnlineStatus();
    _handleInitialRequest();
  }

  void _restoreOnlineStatus() {
    final wasOnline = StorageService.getDriverOnlineStatus();
    if (wasOnline) {
      print('🔄 Restoring previous online status: $wasOnline');
      isOnline.value = true;
      _subscribeToChannels(StorageService.getSignUpResponse()!.userId);
    }
  }

  void _handleInitialRequest() {
    final arguments = Get.arguments;
    if (arguments != null && arguments['initialRequest'] != null) {
      final RequestModel initialRequest = arguments['initialRequest'];
      print("✅ Received initial request from GoOnlineScreen: ${initialRequest.id}");

      if (!requests.any((r) => r.id == initialRequest.id)) {
        requests.add(initialRequest);
      }
    }
  }

  Future<void> _initializePushNotifications() async {
    if (!_beamsInitialized) {
      try {
        _beamsInitialized = true;
        print('ℹ️ Beams already initialized globally, skipping re-initialization');
      } catch (e) {
        print('⚠️ _initializePushNotifications: $e');
      }
    }
  }

  void acceptRequest(RequestModel request) {
    Get.toNamed('/ride-request-detail', arguments: {'request': request})?.then((result) {
      try {
        if (result == 'accepted') {
          final idx = requests.indexWhere((r) => r.id == request.id);
          if (idx >= 0) requests.removeAt(idx);
        } else {
          print('ℹ️ Returned from detail screen, result: $result');
        }
      } catch (e) {
        print('❌ Error handling result from detail screen: $e');
      }
    });
  }

  void rejectRequest(String requestId) {
    requests.removeWhere((r) => r.id == requestId);
    showError('You rejected the request');
  }

  // UPDATED METHOD WITH ENDPOINT CALL
  Future<void> toggleOnline(bool val) async {
    if (isOnline.value == val) {
      print('ℹ️ Driver already ${val ? 'online' : 'offline'}, skipping');
      return;
    }

    // Show loading immediately
    isLoadingToggle(true);

    try {
      final body = {"is_online": val};
      final token = StorageService.getAuthToken();

      if (token == null) {
        FSnackbar.show(title: "Error", message: "User token not found. Please login again.", isError: true);
        isLoadingToggle(false);
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response = await FHttpHelper.post("driver/online", body);
      print("Driver online API response: $response");

      final serverStatus = response['is_online'] ?? false;

      // Update local state based on server response
      isOnline.value = serverStatus;
      await StorageService.setDriverOnlineStatus(serverStatus);

      if (serverStatus) {
        await _goOnline();
        FSnackbar.show(title: "Online", message: response['message'] ?? "You are now online");
      } else {
        await _goOffline();
        FSnackbar.show(title: "Offline", message: response['message'] ?? "You are now offline", isError: true);

        // Navigate back to GoOnlineScreen when successfully offline
        // Get.offAllNamed('/go-online');
        Get.offAll(() => GoOnlineScreen());
      }

    } catch (e, s) {
      print("❌ toggleOnline error: $e\n$s");
      FSnackbar.show(title: "Error", message: "Failed to toggle online status", isError: true);
      // Revert the toggle if API call fails
      isOnline.value = !val;
    } finally {
      isLoadingToggle(false);
    }
  }

  Future<void> _goOnline() async {
    final driverId = StorageService.getSignUpResponse()!.userId;
    print("🚖 Driver going online: $driverId");

    try {
      await executeWithRetry(() async {
        await _driverLocationService.start();
        print("📍 Location service started");

        // ✅ ADD: Start background service
        await PusherBackgroundService().startBackgroundMode(
          driverId,
          userType: 'driver', // ✅ ADD THIS LINE
        );
        await _subscribeToChannels(driverId);
      });
    } catch (e) {
      print('❌ Error going online: $e');
      isOnline.value = false;
      showError('Failed to go online: $e');
    }
  }

  Future<void> _goOffline() async {
    print("🚫 Driver going offline");
    try {
      await executeWithRetry(() async {
        _driverLocationService.pause();
        print("📍 Location service paused");
        await _unsubscribeFromChannels();
        _clearAllRequests();

        // ✅ ADD: Stop background service
        PusherBackgroundService().stopBackgroundMode();
      });
    } catch (e) {
      print('❌ Error going offline: $e');
      showError('Failed to go offline');
    }
  }

  void _handleBidIgnored(Map<String, dynamic> eventData) {
    print("❌ bid-ignored event received: $eventData");

    try {
      final rideId = eventData['rideId']?.toString() ?? "";
      if (rideId.isNotEmpty) {
        // Remove the request from the list
        requests.removeWhere((r) => r.id == rideId);
        print("🗑️ Removed request $rideId from list due to bid ignored");
      }
    } catch (e, s) {
      print("❌ Error handling bid-ignored: $e");
      print(s);
    }
  }

  // ✅ NEW: Handle ride-closed event
  void _handleRideClosed(Map<String, dynamic> eventData) {
    print("🚫 ride-closed event received in ride list controller: $eventData");

    try {
      final rideId = eventData['rideId']?.toString() ?? "";
      final message = eventData['message']?.toString() ?? "Ride is no longer available";

      if (rideId.isNotEmpty) {
        // Remove the request from the list
        final removed = requests.any((r) => r.id == rideId);
        requests.removeWhere((r) => r.id == rideId);

        print("🗑️ Removed request $rideId from list due to ride-closed event");

        // Show notification to user
        // if (removed) {
          // FSnackbar.show(
          //   title: "Ride Closed",
          //   message: message,
          //   isError: true,
          // );
        // }
      }
    } catch (e, s) {
      print("❌ Error handling ride-closed: $e");
      print(s);
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
          print("✅ RideRequestListController subscribed to: $privateChannel");
        }

        // Subscribe to driver channel for bid acceptance
        if (!_subscribedChannels.contains(driverChannel)) {
          await _pusherManager.subscribeOnce(
            driverChannel,
            events: {
              "bid-accepted": (eventData) {
                _handleBidAccepted(eventData);
              },
              "bid-ignored": (eventData) {
                _handleBidIgnored(eventData);
              },
              "bid-rejected": (eventData) {
                FSnackbar.show(title: "Bid Rejected", message: "Offer best fare to passenger.");
              },
              // ✅ ADD: ride-closed event
              "ride-closed": (eventData) {
                _handleRideClosed(eventData);
              },
            },
          );
          _subscribedChannels.add(driverChannel);
          print("✅ RideRequestListController subscribed to: $driverChannel");
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
        for (final channel in _subscribedChannels) {
          _pusherManager.unsubscribeSafely(channel);
          print("✅ RideRequestListController unsubscribed from: $channel");
        }
        _subscribedChannels.clear();
      });
    } catch (e) {
      print('❌ Error unsubscribing from channels: $e');
    }
  }

  void _handleNewRideRequest(Map<String, dynamic> data) {
    print("🚖 New ride request received in RideRequestListController: $data");

    try {
      final request = RequestModel.fromJson(data);

      final existingIndex = requests.indexWhere((r) => r.id == request.id);

      if (existingIndex >= 0) {
        final oldRequest = requests[existingIndex];

        // ✅ Only update if data actually changed (ignoring createdAt)
        if (!_isSameRequestData(oldRequest, request)) {
          requests[existingIndex] = request;
          print("🔄 Updated existing request: ${request.id}");
          FSnackbar.show(
            title: 'Ride Request Updated',
            message:
            '${request.passengerName} updated their request - ${request.offerAmount} PKR',
          );
        } else {
          print("⏸ No actual change in request ${request.id}, skipping update");
        }
      } else {
        requests.add(request);
        print("✅ Added new request: ${request.id}");
      }
    } catch (e, s) {
      print("❌ Error parsing ride request: $e");
      print("📦 Raw data: $data");
      print(s);

      FSnackbar.show(
          title: 'Error',
          message: 'Failed to process ride request',
          isError: true);
    }
  }

  bool _isSameRequestData(RequestModel oldRequest, RequestModel newRequest) {
    final oldJson = Map<String, dynamic>.from(oldRequest.toJson());
    final newJson = Map<String, dynamic>.from(newRequest.toJson());

    // Remove volatile fields
    oldJson.remove('createdAt');
    oldJson.remove('distanceKm');
    newJson.remove('createdAt');
    newJson.remove('distanceKm');

    // Use DeepCollectionEquality to handle nested maps/lists
    final equality = const DeepCollectionEquality();

    return equality.equals(oldJson, newJson);
  }




  void _handleBidAccepted(Map<String, dynamic> eventData) {
    print("✅ bid-accepted event received: $eventData");

    try {
      final rideId = eventData['rideId']?.toString() ?? "";
      if (rideId.isNotEmpty) {
        requests.removeWhere((r) => r.id == rideId);
      }
      _clearAllRequests();
      _unsubscribeFromChannels();
      Get.offNamed('/go-to-pickup', arguments: {"rideData": eventData});
    } catch (e, s) {
      print("❌ Error handling bid-accepted: $e");
      print(s);
      showError("Error handling bid acceptance");
    }
  }

  void _clearAllRequests() {
    requests.clear();
  }

  void refreshRequests() {
    print("🔄 Refreshing ride requests");
  }

  @override
  void onClose() {
    _unsubscribeFromChannels();
    _clearAllRequests();
    super.onClose();
  }
}