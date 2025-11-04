import 'package:doorcab/feautures/start/views/getting_started_screen.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../feautures/shared/controllers/base_controller.dart';
import '../../utils/http/http_client.dart';
import '../../feautures/shared/services/storage_service.dart';
import '../models/languagemodel.dart';

class WelcomeController extends BaseController {
  final languages = <LanguageModel>[].obs;
  final selectedLanguage = Rxn<LanguageModel>();
  final selectedRole = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    isLoading.value = true;

    try {
      await executeWithRetry(() async {
        // Get user country from GPS location
        final String country = await _getUserCountryFromGPS();
        print("📍 Detected country from GPS: $country");

        // Construct URL with country parameter
        final String url = "site/get-languages/$country";
        final response = await FHttpHelper.get(url);
        print("Languages API Response: ${response.toString()}");

        if (response["success"] == true && response["supported_languages"] != null) {
          languages.value = (response["supported_languages"] as List)
              .map((e) => LanguageModel.fromJson(e))
              .toList();

          if (languages.isNotEmpty) {
            selectedLanguage.value = languages.first;
          }
        }
      });
    } catch (e) {
      print("❌ Error loading languages: $e");
      showError('Failed to load languages. Please check your location permissions.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> _getUserCountryFromGPS() async {
    try {
      // Step 1: Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("📍 Location services disabled");
        throw Exception('Location services are disabled');
      }

      // Step 2: Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print("📍 Initial permission status: $permission");

      if (permission == LocationPermission.denied) {
        print("📍 Requesting location permission...");
        permission = await Geolocator.requestPermission();
        print("📍 Permission after request: $permission");
      }

      if (permission == LocationPermission.deniedForever) {
        print("📍 Location permission permanently denied");
        throw Exception('Location permission permanently denied');
      }

      if (permission == LocationPermission.denied) {
        print("📍 Location permission denied");
        throw Exception('Location permission denied');
      }

      // Step 3: Get current position
      print("📍 Location permission granted, getting position...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      );

      print("📍 GPS Coordinates: ${position.latitude}, ${position.longitude}");

      // Step 4: Reverse geocoding to get country
      final country = await _getCountryFromCoordinates(
          position.latitude,
          position.longitude
      );

      return country;

    } catch (e) {
      print("❌ Error getting country from GPS: $e");
      // No fallback to locale - use Pakistan directly
      print("📍 Using default country: Pakistan");
      return 'Pakistan';
    }
  }

  Future<String> _getCountryFromCoordinates(double lat, double lng) async {
    try {
      // Using OpenStreetMap Nominatim API for reverse geocoding
      final url = "https://nominatim.openstreetmap.org/reverse"
          "?format=json"
          "&lat=$lat"
          "&lon=$lng"
          "&zoom=3" // Country level
          "&addressdetails=1"
          "&accept-language=en"; // Force English response

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'DoorCab-App', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];

        if (address != null && address['country'] != null) {
          final country = address['country'].toString();
          print("🗺️ Reverse geocoding result: $country");
          return country;
        } else {
          throw Exception('No country found in geocoding response');
        }
      } else {
        throw Exception('Geocoding API failed with status: ${response.statusCode}');
      }

    } catch (e) {
      print("❌ Reverse geocoding error: $e");
      throw e; // Re-throw to be handled by caller
    }
  }

  void selectLanguage(LanguageModel lang) {
    selectedLanguage.value = lang;
  }

  void selectRole(String role) {
    selectedRole.value = role;
  }

  void saveAndContinue() {
    if (selectedLanguage.value != null && selectedRole.isNotEmpty) {
      StorageService.saveLanguage(selectedLanguage.value!.language);
      StorageService.saveRole(selectedRole.value);
      Get.to(() => const GettingStartedScreen());
    } else {
      showError('Please select both language and role');
    }
  }

  // Optional: Method to retry location detection
  Future<void> retryLocationDetection() async {
    await _loadLanguages();
  }
}