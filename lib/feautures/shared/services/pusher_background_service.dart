import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'enhanced_pusher_manager.dart';

@pragma('vm:entry-point')
class PusherBackgroundService {
  static final PusherBackgroundService _instance = PusherBackgroundService._internal();
  factory PusherBackgroundService() => _instance;

  @pragma('vm:entry-point')
  PusherBackgroundService._internal();

  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
  bool _isRunning = false;
  Timer? _keepAliveTimer;

  @pragma('vm:entry-point')
  Future<void> initialize() async {
    if (_isRunning) return;

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true, // ✅ Keep as true for better survival
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

  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    // ✅ IMPORTANT: Set up notification immediately for Android
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "DoorCab Running",
        content: "Tracking your ride...",
      );
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Start background Pusher with proper error handling
    final backgroundService = PusherBackgroundService();
    await backgroundService._startBackgroundPusher(service);
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    final backgroundService = PusherBackgroundService();
    await backgroundService._startBackgroundPusher(service);
    return true;
  }

  @pragma('vm:entry-point')
  Future<void> _startBackgroundPusher(ServiceInstance service) async {
    try {
      print('🚀 Starting Background Pusher Service...');

      // Initialize Pusher with retry logic
      await _initializePusherWithRetry();

      // Get stored driver context
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('driverId');
      final passengerId = prefs.getString('passengerId');
      final rideId = prefs.getString('currentRideId');

      print('📱 Background Service Context - Driver: $driverId, Passenger: $passengerId, Ride: $rideId');

      // Subscribe based on user type
      if (driverId != null) {
        await _subscribeToDriverChannels(driverId, service);
      }

      if (passengerId != null) {
        await _subscribeToPassengerChannels(passengerId, service);
      }

      if (rideId != null) {
        await _subscribeToRideChannels(rideId, service);
      }

      // ✅ Start keep-alive mechanism
      // _startKeepAliveMechanism(service);

      print('✅ Background Pusher Service Running Successfully');

    } catch (e) {
      print('❌ Background Pusher Error: $e');
      // Retry after delay
      Timer(Duration(seconds: 5), () {
        _startBackgroundPusher(service);
      });
    }
  }

  Future<void> _initializePusherWithRetry() async {
    try {
      await _pusherManager.initialize();
    } catch (e) {
      print('❌ Pusher initialization failed, retrying...: $e');
      await Future.delayed(Duration(seconds: 3));
      await _pusherManager.initialize();
    }
  }

  Future<void> _subscribeToDriverChannels(String driverId, ServiceInstance service) async {
    try {
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
          "ride-closed": (data) => _handleBackgroundEvent('ride-closed', data, service),
        },
      );
    } catch (e) {
      print('❌ Driver channel subscription error: $e');
    }
  }

  Future<void> _subscribeToPassengerChannels(String passengerId, ServiceInstance service) async {
    try {
      await _pusherManager.subscribeOnce(
        "private-passenger-$passengerId",
        events: {
          "ride-update": (data) => _handleBackgroundEvent('ride-update', data, service),
        },
      );
    } catch (e) {
      print('❌ Passenger channel subscription error: $e');
    }
  }

  Future<void> _subscribeToRideChannels(String rideId, ServiceInstance service) async {
    try {
      await _pusherManager.subscribeOnce(
        "ride-$rideId",
        events: {
          "driver-location": (data) => _handleBackgroundEvent('driver-location', data, service),
          "ride-cancelled": (data) => _handleBackgroundEvent('ride-cancelled', data, service),
          "new-message": (data) => _handleBackgroundEvent('new-message', data, service),
          "ride-started": (data) => _handleBackgroundEvent('ride-started', data, service),
          "ride-ended": (data) => _handleBackgroundEvent('ride-ended', data, service),
          "driver-arrived": (data) => _handleBackgroundEvent('driver-arrived', data, service),
        },
      );
    } catch (e) {
      print('❌ Ride channel subscription error: $e');
    }
  }

  void _startKeepAliveMechanism(ServiceInstance service) {
    // Cancel existing timer
    _keepAliveTimer?.cancel();

    // Update notification periodically to keep service alive
    _keepAliveTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      try {
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "DoorCab Running",
            content: "Time Now ${DateTime.now().toString().substring(11, 16)}",
          );
        }

        // Check Pusher connection and reconnect if needed
        await _pusherManager.checkConnection();

        print('🫀 Background Service Keep-Alive - ${DateTime.now()}');
      } catch (e) {
        print('❌ Keep-alive error: $e');
      }
    });
  }

  @pragma('vm:entry-point')
  void _handleBackgroundEvent(String eventType, Map<String, dynamic> data, ServiceInstance service) {
    print('📱 Background Event: $eventType - $data');

    // Store event for when app comes to foreground
    storeBackgroundEvent(eventType, data);

    // ✅ Update notification to show latest event
    if (service is AndroidServiceInstance) {
      _updateNotificationForEvent(eventType, data, service);
    }
  }

  void _updateNotificationForEvent(String eventType, Map<String, dynamic> data, AndroidServiceInstance service) {
    try {
      String content = "Event: $eventType";

      // Customize notification based on event type
      switch (eventType) {
        case 'driver-location':
          content = "Driver location updated";
          break;
        case 'ride-request':
          content = "New ride request";
          break;
        case 'new-message':
          content = "New message received";
          break;
        case 'ride-cancelled':
          content = "Ride cancelled";
          break;
      }

      service.setForegroundNotificationInfo(
        title: "DoorCab Update",
        content: content,
      );
    } catch (e) {
      print('❌ Notification update error: $e');
    }
  }

  @pragma('vm:entry-point')
  Future<void> storeBackgroundEvent(String eventType, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final events = prefs.getStringList('backgroundEvents') ?? [];

      // Limit stored events to prevent overflow
      if (events.length > 50) {
        events.removeAt(0);
      }

      events.add(json.encode({
        'type': eventType,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));

      await prefs.setStringList('backgroundEvents', events);
    } catch (e) {
      print('❌ Error storing background event: $e');
    }
  }

  @pragma('vm:entry-point')
  Future<void> startBackgroundMode(String userId, {String? userType, String? rideId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Store based on user type
      if (userType == 'driver') {
        await prefs.setString('driverId', userId);
        await prefs.remove('passengerId');
      } else {
        await prefs.setString('passengerId', userId);
        await prefs.remove('driverId');
      }

      if (rideId != null) {
        await prefs.setString('currentRideId', rideId);
      }

      // Store user type for reconnection
      await prefs.setString('backgroundUserType', userType ?? 'passenger');

      final service = FlutterBackgroundService();

      // Ensure service is initialized
      await initialize();

      // Start service
      if (await service.isRunning()) {
        service.invoke('restartService');
      } else {
        await service.startService();
      }

      print('🚀 Background Service Started for $userType: $userId, Ride: $rideId');
    } catch (e) {
      print('❌ Error starting background mode: $e');
    }
  }

  @pragma('vm:entry-point')
  Future<void> stopBackgroundMode() async {
    try {
      _keepAliveTimer?.cancel();
      _keepAliveTimer = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('passengerId');
      await prefs.remove('driverId');
      await prefs.remove('currentRideId');
      await prefs.remove('backgroundUserType');
      await prefs.remove('backgroundEvents');

      final service = FlutterBackgroundService();
      service.invoke('stopService');

      print('🛑 Background Service Stopped');
    } catch (e) {
      print('❌ Error stopping background mode: $e');
    }
  }

  @pragma('vm:entry-point')
  Future<List<Map<String, dynamic>>> getPendingEvents() async {
    try {
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
    } catch (e) {
      print('❌ Error getting pending events: $e');
      return [];
    }
  }

  Future<bool> isBackgroundServiceRunning() async {
    final service = FlutterBackgroundService();
    return service.isRunning();
  }

  @pragma('vm:entry-point')
  Future<void> updateRideContext({String? rideId, String? userType}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (rideId != null) {
        await prefs.setString('currentRideId', rideId);
      }
      if (userType != null) {
        await prefs.setString('backgroundUserType', userType);
      }
      print('🔄 Updated background context - Ride: $rideId, UserType: $userType');
    } catch (e) {
      print('❌ Error updating background context: $e');
    }
  }

  @pragma('vm:entry-point')
  Future<Map<String, dynamic>> getBackgroundContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'driverId': prefs.getString('driverId'),
        'passengerId': prefs.getString('passengerId'),
        'rideId': prefs.getString('currentRideId'),
        'userType': prefs.getString('backgroundUserType'),
      };
    } catch (e) {
      print('❌ Error getting background context: $e');
      return {};
    }
  }

}

