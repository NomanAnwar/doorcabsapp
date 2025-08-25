import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  static Future<Position?> currentPosition() async {
    if (!await ensurePermission()) return null;
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  static Future<bool> isLocationEnabled() => Geolocator.isLocationServiceEnabled();
}
