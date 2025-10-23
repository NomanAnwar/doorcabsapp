import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../utils/helpers/image_to_datauri.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/storage_service.dart';

class UploadSelfieController extends GetxController {
  final selfieFile = Rxn<File>();
  final isLoading = false.obs;

  final ImagePicker _picker = ImagePicker();

  /// Open camera/gallery picker bottom sheet
  Future<void> pickSelfie() async {
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
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Get.back();
                  await _pickImage(ImageSource.gallery);
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

  /// Internal image picker logic
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front, // Front camera for selfie
      );

      if (picked != null) {
        selfieFile.value = File(picked.path);
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

  /// Submit selfie to backend
  Future<void> submitSelfie() async {
    if (selfieFile.value == null) {
      Get.snackbar("Error", "Please choose or take a selfie");
      return;
    }

    try {
      isLoading.value = true;

      final body = {
        "selfie": await ImageToDataUri.fileToDataUri(selfieFile.value!),
      };

      final token = StorageService.getAuthToken();
      if (token == null) {
        Get.snackbar("Error", "User token not found. Please login again.");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      final response = await FHttpHelper.post("driver/upload-selfie", body);

      // Save driver profile if returned
      if (response["driver"] != null) {
        StorageService.saveProfile(Map<String, dynamic>.from(response["driver"]));
      }

      StorageService.setDriverStep("selfie", true);
      Get.snackbar("Success", response["message"] ?? "Selfie uploaded successfully");
      Get.offAllNamed('/profile-completion');
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
