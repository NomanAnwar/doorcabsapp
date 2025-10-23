import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../../../utils/helpers/image_to_datauri.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/storage_service.dart';

class UploadRegistrationController extends GetxController {
  final productionYear = ''.obs;
  final frontFile = Rxn<File>();
  final backFile = Rxn<File>();
  final isLoading = false.obs;

  final ImagePicker _picker = ImagePicker();

  /// Pick front side of registration
  Future<void> pickFront() async {
    await _showPicker(isFront: true);
  }

  /// Pick back side of registration
  Future<void> pickBack() async {
    await _showPicker(isFront: false);
  }

  /// Bottom sheet for selecting camera or gallery
  Future<void> _showPicker({required bool isFront}) async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: const Text('Take Photo'),
                onTap: () async {
                  Get.back();
                  await _pickImage(isFront, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Get.back();
                  await _pickImage(isFront, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.red),
                title: const Text('Cancel'),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Actual image picker logic
  Future<void> _pickImage(bool isFront, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (isFront) {
          frontFile.value = file;
        } else {
          backFile.value = file;
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  /// Submit registration data + images
  Future<void> submitRegistration() async {
    if (productionYear.value.trim().isEmpty) {
      Get.snackbar("Error", "Please enter production year");
      return;
    }
    if (frontFile.value == null || backFile.value == null) {
      Get.snackbar("Error", "Please upload both front and back registration images");
      return;
    }

    try {
      isLoading.value = true;

      final body = {
        "number_field": productionYear.value.trim(),
        "reg_front": await ImageToDataUri.fileToDataUri(frontFile.value!),
        "reg_back": await ImageToDataUri.fileToDataUri(backFile.value!),
      };

      final token = StorageService.getAuthToken();
      if (token == null) {
        Get.snackbar("Error", "User token not found. Please login again.");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response = await FHttpHelper.post("driver/upload-registration", body);

      // Store registration info in local storage
      if (response["registration_card"] != null) {
        if (response["driver"] != null) {
          StorageService.saveProfile(Map<String, dynamic>.from(response["driver"]));
        } else {
          final profile = StorageService.getProfile() ?? {};
          profile['registration_card'] = response["registration_card"];
          StorageService.saveProfile(profile);
        }
      }

      StorageService.setDriverStep("registration", true);
      Get.snackbar("Success", response["message"] ?? "Registration uploaded");
      Get.offNamed('/upload-vehicle-info'); // Go back to vehicle info screen
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
