// lib/features/profile_completion/controllers/upload_license_controller.dart
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> pickFront() async {
    final XFile? x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;
    frontFile.value = File(x.path);
  }

  Future<void> pickBack() async {
    final XFile? x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;
    backFile.value = File(x.path);
  }

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

      // update profile if driver object returned
      if (response["driver"] != null) {
        StorageService.saveProfile(Map<String, dynamic>.from(response["driver"]));
      }

      StorageService.setDriverStep("licence", true);
      Get.snackbar("Success", response["message"] ?? "License uploaded");
      Get.offAllNamed('/profile-completion'); // return to vehicle screen
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
