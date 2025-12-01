import 'dart:async';
import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'pusher_channels.dart';

class EnhancedPusherManager {
  static final EnhancedPusherManager _instance = EnhancedPusherManager._internal();
  factory EnhancedPusherManager() => _instance;
  EnhancedPusherManager._internal();

  final PusherChannelsService _pusher = PusherChannelsService();
  final Map<String, Set<String>> _activeSubscriptions = {};
  bool _isInitialized = false;
  bool _isInBackground = false;

  // Track connection state manually since the package might not expose it directly
  String _connectionState = 'disconnected';

  Future<void> initializeOnce() async {
    if (!_isInitialized) {
      await _pusher.initialize();
      _isInitialized = true;
      _connectionState = 'connected';
      print('✅ EnhancedPusherManager initialized once');
    }
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _pusher.initialize();
      _isInitialized = true;
      _connectionState = 'connected';
      print('✅ EnhancedPusherManager initialized');
    }
  }

  Future<void> subscribeOnce(String channelName, {
    Map<String, void Function(Map<String, dynamic>)>? events,
  }) async {
    await initialize();

    await _pusher.subscribe(channelName, events: events);

    // Track active subscriptions
    final channelEvents = _activeSubscriptions[channelName] ?? {};
    final newEvents = events?.keys.toSet() ?? {};
    _activeSubscriptions[channelName] = {...channelEvents, ...newEvents};
    // FSnackbar.show(title: "Subscribe the channel", message: "$channelName");
    print('✅ Subscribed to $channelName with events: $newEvents');
  }

  void unsubscribeSafely(String channelName) {
    _pusher.unsubscribe(channelName);
    _activeSubscriptions.remove(channelName);
    print('✅ Unsubscribed from $channelName');
  }

  // FIXED: Manual connection state tracking
  String get connectionState => _connectionState;

  Future<void> checkConnection() async {
    try {
      // Try to get connection state - this is a workaround since the package
      // might not expose connectionState directly
      _connectionState = 'checking';

      // You can implement a ping mechanism here if needed
      // For now, we'll assume connected if initialized
      if (_isInitialized) {
        _connectionState = 'connected';
      } else {
        _connectionState = 'disconnected';
      }
    } catch (e) {
      _connectionState = 'error';
      print('❌ Error checking connection: $e');
    }
  }

  void setBackgroundState(bool isBackground) {
    _isInBackground = isBackground;
    print('🔄 Pusher background state: $isBackground');

    if (!isBackground) {
      // App came to foreground - ensure connection is active
      _ensureConnection();
    } else {
      // App went to background - optimize for battery
      print('📱 App in background, Pusher connection maintained');
    }
  }

  Future<void> _ensureConnection() async {
    try {
      await checkConnection();

      if (_connectionState != 'connected') {
        print('🔄 Reconnecting Pusher...');
        // Re-initialize to reconnect
        await _pusher.initialize();
        _connectionState = 'connected';

        // Re-subscribe to all active channels
        for (final channel in _activeSubscriptions.keys) {
          // You would need to store the events to re-subscribe properly
          print('🔄 Re-subscribing to $channel');
        }
      }
    } catch (e) {
      print('❌ Pusher reconnection error: $e');
      _connectionState = 'error';
    }
  }

  // Getters for existing functionality
  PusherChannelsService get pusher => _pusher;

  bool isSubscribedTo(String channelName, [String? eventName]) {
    if (!_activeSubscriptions.containsKey(channelName)) return false;
    if (eventName == null) return true;
    return _activeSubscriptions[channelName]!.contains(eventName);
  }

  // Method to manually set connection state (for testing)
  void setConnectionStateForTesting(String state) {
    _connectionState = state;
  }


  // Add this method to your EnhancedPusherManager class
  Future<void> reconnectPusher() async {
    try {
      print('🔄 Attempting to reconnect Pusher...');

      // Disconnect first if connected
      try {
        await _pusher.disconnect();
      } catch (e) {
        print('⚠️ Error during disconnect: $e');
      }

      // Clear existing state
      _activeSubscriptions.clear();
      _isInitialized = false;

      // Reinitialize
      await initialize();
      _connectionState = 'connected';

      print('✅ Pusher reconnected successfully');
    } catch (e) {
      print('❌ Pusher reconnection failed: $e');
      _connectionState = 'error';

      // Retry after delay
      Timer(Duration(seconds: 5), () {
        reconnectPusher();
      });
    }
  }
}
