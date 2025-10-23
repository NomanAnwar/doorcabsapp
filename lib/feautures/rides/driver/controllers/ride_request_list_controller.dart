import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:doorcab/feautures/shared/services/pusher_channels.dart';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:get/get.dart';
import '../../../../main.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/driver_location_service.dart';
import '../../../shared/services/pusher_beams.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';
import '../models/request_model.dart';

class RideRequestListController extends BaseController {
  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
  final PusherChannelsService _pusherChannel = PusherChannelsService();
  final DriverLocationService _driverLocationService = DriverLocationService();

  final requests = <RequestModel>[].obs;
  final isOnline = false.obs;

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
    final wasOnline = StorageService.getDriverOnlineStatus();
    if (wasOnline) {
      print('🔄 Restoring previous online status: $wasOnline');
      toggleOnline(true);
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

  void toggleOnline(bool val) async {
    if (isOnline.value == val) {
      print('ℹ️ Driver already ${val ? 'online' : 'offline'}, skipping');
      return;
    }

    isOnline.value = val;
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
        await _driverLocationService.start();
        print("📍 Location service started");
        await _subscribeToChannels(driverId);
        showSuccess('You are now online and receiving ride requests');
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
        showSuccess('You are now offline');
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

      // FSnackbar.show(
      //     title: "Bid Ignored",
      //     message: "Passenger ignored your bid",
      //     isError: true
      // );
    } catch (e, s) {
      print("❌ Error handling bid-ignored: $e");
      print(s);
    }
  }

  // Future<void> _subscribeToChannels(String driverId) async {
  //   final privateChannel = "private-driver-$driverId";
  //   final driverChannel = "driver-$driverId";
  //
  //   try {
  //     await executeWithRetry(() async {
  //       // Subscribe to private driver channel for ride requests
  //       if (!_subscribedChannels.contains(privateChannel)) {
  //         await _pusherManager.subscribeOnce(
  //           privateChannel,
  //           events: {
  //             "ride-request": (data) {
  //               _handleNewRideRequest(data);
  //             },
  //           },
  //         );
  //         _subscribedChannels.add(privateChannel);
  //         print("✅ RideRequestListController subscribed to: $privateChannel");
  //       }
  //
  //       // Subscribe to driver channel for bid acceptance
  //       if (!_subscribedChannels.contains(driverChannel)) {
  //         await _pusherManager.subscribeOnce(
  //           driverChannel,
  //           events: {
  //             "bid-accepted": (eventData) {
  //               _handleBidAccepted(eventData);
  //             },
  //             "bid-ignored": (eventData) {
  //               FSnackbar.show(title: "bid ignored", message: eventData.toString());
  //               // _handleBidAccepted(eventData);
  //             },
  //             "bid-rejected": (eventData) {
  //               FSnackbar.show(title: "bid rejected", message: eventData.toString());
  //               // _handleBidAccepted(eventData);
  //             },
  //           },
  //         );
  //         _subscribedChannels.add(driverChannel);
  //         print("✅ RideRequestListController subscribed to: $driverChannel");
  //       }
  //     });
  //   } catch (e) {
  //     print('❌ Error subscribing to channels: $e');
  //     rethrow;
  //   }
  // }

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
                _handleBidIgnored(eventData); // Use the new handler
              },
              "bid-rejected": (eventData) {
                // FSnackbar.show(title: "Bid Rejected", message: eventData.toString());
                FSnackbar.show(title: "Bid Rejected", message: "Offer best fare to passenger.");
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

  // void _handleNewRideRequest(Map<String, dynamic> data) {
  //   print("🚖 New ride request received in RideRequestListController: $data");
  //
  //   try {
  //     final request = RequestModel.fromJson(data);
  //
  //     // Check for duplicate requests
  //     if (requests.any((r) => r.id == request.id)) {
  //       print('ℹ️ Request ${request.id} already exists, skipping');
  //       return;
  //     }
  //
  //     requests.add(request);
  //
  //     print("✅ Added request: ${request.id}, Passenger: ${request.passengerName}");
  //
  //     // Show notification
  //     FSnackbar.show(title:'New Ride Request',message:
  //       'From ${request.passengerName} - ${request.offerAmount} PKR',
  //     );
  //   } catch (e, s) {
  //     print("❌ Error parsing ride request: $e");
  //     print("📦 Raw data: $data");
  //     print(s);
  //   }
  // }

  void _handleNewRideRequest(Map<String, dynamic> data) {
    print("🚖 New ride request received in RideRequestListController: $data");

    try {
      final request = RequestModel.fromJson(data);

      // Check for existing request with same ID
      final existingIndex = requests.indexWhere((r) => r.id == request.id);

      if (existingIndex >= 0) {
        // UPDATE EXISTING REQUEST
        final oldRequest = requests[existingIndex];
        requests[existingIndex] = request;

        print("🔄 Updated existing request: ${request.id}, Passenger: ${request.passengerName}");

        // Show update notification
        FSnackbar.show(
          title: 'Ride Request Updated',
          message: '${request.passengerName} updated their request - ${request.offerAmount} PKR',
        );
      } else {
        // ADD NEW REQUEST
        requests.add(request);
        print("✅ Added new request: ${request.id}, Passenger: ${request.passengerName}");

        // Show new request notification
        FSnackbar.show(
          title: 'New Ride Request',
          message: 'From ${request.passengerName} - ${request.offerAmount} PKR',
        );
      }

    } catch (e, s) {
      print("❌ Error parsing ride request: $e");
      print("📦 Raw data: $data");
      print(s);

      // Show error notification
      FSnackbar.show(
        title: 'Error',
        message: 'Failed to process ride request',
        isError: true
      );
    }
  }

  void _handleBidAccepted(Map<String, dynamic> eventData) {
    print("✅ bid-accepted event received: $eventData");

    try {
      final rideId = eventData['rideId']?.toString() ?? "";
      if (rideId.isNotEmpty) {
        requests.removeWhere((r) => r.id == rideId);
      }
      _clearAllRequests();
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
    _clearAllRequests();
    super.onClose();
  }
}