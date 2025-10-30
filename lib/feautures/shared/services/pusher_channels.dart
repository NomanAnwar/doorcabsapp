// pusher_channels.dart
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

  // ✅ NEW: Track event handlers per channel per event as LIST (so multiple listeners can register)
  // channelName -> eventName -> list of handlers
  final Map<String, Map<String, List<void Function(Map<String, dynamic>)>>> _eventHandlers = {};

  // Initialize only once
  Future<void> initialize() async {
    try {
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
        // central event handler
        onEvent: _onEvent,
      );

      await _pusher.connect();
      print("🔗 Pusher connected");
    } catch (e) {
      print("❌ Error initializing Pusher: $e");
    }
  }

  // Subscribe: accepts events map like {"bid-accepted": (data) => ...}
  Future<void> subscribe(String channelName, {
    Map<String, void Function(Map<String, dynamic>)>? events,
  }) async {
    try {
      if (!_subscribedChannels.contains(channelName)) {
        await _pusher.subscribe(channelName: channelName);
        _subscribedChannels.add(channelName);
        print("✅ Subscribed to $channelName");
      }

      // Merge (append) new event handlers with existing ones (support multiple handlers)
      if (events != null) {
        _eventHandlers.putIfAbsent(channelName, () => <String, List<void Function(Map<String, dynamic>)>>{});
        final channelMap = _eventHandlers[channelName]!;

        events.forEach((eventName, handler) {
          channelMap.putIfAbsent(eventName, () => <void Function(Map<String, dynamic>)>[]);
          channelMap[eventName]!.add(handler);
          print("➕ Handler added for event '$eventName' on channel '$channelName' (total: ${channelMap[eventName]!.length})");
        });
      }
    } catch (e) {
      print("❌ Failed to subscribe: $e");
    }
  }

  // Central dispatcher: safe payload parsing + calling all registered handlers
  void _onEvent(PusherEvent event) {
    try {
      final channel = event.channelName ?? '';
      final eventName = event.eventName ?? '';
      print("📨 Event received: $eventName from $channel (raw data: ${event.data})");

      // Parse payload robustly: event.data may be a JSON string, a Map, or something else
      dynamic parsed;
      if (event.data == null) {
        parsed = <String, dynamic>{};
      } else if (event.data is String) {
        final s = (event.data as String).trim();
        try {
          parsed = jsonDecode(s);
        } catch (e) {
          // if not JSON, wrap it
          parsed = {'_raw': s};
        }
      } else if (event.data is Map) {
        parsed = Map<String, dynamic>.from(event.data as Map);
      } else {
        // other types (list, number, etc.)
        parsed = {'_payload': event.data};
      }

      final Map<String, dynamic> dataMap = (parsed is Map) ? Map<String, dynamic>.from(parsed) : {'payload': parsed};

      final channelMap = _eventHandlers[channel];
      final handlers = channelMap?[eventName];

      if (handlers == null || handlers.isEmpty) {
        print("⚠️ No handlers registered for event '$eventName' on channel '$channel'");
        return;
      }

      for (final h in handlers) {
        try {
          h(dataMap);
        } catch (e, st) {
          print("❌ Handler error for $eventName on $channel: $e\n$st");
        }
      }
    } catch (e, st) {
      print("❌ _onEvent failed: $e\n$st");
    }
  }

  Future<void> unsubscribe(String channelName) async {
    if (_subscribedChannels.contains(channelName)) {
      try {
        await _pusher.unsubscribe(channelName: channelName);
        _subscribedChannels.remove(channelName);
        _eventHandlers.remove(channelName); // cleanup handlers
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
    _eventHandlers.clear();
    await _pusher.disconnect();
  }
}
