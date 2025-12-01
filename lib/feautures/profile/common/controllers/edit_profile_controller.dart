import 'dart:convert';
import 'dart:io';
import 'package:doorcab/feautures/profile/common/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/storage_service.dart';
import '../../../../utils/http/api_retry_helper.dart';

class EditProfileController extends GetxController {
  final formKey = GlobalKey<FormState>();

  /// Text Controllers
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final emergencyCtrl = TextEditingController();
  final countryCtrl = TextEditingController(text: "Pakistan");
  final cityCtrl = TextEditingController();

  final isLoading = false.obs;
  final isLoadingData = true.obs; // New loading state for data fetching
  final isEditingMode = false.obs;
  final profileImageUrl = ''.obs;

  /// Focus Nodes for keyboard navigation
  final firstNameFocus = FocusNode();
  final lastNameFocus = FocusNode();
  final emailFocus = FocusNode();
  final contactFocus = FocusNode();
  final emergencyFocus = FocusNode();
  final countryFocus = FocusNode();
  final cityFocus = FocusNode();


  /// Image handling
  final profileImage = Rx<File?>(null);
  final base64Image = ''.obs;
  final _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _loadProfileData();
  }

  /// Method to move to next field
  void moveToNextField(FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(Get.context!).requestFocus(nextFocus);
  }

  /// Method to handle form submission when last field is done
  void onLastFieldSubmit() {
    cityFocus.unfocus();
    saveAndContinue();
  }

  /// Load profile data from storage
  Future<void> _loadProfileData() async {
    try {
      isLoadingData.value = true;

      final profileData = StorageService.getProfile();
      if (profileData != null) {
        _populateFieldsFromStorage(profileData);
      }

      // Get location after loading profile data
      await _getCurrentLocationForEmptyFields();

    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      isLoadingData.value = false;
    }
  }

  /// Populate fields from StorageService.getProfile()
  void _populateFieldsFromStorage(Map<String, dynamic> profileData) {
    try {
      print("noman shah : "+ profileData.toString());
      if (profileData.containsKey('name')) {
        print("noman shah : "+ profileData.toString());
        firstNameCtrl.text = profileData['name']['firstName']?.toString() ?? '';
        lastNameCtrl.text = profileData['name']['lastName']?.toString() ?? '';
        emailCtrl.text = profileData['email']?.toString() ?? '';
        emergencyCtrl.text = profileData['emergency_no']?.toString() ?? '';
        countryCtrl.text = profileData['address']['country']?.toString() ?? '';
        cityCtrl.text = profileData['address']['city']?.toString() ?? '';
        profileImageUrl.value = profileData['Profile_Image']?.toString() ?? '';
      }
    } catch (e) {
      print('Error populating from storage: $e');
    }
  }

  /// Get current location for empty city and country fields
  Future<void> _getCurrentLocationForEmptyFields() async {
    try {
      // Only get location if city or country is empty
      if (cityCtrl.text.isNotEmpty && countryCtrl.text.isNotEmpty) {
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;

        // Update only empty fields
        if (cityCtrl.text.isEmpty) {
          cityCtrl.text = placemark.locality ?? placemark.subAdministrativeArea ?? '';
        }
        if (countryCtrl.text.isEmpty) {
          countryCtrl.text = placemark.country ?? 'Pakistan';
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      // Set default values if location fails
      if (cityCtrl.text.isEmpty) {
        cityCtrl.text = '';
      }
      if (countryCtrl.text.isEmpty) {
        countryCtrl.text = 'Pakistan';
      }
    }
  }

  /// Enable editing mode
  void enableEditing() {
    isEditingMode.value = true;
  }

  /// Pick image with retry for file operations
  Future<void> pickImage(ImageSource source) async {
    if (!isEditingMode.value) return;

    try {
      await ApiRetryHelper.executeWithRetry(
            () async {
          final pickedFile =
          await _picker.pickImage(source: source, imageQuality: 80);
          if (pickedFile == null) return;

          final file = File(pickedFile.path);
          profileImage.value = file;

          final bytes = await file.readAsBytes();
          final encoded = base64Encode(bytes);

          // detect mime type from extension
          final mime = _mimeFromPath(pickedFile.path);

          base64Image.value = 'data:image/$mime;base64,$encoded';
          profileImageUrl.value = ''; // Clear stored URL when new image is selected
        },
        maxRetries: 2,
      );
    } catch (e) {
      Get.snackbar("Image Error", "Failed to pick image: ${e.toString()}");
    }
  }

  String _mimeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'png') return 'png';
    if (ext == 'jpg' || ext == 'jpeg') return 'jpeg';
    if (ext == 'webp') return 'webp';
    return 'jpeg';
  }

  void clearImage() {
    profileImage.value = null;
    base64Image.value = '';
  }

  /// --- VALIDATORS ---
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return "Enter a valid email address";
    }
    return null;
  }

  /// Save profile API with retry mechanism
  Future<void> saveAndContinue() async {
    if (!formKey.currentState!.validate()) return;

    final token = StorageService.getAuthToken();
    if (token == null) {
      Get.snackbar("Error", "User token not found. Please login again.");
      return;
    }

    FHttpHelper.setAuthToken(token, useBearer: true);

    final body = {
      "firstName": firstNameCtrl.text.trim(),
      "lastName": lastNameCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "emergency_no": emergencyCtrl.text.trim(),
      "country": countryCtrl.text.trim(),
      "city": cityCtrl.text.trim(),
      "language": StorageService.getLanguage() ?? "en",
      "profileImage": base64Image.value,
    };

    try {
      isLoading.value = true;

      await ApiRetryHelper.executeWithRetry(
            () async {
          final response = await FHttpHelper.post("service/update-profile", body);

          print("Update Profile API Response: $response");

          if (response["message"] == "Profile updated successfully." ) {
            StorageService.saveProfile(body);

            print("Update Profile API Response: ");

            final role = StorageService.getRole();

            if(role == "driver" || role == "Driver") {

              final profileResponse = await FHttpHelper.get(
                "driver/${StorageService
                    .getSignUpResponse()
                    ?.userId
                    .toString()}",
              );
              print("Get Profile Api Response : " +
                  profileResponse.toString());

              final driverProfile = profileResponse["driver"];
              StorageService.saveProfile(driverProfile);

              FSnackbar.show(
                title: "Success",
                message: "Profile updated successfully.",
              );


            } else if(role == "passenger" || role == "Passenger"){

              final response1 = await FHttpHelper.get(
                  "passenger/get-profile-info");
              StorageService.saveProfile(response1["passenger"]);

              FSnackbar.show(
                title: "Success",
                message: "Profile updated successfully.",
              );
            }


            // ✅ FIX: Only call Get.back() once after everything is done

            // await Future.delayed(const Duration(milliseconds: 50));
            // Get.back(result: true); // Pass result to trigger refresh

          } else {
            FSnackbar.show(
              title: "Error",
              message: response["message"].toString(),
              isError: true,
            );
            throw Exception(response["message"] ?? "Something went wrong");
          }
          return response;
        },
        maxRetries: 2,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
      isEditingMode.value = false; // Exit editing mode after save
    }
  }

  @override
  void onClose() {

    firstNameFocus.dispose();
    lastNameFocus.dispose();
    emailFocus.dispose();
    contactFocus.dispose();
    emergencyFocus.dispose();
    countryFocus.dispose();
    cityFocus.dispose();


    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    contactCtrl.dispose();
    emergencyCtrl.dispose();
    countryCtrl.dispose();
    cityCtrl.dispose();
    super.onClose();
  }
}