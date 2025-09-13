import 'dart:convert';

import 'package:pusher_beams/pusher_beams.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PusherBeamsService {
  static final PusherBeamsService _instance = PusherBeamsService._internal();
  factory PusherBeamsService() => _instance;
  PusherBeamsService._internal();

  final String instanceId = '1aeaf0d9-e6ba-4132-bee8-b152fe62ad54';
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize both Pusher Beams and Firebase Messaging
  Future<void> initialize() async {
    try {
      // Initialize Pusher Beams
      await PusherBeams.instance.start(instanceId);
      print('✅ Pusher Beams initialized successfully');

      // Initialize Firebase Messaging
      await _setupFirebaseMessaging();
      print('✅ Firebase Messaging initialized');

      // Register device interests
      await registerDevice();

    } catch (e) {
      print('❌ Error initializing: $e');
    }
  }

  /// Setup Firebase Messaging with notification handlers
  Future<void> _setupFirebaseMessaging() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('Notification permission: ${settings.authorizationStatus}');

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup message handlers
      _setupMessageHandlers();

    } catch (e) {
      print('❌ Error setting up Firebase Messaging: $e');
    }
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(initializationSettings);
  }

  /// Setup Firebase message handlers
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message: ${message.data}');
      _showLocalNotification(message);
      _handleIncomingNotification(message.data);
    });

    // Handle when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 App opened from notification: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // Handle initial message when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📱 Initial message: ${message.data}');
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ride_channel',
      'Ride Notifications',
      channelDescription: 'Notifications for ride requests and updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new notification',
      notificationDetails,
      payload: json.encode(message.data),
    );
  }

  /// Register device for push notifications
  Future<void> registerDevice() async {
    try {
      final interests = await getCurrentInterests();
      print('📱 Device registered with interests: $interests');

      // Subscribe to relevant interests
      await subscribeToInterest('ride_requests');
      await subscribeToInterest('driver_updates');

    } catch (e) {
      print('❌ Error registering device: $e');
    }
  }

  /// Subscribe to interest
  Future<void> subscribeToInterest(String interest) async {
    try {
      await PusherBeams.instance.addDeviceInterest(interest);
      print('✅ Subscribed to interest: $interest');
    } catch (e) {
      print('❌ Error subscribing to interest $interest: $e');
    }
  }

  /// Handle incoming notification data
  void _handleIncomingNotification(Map<String, dynamic> data) {
    final String? type = data['type'];

    switch (type) {
      case 'ride_request':
        _handleRideRequestNotification(data);
        break;
      case 'driver_assigned':
        _handleDriverAssignedNotification(data);
        break;
      case 'ride_status':
        _handleRideStatusNotification(data);
        break;
      case 'driver_nearby':
        _handleDriverNearbyNotification(data);
        break;
      default:
        print('Received unknown notification type: $type');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final String? rideId = data['ride_id'];
    final String? type = data['type'];

    if (rideId != null) {
      print('Navigating to ride details: $rideId');
      // Navigate to appropriate screen based on notification type
      _navigateBasedOnNotification(type, rideId, data);
    }
  }

  void _navigateBasedOnNotification(String? type, String rideId, Map<String, dynamic> data) {
    switch (type) {
      case 'ride_request':
      // Get.toNamed('/ride-request/$rideId');
        break;
      case 'driver_assigned':
      // Get.toNamed('/driver-tracking/$rideId');
        break;
      case 'ride_status':
      // Get.toNamed('/ride-status/$rideId');
        break;
      default:
      // Get.toNamed('/notifications');
        break;
    }
  }

  void _handleRideRequestNotification(Map<String, dynamic> payload) {
    final String rideId = payload['ride_id'] ?? '';
    final String pickup = payload['pickup'] ?? '';
    final String fare = payload['fare'] ?? '';

    print('🚗 New ride request: $rideId from $pickup for $fare');

    // Show alert to user
    // Get.snackbar('New Ride Request', 'Pickup: $pickup | Fare: $fare');
  }

  void _handleDriverAssignedNotification(Map<String, dynamic> payload) {
    final String rideId = payload['ride_id'] ?? '';
    final String driverName = payload['driver_name'] ?? '';
    final String eta = payload['eta'] ?? '';

    print('👤 Driver assigned: $driverName for ride $rideId, ETA: $eta');

    // Get.snackbar('Driver Assigned', '$driverName will arrive in $eta');
  }

  void _handleRideStatusNotification(Map<String, dynamic> payload) {
    final String rideId = payload['ride_id'] ?? '';
    final String status = payload['status'] ?? '';

    print('🔄 Ride status update: $rideId is now $status');

    // Get.snackbar('Ride Update', 'Status: ${status.toUpperCase()}');
  }

  void _handleDriverNearbyNotification(Map<String, dynamic> payload) {
    final String rideId = payload['ride_id'] ?? '';
    final String driverName = payload['driver_name'] ?? '';
    final String distance = payload['distance'] ?? '';

    print('📍 Driver nearby: $driverName is $distance away for ride $rideId');
  }

  /// Get current interests
  Future<List<String>> getCurrentInterests() async {
    try {
      final interests = await PusherBeams.instance.getDeviceInterests();
      return interests.whereType<String>().toList();
    } catch (e) {
      print('❌ Error getting interests: $e');
      return [];
    }
  }

  /// Clear all interests
  Future<void> clearAllInterests() async {
    try {
      await PusherBeams.instance.clearDeviceInterests();
      print('✅ Cleared all interests');
    } catch (e) {
      print('❌ Error clearing interests: $e');
    }
  }
}