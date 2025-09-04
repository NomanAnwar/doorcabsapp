// lib/features/profile_completion/controllers/upload_registration_controller.dart
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../utils/helpers/image_to_datauri.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/storage_service.dart';

class UploadRegistrationController extends GetxController {
  final productionYear = ''.obs;
  final frontFile = Rxn<File>();
  final backFile = Rxn<File>();
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

      // API returns registration_card; also might return updated driver
      if (response["registration_card"] != null) {
        // merge into driver profile if provided
        if (response["driver"] != null) {
          StorageService.saveProfile(Map<String, dynamic>.from(response["driver"]));
        } else {
          // attach registration_card under profile -> vehicle or document so later vehicle screen can read
          final profile = StorageService.getProfile() ?? {};
          profile['registration_card'] = response["registration_card"];
          StorageService.saveProfile(profile);
        }
      }

      StorageService.setDriverStep("registration", true); // signal that registration uploaded (vehicle step relies on this)
      Get.snackbar("Success", response["message"] ?? "Registration uploaded");
      // go back to vehicle info screen
      Get.offAllNamed('/upload-vehicle-info'); // adjust route if you used a different route name
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
