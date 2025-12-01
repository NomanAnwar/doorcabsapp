import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

      const initSettings = InitializationSettings(
        android: androidInit,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (resp) {
          // Handle notification tap
          print("🔔 Notification clicked: ${resp.payload}");
        },
      );

      await _createChannel();

      print("✅ Notification Helper Ready");
    } catch (e) {
      print("❌ Notification Setup Failed: $e");
    }
  }

  static Future<void> _createChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'doorcab_background',
      'DoorCab Background Service',
      description: 'Used for location tracking & ride updates',
      importance: Importance.low,
      showBadge: false,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
  }

  static Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'doorcab_background',
      'DoorCab Background Service',
      channelDescription: 'Used for location tracking & ride updates',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, details, payload: payload);
  }
}
