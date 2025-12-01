import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/storage_service.dart';
import '../../../../utils/http/api_retry_helper.dart';

class ProfileController extends GetxController {
  final formKey = GlobalKey<FormState>();

  /// Text Controllers
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final emergencyCtrl = TextEditingController();
  final countryCtrl = TextEditingController(text: "Pakistan");
  final cityCtrl = TextEditingController();

  /// Focus Nodes for keyboard navigation
  final firstNameFocus = FocusNode();
  final lastNameFocus = FocusNode();
  final emailFocus = FocusNode();
  final contactFocus = FocusNode();
  final emergencyFocus = FocusNode();
  final countryFocus = FocusNode();
  final cityFocus = FocusNode();

  final isLoading = false.obs;

  /// Image handling
  final profileImage = Rx<File?>(null); //  used directly in UI
  final base64Image = ''.obs;
  final _picker = ImagePicker();

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

  /// ✅ UPDATED: Pick image with retry for file operations
  Future<void> pickImage(ImageSource source) async {
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

  /// ✅ UPDATED: Save profile API with retry mechanism
  Future<void> saveAndContinue() async {
    if (!formKey.currentState!.validate()) return;

    final token = StorageService.getAuthToken();
    if (token == null) {
      Get.snackbar("Error", "User token not found. Please login again.");
      return;
    }

    /// 🔑 setAuthToken with useBearer: false so it goes in "token" header
    FHttpHelper.setAuthToken(token, useBearer: true);

    final body = {
      "firstName": firstNameCtrl.text.trim(),
      "lastName": lastNameCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      // "contact": contactCtrl.text.trim(),
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

          if (response["message"]?.toString().toLowerCase().contains("profile updated") ==
              true) {
            StorageService.saveProfile(body);

            final role = StorageService.getRole();

            if(role == "driver" || role == "Driver") {

              StorageService.setDriverStep("basic", true);

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
                isError: false,
              );

              Get.offAllNamed('/profile-completion');

            } else if(role == "passenger" || role == "Passenger"){


              final response1 = await FHttpHelper.get(
                  "passenger/get-profile-info");
              StorageService.saveProfile(response1["passenger"]);

              FSnackbar.show(
                title: "Success",
                message: "Profile updated successfully.",
                isError: false,
              );

              Get.offAllNamed('/ride-type');
              // Get.offAllNamed('/ride-home');


            }

          } else {
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
    }
  }


  @override
  void onClose() {
    // Dispose focus nodes
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    emailFocus.dispose();
    contactFocus.dispose();
    emergencyFocus.dispose();
    countryFocus.dispose();
    cityFocus.dispose();

    // Dispose controllers
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