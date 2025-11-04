import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'enhanced_pusher_manager.dart';

@pragma('vm:entry-point') // ✅ ADD THIS
class PusherBackgroundService {
  static final PusherBackgroundService _instance = PusherBackgroundService._internal();
  factory PusherBackgroundService() => _instance;

  @pragma('vm:entry-point') // ✅ ADD THIS
  PusherBackgroundService._internal();

  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
  bool _isRunning = false;

  @pragma('vm:entry-point') // ✅ ADD THIS
  Future<void> initialize() async {
    if (_isRunning) return;

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: false, // ✅ FIX: Changed from true to false
        notificationChannelId: 'doorcab_background',
        initialNotificationTitle: 'DoorCab Running',
        initialNotificationContent: 'Tracking your ride',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );

    _isRunning = true;
  }

  @pragma('vm:entry-point') // ✅ ADD THIS
  static Future<void> _onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Start background Pusher
    final backgroundService = PusherBackgroundService();
    await backgroundService._startBackgroundPusher(service);
  }

  @pragma('vm:entry-point') // ✅ ADD THIS
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point') // ✅ ADD THIS
  Future<void> _startBackgroundPusher(ServiceInstance service) async {
    try {
      await _pusherManager.initialize();

      // Get stored driver context
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('driverId');
      final rideId = prefs.getString('currentRideId');

      if (driverId != null) {
        await _pusherManager.subscribeOnce(
          "private-driver-$driverId",
          events: {
            "ride-request": (data) => _handleBackgroundEvent('ride-request', data, service),
          },
        );

        await _pusherManager.subscribeOnce(
          "driver-$driverId",
          events: {
            "bid-accepted": (data) => _handleBackgroundEvent('bid-accepted', data, service),
            "bid-rejected": (data) => _handleBackgroundEvent('bid-rejected', data, service),
            "bid-ignored": (data) => _handleBackgroundEvent('bid-ignored', data, service),
          },
        );
      }

      if (rideId != null) {
        await _pusherManager.subscribeOnce(
          "ride-$rideId",
          events: {
            "driver-location": (data) => _handleBackgroundEvent('driver-location', data, service),
            "ride-cancelled": (data) => _handleBackgroundEvent('ride-cancelled', data, service),
            "new-message": (data) => _handleBackgroundEvent('new-message', data, service),
          },
        );
      }

      // ✅ FIX: REMOVED setAsForegroundService() call
      // This was causing the crash because we're not in foreground mode

      print('✅ Background Pusher Service Running Successfully');

    } catch (e) {
      print('❌ Background Pusher Error: $e');
    }
  }

  @pragma('vm:entry-point') // ✅ ADD THIS
  // Remove notification methods since we're not in foreground mode
  void _handleBackgroundEvent(String eventType, Map<String, dynamic> data, ServiceInstance service) {
    print('📱 Background Event: $eventType - $data');

    // Store event for when app comes to foreground
    _storeBackgroundEvent(eventType, data);

    // ❌ REMOVE: Can't show notifications in non-foreground mode
    // if (service is AndroidServiceInstance) {
    //   _updateNotificationForEvent(eventType, data, service);
    // }
  }

  @pragma('vm:entry-point') // ✅ ADD THIS
  Future<void> _storeBackgroundEvent(String eventType, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final events = prefs.getStringList('backgroundEvents') ?? [];
    events.add(json.encode({
      'type': eventType,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));
    await prefs.setStringList('backgroundEvents', events);
  }

  @pragma('vm:entry-point') // ✅ ADD THIS
  // ✅ UPDATE: Add driver support
  Future<void> startBackgroundMode(String userId, {String? userType, String? rideId}) async {
    final prefs = await SharedPreferences.getInstance();

    // Store based on user type
    if (userType == 'driver') {
      await prefs.setString('driverId', userId);
    } else {
      await prefs.setString('passengerId', userId);
    }

    if (rideId != null) {
      await prefs.setString('currentRideId', rideId);
    }

    final service = FlutterBackgroundService();
    await service.startService();

    print('🚀 Background Service Started for $userType: $userId');
  }


  @pragma('vm:entry-point') // ✅ ADD THIS
  Future<void> stopBackgroundMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('passengerId');
    await prefs.remove('driverId');
    await prefs.remove('currentRideId');
    await prefs.remove('backgroundEvents');

    final service = FlutterBackgroundService();
    service.invoke('stopService');

    print('🛑 Background Service Stopped');
  }

  @pragma('vm:entry-point') // ✅ ADD THIS
  Future<List<Map<String, dynamic>>> getPendingEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final events = prefs.getStringList('backgroundEvents') ?? [];
    await prefs.remove('backgroundEvents');

    return events.map((e) {
      try {
        return json.decode(e) as Map<String, dynamic>;
      } catch (e) {
        return {'type': 'error', 'data': {'error': 'Invalid event format'}};
      }
    }).toList();
  }
}