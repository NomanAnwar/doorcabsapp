import 'package:doorcab/common/widgets/snakbar/snackbar.dart';

import 'pusher_channels.dart';

class EnhancedPusherManager {
  static final EnhancedPusherManager _instance = EnhancedPusherManager._internal();
  factory EnhancedPusherManager() => _instance;
  EnhancedPusherManager._internal();

  final PusherChannelsService _pusher = PusherChannelsService();
  final Map<String, Set<String>> _activeSubscriptions = {}; // channel -> events
  bool _isInitialized = false;

  Future<void> initializeOnce() async {
    if (!_isInitialized) {
      await _pusher.initialize();
      _isInitialized = true;
      print('✅ EnhancedPusherManager initialized once');
      // FSnackbar.show(title: 'Manager', message: 'EnhancedPusherManager initialized');
    }
  }

  // ✅ FIXED: Remove the blocking check to allow multiple event listeners
  Future<void> subscribeOnce(String channelName, {
    Map<String, void Function(Map<String, dynamic>)>? events,
  }) async {
    await initializeOnce();

    // ✅ REMOVED: The blocking check that was preventing multiple controllers from listening
    // Always subscribe - PusherChannelsService can handle multiple event handlers
    await _pusher.subscribe(channelName, events: events);

    // Track active subscriptions (for logging/debugging only)
    final channelEvents = _activeSubscriptions[channelName] ?? {};
    final newEvents = events?.keys.toSet() ?? {};
    _activeSubscriptions[channelName] = {...channelEvents, ...newEvents};

    print('✅ Subscribed to $channelName with events: $newEvents');
    // FSnackbar.show(title: 'Channel', message: 'Subscribed to $channelName with events: $newEvents');
  }

  void unsubscribeSafely(String channelName) {
    _pusher.unsubscribe(channelName);
    _activeSubscriptions.remove(channelName);
    print('✅ Unsubscribed from $channelName');
    // FSnackbar.show(title: 'Channel', message: 'Unsubscribed from $channelName');
  }

  // Getters for existing functionality
  PusherChannelsService get pusher => _pusher;

  // Check if already subscribed
  bool isSubscribedTo(String channelName, [String? eventName]) {
    if (!_activeSubscriptions.containsKey(channelName)) return false;
    if (eventName == null) return true;
    return _activeSubscriptions[channelName]!.contains(eventName);
  }
}