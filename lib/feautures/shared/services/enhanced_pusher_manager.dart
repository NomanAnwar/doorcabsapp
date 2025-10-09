
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
    }
  }

  // ✅ FIXED: Correct parameter name and method signature
  Future<void> subscribeOnce(String channelName, {
    Map<String, void Function(Map<String, dynamic>)>? events,
  }) async {
    await initializeOnce();

    // Check if already subscribed to these events
    final channelEvents = _activeSubscriptions[channelName] ?? {};
    final newEvents = events?.keys.toSet() ?? {};

    if (channelEvents.containsAll(newEvents) && newEvents.isNotEmpty) {
      print('✅ Already subscribed to these events on $channelName');
      return;
    }

    // ✅ FIXED: Pass both channelName AND events to the underlying service
    await _pusher.subscribe(channelName, events: events);

    // Track active subscriptions
    _activeSubscriptions[channelName] = {...channelEvents, ...newEvents};
    print('✅ Subscribed to $channelName with events: $newEvents');
  }

  void unsubscribeSafely(String channelName) {
    _pusher.unsubscribe(channelName);
    _activeSubscriptions.remove(channelName);
    print('✅ Unsubscribed from $channelName');
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