// import 'dart:convert';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'enhanced_pusher_manager.dart';
//
// @pragma('vm:entry-point') // ✅ ADD THIS
// class PusherBackgroundService {
//   static final PusherBackgroundService _instance = PusherBackgroundService._internal();
//   factory PusherBackgroundService() => _instance;
//
//   @pragma('vm:entry-point') // ✅ ADD THIS
//   PusherBackgroundService._internal();
//
//   final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
//   bool _isRunning = false;
//
//   @pragma('vm:entry-point') // ✅ ADD THIS
//   Future<void> initialize() async {
//     if (_isRunning) return;
//
//     final service = FlutterBackgroundService();
//
//     await service.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: _onStart,
//         autoStart: false,
//         isForegroundMode: false, // ✅ FIX: Changed from true to false
//         notificationChannelId: 'doorcab_background',
//         initialNotificationTitle: 'DoorCab Running',
//         initialNotificationContent: 'Tracking your ride',
//         foregroundServiceNotificationId: 888,
//       ),
//       iosConfiguration: IosConfiguration(
//         autoStart: false,
//         onForeground: _onStart,
//         onBackground: _onIosBackground,
//       ),
//     );
//
//     _isRunning = true;
//   }
//
//   @pragma('vm:entry-point') // ✅ ADD THIS
//   static Future<void> _onStart(ServiceInstance service) async {
//     if (service is AndroidServiceInstance) {
//
//       // service.on('setAsForeground').listen((event) {
//         service.setAsForegroundService();
//       // });
//
//         service.setForegroundNotificationInfo(
//           title: "DoorCab Running",
//           content: "Tracking your ride...",
//         );
//
//       service.on('setAsBackground').listen((event) {
//         service.setAsBackgroundService();
//       });
//     }
//
//     service.on('stopService').listen((event) {
//       service.stopSelf();
//     });
//
//     // Start background Pusher
//     final backgroundService = PusherBackgroundService();
//     await backgroundService._startBackgroundPusher(service);
//   }
//
//   @pragma('vm:entry-point') // ✅ ADD THIS
//   static Future<bool> _onIosBackground(ServiceInstance service) async {
//     return true;
//   }
//
//   @pragma('vm:entry-point') // ✅ ADD THIS
//   Future<void> _startBackgroundPusher(ServiceInstance service) async {
//     try {
//       await _pusherManager.initialize();
//
//       // Get stored driver context
//       final prefs = await SharedPreferences.getInstance();
//       final driverId = prefs.getString('driverId');
//       final rideId = prefs.getString('currentRideId');
//
//       if (driverId != null) {
//         await _pusherManager.subscribeOnce(
//           "private-driver-$driverId",
//           events: {
//             "ride-request": (data) => _handleBackgroundEvent('ride-request', data, service),
//           },
//         );
//
//         await _pusherManager.subscribeOnce(
//           "driver-$driverId",
//           events: {
//             "bid-accepted": (data) => _handleBackgroundEvent('bid-accepted', data, service),
//             "bid-rejected": (data) => _handleBackgroundEvent('bid-rejected', data, service),
//             "bid-ignored": (data) => _handleBackgroundEvent('bid-ignored', data, service),
//             "ride-closed": (data) => _handleBackgroundEvent('ride-closed', data, service),
//           },
//         );
//       }
//
//       if (rideId != null) {
//         await _pusherManager.subscribeOnce(
//           "ride-$rideId",
//           events: {
//             "driver-location": (data) => _handleBackgroundEvent('driver-location', data, service),
//             "ride-cancelled": (data) => _handleBackgroundEvent('ride-cancelled', data, service),
//             "new-message": (data) => _handleBackgroundEvent('new-message', data, service),
//           },
//         );
//       }
//
//       // ✅ FIX: REMOVED setAsForegroundService() call
//       // This was causing the crash because we're not in foreground mode
//
//       print('✅ Background Pusher Service Running Successfully');
//
//     } catch (e) {
//       print('❌ Background Pusher Error: $e');
//     }
//   }
//
//   @pragma('vm:entry-point') // ✅ ADD THIS
//   // Remove notification methods since we're not in foreground mode
//   void _handleBackgroundEvent(String eventType, Map<String, dynamic> data, ServiceInstance service) {
//     print('📱 Background Event: $eventType - $data');
//
//     // Store event for when app comes to foreground
//     _storeBackgroundEvent(eventType, data);
//
//     // ❌ REMOVE: Can't show notifications in non-foreground mode
//     // if (service is AndroidServiceInstance) {
//     //   _updateNotificationForEvent(eventType, data, service);
//     // }
//   }
//
//   @pragma('vm:entry-point') // ✅ ADD THIS
//   Future<void> _storeBackgroundEvent(String eventType, Map<String, dynamic> data) async {
//     final prefs = await SharedPreferences.getInstance();
//     final events = prefs.getStringList('backgroundEvents') ?? [];
//     events.add(json.encode({
//       'type': eventType,
//       'data': data,
//       'timestamp': DateTime.now().millisecondsSinceEpoch,
//     }));
//     await prefs.setStringList('backgroundEvents', events);
//   }
//
//   @pragma('vm:entry-point') // ✅ ADD THIS
//   // ✅ UPDATE: Add driver support
//   Future<void> startBackgroundMode(String userId, {String? userType, String? rideId}) async {
//     final prefs = await SharedPreferences.getInstance();
//
//     // Store based on user type
//     if (userType == 'driver') {
//       await prefs.setString('driverId', userId);
//     } else {
//       await prefs.setString('passengerId', userId);
//     }
//
//     if (rideId != null) {
//       await prefs.setString('currentRideId', rideId);
//     }
//
//     final service = FlutterBackgroundService();
//     await service.startService();
//
//     print('🚀 Background Service Started for $userType: $userId');
//   }
//
//
//   @pragma('vm:entry-point') // ✅ ADD THIS
//   Future<void> stopBackgroundMode() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('passengerId');
//     await prefs.remove('driverId');
//     await prefs.remove('currentRideId');
//     await prefs.remove('backgroundEvents');
//
//     final service = FlutterBackgroundService();
//     service.invoke('stopService');
//
//     print('🛑 Background Service Stopped');
//   }
//
//   @pragma('vm:entry-point') // ✅ ADD THIS
//   Future<List<Map<String, dynamic>>> getPendingEvents() async {
//     final prefs = await SharedPreferences.getInstance();
//     final events = prefs.getStringList('backgroundEvents') ?? [];
//     await prefs.remove('backgroundEvents');
//
//     return events.map((e) {
//       try {
//         return json.decode(e) as Map<String, dynamic>;
//       } catch (e) {
//         return {'type': 'error', 'data': {'error': 'Invalid event format'}};
//       }
//     }).toList();
//   }
// }
