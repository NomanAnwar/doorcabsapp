import 'package:geolocator/geolocator.dart';
import 'package:doorcab/feautures/start/views/getting_started_screen.dart';
import 'package:get/get.dart';
import '../../feautures/shared/controllers/base_controller.dart';
import '../../utils/http/http_client.dart';
import '../../feautures/shared/services/storage_service.dart';
import '../models/languagemodel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WelcomeController extends BaseController {
  final languages = <LanguageModel>[].obs;
  final selectedLanguage = Rxn<LanguageModel>();
  final selectedRole = ''.obs;
  final isLoading = false.obs;
  final locationPermissionGranted = false.obs;

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
        print("📍 Detected country: $country");

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
      print("Error loading languages: $e");
      // Don't show error for permission denied - use fallback silently
      if (!e.toString().contains('permission') && !e.toString().contains('denied')) {
        showError('Failed to load languages. Using default settings.');
      }
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
        return _getFallbackCountry();
      }

      // Step 2: Check and request location permissions with proper flow
      LocationPermission permission = await Geolocator.checkPermission();
      print("📍 Initial permission status: $permission");

      if (permission == LocationPermission.denied) {
        print("📍 Requesting location permission...");
        permission = await Geolocator.requestPermission();
        print("📍 Permission after request: $permission");
      }

      if (permission == LocationPermission.deniedForever) {
        print("📍 Location permission permanently denied");
        return _getFallbackCountry();
      }

      if (permission == LocationPermission.denied) {
        print("📍 Location permission denied");
        return _getFallbackCountry();
      }

      // Step 3: Permission granted - get current position
      print("📍 Location permission granted, getting position...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      );

      print("📍 GPS Coordinates: ${position.latitude}, ${position.longitude}");

      // Step 4: Reverse geocoding to get country IN ENGLISH
      final country = await _getCountryFromCoordinates(
          position.latitude,
          position.longitude
      );

      locationPermissionGranted.value = true;
      return country;

    } catch (e) {
      print("❌ Error getting country from GPS: $e");
      return _getFallbackCountry();
    }
  }

  String _getFallbackCountry() {
    // Fallback: Try device locale as last resort
    final locale = Get.deviceLocale;
    if (locale != null && locale.countryCode != null) {
      print("📍 Using device locale fallback: ${locale.countryCode}");
      return _simplifiedCountryFallback(locale.countryCode!);
    }

    print("📍 Using ultimate fallback: Pakistan");
    return 'Pakistan';
  }

  String _simplifiedCountryFallback(String countryCode) {
    // Simple mapping for common cases only - IN ENGLISH
    final commonCountries = {
      'US': 'United States',
      'PK': 'Pakistan',
      'IN': 'India',
      'GB': 'United Kingdom',
      'CA': 'Canada',
      'AU': 'Australia',
      'DE': 'Germany',
      'FR': 'France',
      'IT': 'Italy',
      'ES': 'Spain',
      'BR': 'Brazil',
      'CN': 'China',
      'JP': 'Japan',
      'KR': 'South Korea',
      'MX': 'Mexico',
      'RU': 'Russia',
    };

    return commonCountries[countryCode] ?? 'United States';
  }

  Future<String> _getCountryFromCoordinates(double lat, double lng) async {
    try {
      // Using OpenStreetMap Nominatim API with English language parameter
      final url = "https://nominatim.openstreetmap.org/reverse"
          "?format=json"
          "&lat=$lat"
          "&lon=$lng"
          "&zoom=3" // Country level
          "&addressdetails=1"
          "&accept-language=en"; // ✅ FORCE ENGLISH LANGUAGE

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'DoorCab-App', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];

        if (address != null) {
          // Get country name in English from reverse geocoding
          final country = address['country']?.toString() ?? 'Unknown';

          print("🗺️ Reverse geocoding result: $country");

          // ✅ Additional safety check - if still not in English, use fallback
          if (_containsNonEnglishCharacters(country)) {
            print("⚠️ Country name contains non-English characters, using fallback");
            return _getCountryFromCoordinatesFallback(lat, lng);
          }

          return country;
        }
      }

      throw Exception('Failed to get country from coordinates');

    } catch (e) {
      print("❌ Reverse geocoding error: $e");
      return _getCountryFromCoordinatesFallback(lat, lng);
    }
  }

  // ✅ Alternative method using a different geocoding service as fallback
  Future<String> _getCountryFromCoordinatesFallback(double lat, double lng) async {
    try {
      // Using Google Geocoding API (requires API key) or another service
      // For now, let's use a simple country code to name mapping based on coordinates
      return _getCountryFromCoordinatesManual(lat, lng);
    } catch (e) {
      print("❌ Fallback geocoding error: $e");
      return _getFallbackCountry();
    }
  }

  // ✅ Manual country detection based on coordinates (basic approach)
  String _getCountryFromCoordinatesManual(double lat, double lng) {
    // Simple coordinate-based country detection for major countries
    // Pakistan coordinates range
    if (lat >= 23.5 && lat <= 37.0 && lng >= 60.0 && lng <= 77.0) {
      return 'Pakistan';
    }
    // India coordinates range
    else if (lat >= 6.0 && lat <= 35.0 && lng >= 68.0 && lng <= 97.0) {
      return 'India';
    }
    // USA coordinates range
    else if (lat >= 24.0 && lat <= 49.0 && lng >= -125.0 && lng <= -67.0) {
      return 'United States';
    }
    // UK coordinates range
    else if (lat >= 49.0 && lat <= 60.0 && lng >= -8.0 && lng <= 2.0) {
      return 'United Kingdom';
    }
    // Add more countries as needed...

    return 'United States'; // Default fallback
  }

  // ✅ Check if string contains non-English characters
  bool _containsNonEnglishCharacters(String text) {
    final englishRegex = RegExp(r'^[a-zA-Z\s\-,.]+$');
    return !englishRegex.hasMatch(text);
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

  // Optional: Method to manually trigger permission request
  Future<void> requestLocationPermissionManually() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      print("📍 Manual permission request result: $permission");

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Reload languages with GPS data
        await _loadLanguages();
      }
    } catch (e) {
      print("❌ Manual permission request error: $e");
    }
  }
}