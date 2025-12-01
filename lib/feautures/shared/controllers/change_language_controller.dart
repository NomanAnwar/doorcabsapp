import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../../../utils/http/http_client.dart';
import '../services/storage_service.dart';

class ChangeLanguageController extends GetxController {
  var currentLanguage = "English".obs;
  var selectedLanguage = "".obs;
  var availableLanguages = <String>[].obs;
  var isLoading = false.obs;
  var isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentLanguage();
    fetchLanguages();
  }

  /// Load current language from storage safely
  void _loadCurrentLanguage() {
    try {
      final data = StorageService.getProfile();

      if (data != null && data.isNotEmpty) {
        final language = data['preferred_language']?.toString();
        if (language != null && language.isNotEmpty) {
          print("the language : " + language);
          currentLanguage.value = language;
        } else {
          currentLanguage.value = "English"; // Default if empty
        }
      } else {
        currentLanguage.value = "English"; // Default if no profile
      }
    } catch (e) {
      print("Error loading language from storage: $e");
      currentLanguage.value = "English"; // Default on error
    }
  }

  Future<void> fetchLanguages() async {
    try {
      isLoading.value = true;

      String country = "Unknown";

      // Try to get location with retry logic
      try {
        Position position = await _getCurrentLocationWithRetry();
        country = await _getCountryFromLocation(position);
      } catch (e) {
        print("Failed to get location: $e");
        country = "Unknown"; // Default if location fails
      }

      // Fetch languages from API
      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response = await FHttpHelper.get('site/get-languages/$country');

      if (response['success'] == true) {
        final languages = List<String>.from(
            response['supported_languages'].map((lang) =>
                _capitalize(lang['language']?.toString() ?? 'English')
            )
        );
        availableLanguages.value = languages.isNotEmpty ? languages : ["English"];
      } else {
        // Fallback to default languages if API fails
        availableLanguages.value = ["English", "Urdu", "Arabic"];
      }
    } catch (e) {
      print("Error fetching languages: $e");
      // Fallback to default languages on error
      availableLanguages.value = ["English", "Urdu", "Arabic"];
      FSnackbar.show(
          title: "Info",
          message: "Using default languages",
          isError: false
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get current location with retry logic
  Future<Position> _getCurrentLocationWithRetry({int maxRetries = 2}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (attempt == maxRetries) {
            throw Exception('Location services are disabled.');
          }
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (attempt == maxRetries) {
              throw Exception('Location permissions are denied');
            }
            await Future.delayed(Duration(seconds: attempt));
            continue;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are permanently denied');
        }

        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        );
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw Exception('Failed to get location after $maxRetries attempts');
  }

  Future<String> _getCountryFromLocation(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first.country ?? "Unknown";
      } else {
        return "Unknown";
      }
    } catch (e) {
      print("Error getting country from location: $e");
      return "Unknown";
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return "English"; // Default if empty
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Future<void> saveLanguage() async {
    final newLang = selectedLanguage.value;

    if (newLang.isEmpty) {
      FSnackbar.show(title: "Error", message: "Please select a language.", isError: true);
      return;
    }

    try {
      isSaving.value = true;

      // Call update profile API
      final response = await FHttpHelper.post(
          'service/update-language',
          {"language": newLang}
      );

      if (response['message'] == "Language updated successfully.") {
        currentLanguage.value = newLang;
        FSnackbar.show(title: "Success", message: "Language changed to $newLang.");
        await _saveProfile();
        Get.back();
      } else {
        FSnackbar.show(title: "Error",message:  "Failed to update language.", isError: true);
      }
    } catch (e) {
      FSnackbar.show(title: "Error", message: "Failed to update language: ${e.toString()}", isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _saveProfile() async {
    try {
      final role = StorageService.getRole();

      if(role == "Driver" || role == "driver") {
        final token = StorageService.getAuthToken();
        if (token == null) {
          print("❌ User token not found for active rides API");
          return;
        }

        FHttpHelper.setAuthToken(token, useBearer: true);
        final profileResponse = await FHttpHelper.get(
          "driver/${StorageService
              .getSignUpResponse()
              ?.userId
              .toString()}",
        );

        final driverProfile = profileResponse["driver"];
        StorageService.saveProfile(driverProfile);

        print("After language change profile saved.");
      }

      if(role == "Passenger" || role == "passenger") {
        final token = StorageService.getAuthToken();
        if (token == null) {
          print("❌ User token not found for active rides API");
          return;
        }

        FHttpHelper.setAuthToken(token, useBearer: true);
        final response1 = await FHttpHelper.get("passenger/get-profile-info");
        StorageService.saveProfile(response1["passenger"]);
        print("After language change profile saved.");
      }
    } catch (e) {
      print("Error saving profile after language change: $e");
      // Continue even if profile save fails
    }
  }
}