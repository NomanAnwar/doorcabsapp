import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../../../utils/http/http_client.dart';
import 'storage_service.dart';

class PusherChannelsService {
  static final PusherChannelsService _instance = PusherChannelsService._internal();
  factory PusherChannelsService() => _instance;
  PusherChannelsService._internal();

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  // Track multiple subscriptions (driver + passenger)
  final Set<String> _subscribedChannels = {};

  Future<void> initialize({
    String? driverId,
    String? passengerId,
    void Function(Map<String, dynamic>)? onRideRequest,
    void Function(Map<String, dynamic>)? onNewBid,
    void Function(Map<String, dynamic>)? onNearbyDrivers,
  }) async {
    try {
      final role = StorageService.getRole(); // "Driver" OR "Passenger"

      await _pusher.init(
        apiKey: "7a908f19197d8285cfe9",
        cluster: "ap2",

        authEndpoint: "${FHttpHelper.baseUrl}/pusher/auth",

        onAuthorizer: (channelName, socketId, options) async {
          try {
            final response = await FHttpHelper.post(
              "pusher/auth",
              {
                "socket_id": socketId,
                "channel_name": channelName,
              },
            );
            return response;
          } catch (e) {
            print("❌ Auth failed for $channelName : $e");
            rethrow;
          }
        },

        onConnectionStateChange: (String currentState, String previousState) {
          print("🔌 Connection state: $previousState → $currentState");
        },

        onError: (String message, int? code, dynamic e) {
          print("❌ Pusher error: $message (code: $code) $e");
        },

        onSubscriptionSucceeded: (String channelName, dynamic data) {
          print("✅ Subscribed to $channelName");
        },

        onEvent: (PusherEvent event) {
          print("📨 Event received: ${event.eventName} → ${event.data}");
          try {
            final data = jsonDecode(event.data);

            // Driver receives ride requests
            if (event.eventName == "ride-request" && onRideRequest != null) {
              onRideRequest(data);
            }

            // Passenger receives new bids
            if (event.eventName == "new-bid" && onNewBid != null) {
              onNewBid(data);
            }

            // Passenger receives nearby drivers
            // if (event.eventName == "nearby-drivers" && onNearbyDrivers != null) {
            //   onNearbyDrivers(data);
            // }
          } catch (e) {
            print("❌ Failed to parse event data: $e");
          }
        },
      );

      await _pusher.connect();

      // Subscribe based on role
      if (role == "Driver" && driverId != null) {
        final driverChannel = "private-driver-$driverId";
        await subscribe(driverChannel);
      } else if (role == "Passenger" && passengerId != null) {
        final passengerChannel = "passenger-$passengerId";
        await subscribe(passengerChannel);
      }
    } catch (e) {
      print("❌ Error initializing Pusher: $e");
    }
  }


  Future<void> subscribe(String channelName) async {
    try {
      if (_subscribedChannels.contains(channelName)) return;

      await _pusher.subscribe(channelName: channelName);
      _subscribedChannels.add(channelName);

      print("✅ Subscribed to $channelName");
    } catch (e) {
      print("❌ Failed to subscribe: $e");
    }
  }

  Future<void> unsubscribe(String channelName) async {
    if (_subscribedChannels.contains(channelName)) {
      try {
        await _pusher.unsubscribe(channelName: channelName);
        _subscribedChannels.remove(channelName);
        print("🚫 Unsubscribed from $channelName");
      } catch (e) {
        print("❌ Failed to unsubscribe: $e");
      }
    }
  }

  Future<void> disconnect() async {
    for (final channel in _subscribedChannels) {
      await _pusher.unsubscribe(channelName: channel);
    }
    _subscribedChannels.clear();
    await _pusher.disconnect();
  }
}
