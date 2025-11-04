// Extend the existing PusherBackgroundService for driver-specific needs
import 'package:doorcab/feautures/shared/services/pusher_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverBackgroundService {
  static Future<void> startDriverBackgroundMode(String driverId, {String? rideId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driverId', driverId);
    if (rideId != null) {
      await prefs.setString('currentRideId', rideId);
    }

    // Start the generic background service
    await PusherBackgroundService().startBackgroundMode(driverId, rideId: rideId);

    print("🚗 Driver background mode started");
  }

  static Future<void> stopDriverBackgroundMode() async {
    await PusherBackgroundService().stopBackgroundMode();
    print("🚗 Driver background mode stopped");
  }
}