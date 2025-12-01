import 'dart:async';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import '../../../common/widgets/snakbar/snackbar.dart';
import '../../../utils/http/http_client.dart';

class DriverLocationService {
  static final DriverLocationService _instance = DriverLocationService._internal();
  factory DriverLocationService() => _instance;
  DriverLocationService._internal();

  bool _isOnline = false;
  Timer? _foregroundTimer;

  // 🔄 Optional pause flag (to stop sending when offline but keep service alive)
  bool _isPaused = false;

  /// Called once at app startup (main.dart)
  Future<void> configure() async {
    // Request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("⚠️ Location permissions are permanently denied");
    }

    // ✅ Init background worker
    await Workmanager().initialize(
      _callbackDispatcher,
      isInDebugMode: true,
    );
  }

  /// Start foreground + background tracking
  Future<void> start() async {
    if (_isOnline) return; // already running
    _isOnline = true;
    int i = 0;
    // Foreground real-time updates (every 5s)
    _foregroundTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _sendCurrentLocation(i);
      i++;
    });

    // Background updates (every 15 minutes)
    await Workmanager().registerPeriodicTask(
      "driverLocationTask",
      "sendDriverLocation",
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    print("▶️ DriverLocationService started (5s foreground, 15m background)");
    // FSnackbar.show(title: 'Location service', message: 'DriverLocationService started');
  }

  /// Stop both foreground + background tracking
  /// ❌ You commented this out in toggleOnline — so service runs until app exit
  Future<void> stop() async {
    _isOnline = false;
    _foregroundTimer?.cancel();
    _foregroundTimer = null;

    await Workmanager().cancelByUniqueName("driverLocationTask");
    print("🛑 DriverLocationService stopped");
    // FSnackbar.show(title: 'Location service', message: 'DriverLocationService stop');
  }

  // 🔄 Optional pause/resume control (if you want to stop sending while offline)

  void pause() {
    _isPaused = true;
    print("⏸️ DriverLocationService paused (no location sent, still running)");
    // FSnackbar.show(title: 'Location service', message: 'DriverLocationService pause');
  }

  void resume() {
    _isPaused = false;
    print("▶️ DriverLocationService resumed");
    // FSnackbar.show(title: 'Location service', message: 'DriverLocationService resume');
  }

  bool get isRunning => _isOnline;

  /// Internal — send current position to server
  Future<void> _sendCurrentLocation(int i) async {
    try {
      // 🔄 Skip if paused
      // if (_isPaused) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final body = {
        "lat": position.latitude,
        "lng": position.longitude,
      };

      final token = StorageService.getAuthToken();
      if (token == null) {
        print("Error" + "User token not found. Please login again.");
        return; // ✅ prevent crash
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      await FHttpHelper.post("driver/redis-drivers", body);
      print("📍 Location sent $i: $body");
      // if(i == 0) {
      //   FSnackbar.show(title: "Location", message: "Driver Location sent $body");
      // }
    } catch (e) {
      print("❌ Failed to send location: $e");
      // if(i== 0){
      // FSnackbar.show(title: 'Location service', message: 'Driver Location not sent');
      // }
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
