import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/helpers/image_to_datauri.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/storage_service.dart';

class UploadLicenseController extends GetxController {
  final frontFile = Rxn<File>();
  final backFile = Rxn<File>();
  final licenseNumber = ''.obs;
  final licenseExpiry = ''.obs;
  final isLoading = false.obs;

  final ImagePicker _picker = ImagePicker();

  /// Allow user to pick front image (camera or gallery)
  Future<void> pickFront() async {
    await _showPicker(isFront: true);
  }

  /// Allow user to pick back image (camera or gallery)
  Future<void> pickBack() async {
    await _showPicker(isFront: false);
  }

  /// Bottom sheet for camera/gallery selection
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

  /// Handles actual picking
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
        backgroundColor: const Color(0xFFB00020),
        colorText: Colors.white,
      );
    }
  }

  /// Upload license info + images
  Future<void> submitLicense() async {
    if (frontFile.value == null || backFile.value == null) {
      Get.snackbar("Error", "Please upload both license images");
      return;
    }
    if (licenseNumber.value.trim().isEmpty) {
      Get.snackbar("Error", "Please enter license number");
      return;
    }
    if (licenseExpiry.value.trim().isEmpty) {
      Get.snackbar("Error", "Please enter expiry date");
      return;
    }

    try {
      isLoading.value = true;

      final body = {
        "license_front": await ImageToDataUri.fileToDataUri(frontFile.value!),
        "license_back": await ImageToDataUri.fileToDataUri(backFile.value!),
        "license_number": licenseNumber.value.trim(),
        "license_expiry": licenseExpiry.value.trim(),
      };

      final token = StorageService.getAuthToken();
      if (token == null) {
        Get.snackbar("Error", "User token not found. Please login again.");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response = await FHttpHelper.post("driver/upload-license", body);

      // Save profile if driver data returned
      if (response["driver"] != null) {
        StorageService.saveProfile(Map<String, dynamic>.from(response["driver"]));
      }

      StorageService.setDriverStep("licence", true);
      FSnackbar.show(title: "Success", message: response["message"] ?? "License uploaded");
      Get.offAllNamed('/profile-completion');
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
