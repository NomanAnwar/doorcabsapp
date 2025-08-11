import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pusher_beams/pusher_beams.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
    _initPusherBeams();
  }

  /// Initialize Firebase Messaging for Push Notifications
  Future<void> _initFirebaseMessaging() async {
    // Ask for notification permission
    NotificationSettings settings =
    await FirebaseMessaging.instance.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("✅ Push notification permission granted");

      // Get FCM Token
      String? token = await FirebaseMessaging.instance.getToken();
      debugPrint("📲 FCM Token: $token");

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("📩 Foreground message received: ${message.data}");
        _showNotificationDialog(message);
      });

      // When the app is opened via notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("📬 App opened via notification: ${message.data}");
      });
    } else {
      debugPrint("❌ Push notification permission denied");
    }
  }

  /// Initialize Pusher Beams
  Future<void> _initPusherBeams() async {
    await Permission.notification.request();

    try {
      await PusherBeams.instance.start("1aeaf0d9-e6ba-4132-bee8-b152fe62ad54"); // replace with your ID
      await PusherBeams.instance.addDeviceInterest("passenger");
      debugPrint("✅ Pusher Beams initialized");
    } catch (e) {
      debugPrint("❌ Pusher Beams initialization failed: $e");
    }
  }

  /// Simple notification dialog for testing
  void _showNotificationDialog(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message.notification?.title ?? "Notification"),
        content: Text(message.notification?.body ?? "No body"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          "Home Screen — Notifications & Pusher Active",
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
