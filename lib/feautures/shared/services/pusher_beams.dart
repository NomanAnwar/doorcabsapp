import 'dart:convert';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:pusher_beams/pusher_beams.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import '../../../utils/http/http_client.dart';

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

      // await clearAllInterests();

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

      // CRITICAL FIX: Send FCM token to backend server
      if (token != null) {
        await _sendFcmTokenToServer(token);
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup message handlers
      _setupMessageHandlers();

    } catch (e) {
      print('❌ Error setting up Firebase Messaging: $e');
    }
  }

  /// CRITICAL FIX: Send FCM token to backend server
  Future<void> _sendFcmTokenToServer(String token) async {
    try {
      final driverId = StorageService.getSignUpResponse()?.userId;
      if (driverId == null) {
        print('❌ No driver ID found');
        return;
      }

      final storetoken = StorageService.getAuthToken();

      if (storetoken == null) {
        print("Error" + "User token not found. Please login again.");
        return;
      }

      FHttpHelper.setAuthToken(storetoken, useBearer: true);

      final fcmres = await FHttpHelper.post('token/register-fcm', {
        'fcm_token': token,
        'device_type': 'android',
      });

      print("FCM Res : "+fcmres.toString());


      print('✅ FCM token sent to server successfully');
    } catch (e) {
      print('❌ Failed to send FCM token to server: $e');
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
      // Get driver ID for driver-specific interest
      final userId = StorageService.getSignUpResponse()?.userId;
      final role = StorageService.getRole();
      print("User Role in the beam : "+role.toString());
      if (userId != null) {

        if(role == "Driver" || role == "driver") {
          final driverInterest = 'driver-$userId';
          await PusherBeams.instance.addDeviceInterest(driverInterest);
          print('✅ Subscribed to driver-specific interest: $driverInterest');
        } else if (role == "Passenger" || role == "passenger"){
          final driverInterest = 'passenger-$userId';
          await PusherBeams.instance.addDeviceInterest(driverInterest);
          print('✅ Subscribed to passenger-specific interest: $driverInterest');
        }
      }

      final interests = await getCurrentInterests();
      print('📱 Device registered with interests: $interests');

      // Subscribe to relevant interests
      // await subscribeToInterest('debug-ride_requests');
      // await subscribeToInterest('ride_requests');
      // await subscribeToInterest('driver_updates');

      // Send interests to backend for tracking
      if (userId != null) {
        await _sendInterestsToServer(userId, interests);
      }

    } catch (e) {
      print('❌ Error registering device: $e');
    }
  }

  /// Send current interests to backend
  Future<void> _sendInterestsToServer(String driverId, List<String> interests) async {
    try {

      final token = StorageService.getAuthToken();

      if (token == null) {
        print("Error" + "User token not found. Please login again.");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      await FHttpHelper.post('token/update-interests', {
        'interests': interests,
      });
      print('✅ Interests sent to server: $interests');
    } catch (e) {
      print('❌ Failed to send interests to server: $e');
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

  /// Test method to verify push notifications are working
  Future<void> testNotification() async {
    try {
      // Get driver ID for testing
      final driverId = StorageService.getSignUpResponse()?.userId;
      if (driverId == null) {
        print('❌ No driver ID found for test notification');
        return;
      }

      // Call your backend API to send a test notification
      // Your backend should use the server-side Pusher Beams SDK
      await FHttpHelper.post('driver/test-notification', {
        'driver_id': driverId,
        'message': 'Test notification from your app'
      });

      print('✅ Test notification request sent to backend');

    } catch (e) {
      print('❌ Test notification failed: $e');
    }
  }
}