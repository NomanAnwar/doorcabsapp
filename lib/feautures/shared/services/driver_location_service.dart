import 'dart:async';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:workmanager/workmanager.dart';
import '../../../utils/http/http_client.dart';

class DriverLocationService {
  static final DriverLocationService _instance = DriverLocationService._internal();
  factory DriverLocationService() => _instance;
  DriverLocationService._internal();

  bool _isOnline = false;
  Timer? _foregroundTimer;

  /// Called once at app startup
  Future<void> configure() async {
    // Request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("⚠️ Location permissions are permanently denied");
    }

    // Init background worker
    await Workmanager().initialize(
      _callbackDispatcher,
      isInDebugMode: true,
    );
  }

  /// Foreground + Background start
  Future<void> start() async {
    if (_isOnline) return;
    _isOnline = true;

    // Foreground real-time updates (every 5s)
    _foregroundTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _sendCurrentLocation();
    });

    // Background updates (15 minutes min interval)
    await Workmanager().registerPeriodicTask(
      "driverLocationTask",
      "sendDriverLocation",
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace, // <-- FIXED
    );

    print("▶️ DriverLocationService started (5s foreground, 15m background)");
  }

  /// Stop both foreground + background tracking
  Future<void> stop() async {
    _isOnline = false;
    _foregroundTimer?.cancel();
    _foregroundTimer = null;

    await Workmanager().cancelByUniqueName("driverLocationTask");
    print("🛑 DriverLocationService stopped");
  }

  bool get isRunning => _isOnline;

  /// Internal — send current position to server
  Future<void> _sendCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final body = {
        "lat": position.latitude,
        "lng": position.longitude,
      };

      final token = StorageService.getAuthToken();
      if (token == null) {
        Get.snackbar("Error", "User token not found. Please login again.");
      }

      FHttpHelper.setAuthToken(token!, useBearer: true);


      await FHttpHelper.post("driver/redis-drivers", body);
      print("📍 Location sent: $body");
    } catch (e) {
      print("❌ Failed to send location: $e");
    }
  }
}

/// Background task dispatcher (runs outside app lifecycle)
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "sendDriverLocation") {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );

        final body = {
          "lat": position.latitude,
          "lng": position.longitude,
        };

        await FHttpHelper.post("driver/redis-drivers", body);
        print("📍 [Background] Location sent: $body");
      } catch (e) {
        print("❌ [Background] Failed to send location: $e");
      }
    }
    return Future.value(true);
  });
}
