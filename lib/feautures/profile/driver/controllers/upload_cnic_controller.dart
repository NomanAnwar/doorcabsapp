import 'dart:io';
import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../utils/helpers/image_to_datauri.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/storage_service.dart';
import '../models/cnic_response.dart';

class UploadCnicController extends GetxController {
  final cnicNumber = ''.obs;
  final frontFile = Rxn<File>();
  final backFile = Rxn<File>();
  final isLoading = false.obs;

  final ImagePicker _picker = ImagePicker();

  /// Show bottom sheet for selecting camera or gallery
  Future<void> pickFront() async {
    await _showPicker(isFront: true);
  }

  Future<void> pickBack() async {
    await _showPicker(isFront: false);
  }

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
        backgroundColor: const Color(0xFFB00020),
        colorText: Colors.white,
      );
    }
  }

  Future<void> submitCnic() async {
    if (cnicNumber.value.trim().isEmpty) {
      Get.snackbar("Error", "Please enter CNIC number");
      return;
    }
    if (frontFile.value == null || backFile.value == null) {
      Get.snackbar("Error", "Please upload both front and back CNIC images");
      return;
    }

    try {
      isLoading.value = true;

      final body = {
        "cnic_number": cnicNumber.value.trim(),
        "cnic_front": await ImageToDataUri.fileToDataUri(frontFile.value!),
        "cnic_back": await ImageToDataUri.fileToDataUri(backFile.value!),
      };

      final token = StorageService.getAuthToken();
      if (token == null) {
        Get.snackbar("Error", "User token not found. Please login again.");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response = await FHttpHelper.post("driver/upload-cnic", body);

      final model = CNICResponse.fromJson(response);

      if (model.driver.isNotEmpty) {
        StorageService.saveProfile(model.driver);
      }

      StorageService.setDriverStep("cnic", true);
      FSnackbar.show(title: "Success", message: model.message);
      Get.offAllNamed('/profile-completion');
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
