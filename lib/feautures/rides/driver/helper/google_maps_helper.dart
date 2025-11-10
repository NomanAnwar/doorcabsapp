// google_maps_helper.dart
import 'package:url_launcher/url_launcher.dart';

class GoogleMapsHelper {

  // Open Google Maps with navigation to a specific point
  static Future<void> openGoogleMapsWithNavigation({
    required double destinationLat,
    required double destinationLng,
    String destinationName = "Destination",
  }) async {
    try {
      // Try to open in Google Maps app first
      final Uri uri = Uri.parse(
          "google.navigation:q=$destinationLat,$destinationLng&mode=d"
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: Open in browser
        await openGoogleMapsInBrowser(
          destinationLat: destinationLat,
          destinationLng: destinationLng,
          destinationName: destinationName,
        );
      }
    } catch (e) {
      print('Error opening Google Maps: $e');
      // Fallback to browser
      await openGoogleMapsInBrowser(
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        destinationName: destinationName,
      );
    }
  }

  // Fallback method to open in browser
  static Future<void> openGoogleMapsInBrowser({
    required double destinationLat,
    required double destinationLng,
    String destinationName = "Destination",
  }) async {
    final Uri uri = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=driving"
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  // Open Google Maps with both origin and destination
  static Future<void> openGoogleMapsWithRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String originName = "My Location",
    String destName = "Destination",
  }) async {
    try {
      final Uri uri = Uri.parse(
          "https://www.google.com/maps/dir/?api=1"
              "&origin=$originLat,$originLng"
              "&destination=$destLat,$destLng"
              "&travelmode=driving"
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await openGoogleMapsInBrowser(
          destinationLat: destLat,
          destinationLng: destLng,
          destinationName: destName,
        );
      }
    } catch (e) {
      print('Error opening Google Maps with route: $e');
      await openGoogleMapsInBrowser(
        destinationLat: destLat,
        destinationLng: destLng,
        destinationName: destName,
      );
    }
  }
}