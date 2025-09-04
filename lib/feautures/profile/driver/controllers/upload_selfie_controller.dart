// lib/features/profile_completion/controllers/upload_selfie_controller.dart
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../utils/helpers/image_to_datauri.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/storage_service.dart';

class UploadSelfieController extends GetxController {
  final selfieFile = Rxn<File>();
  final isLoading = false.obs;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickSelfie() async {
    final XFile? x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;
    selfieFile.value = File(x.path);
  }

  Future<void> submitSelfie() async {
    if (selfieFile.value == null) {
      Get.snackbar("Error", "Please choose a selfie image");
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
      // API returns a driver object similar to CNIC response — save it
      if (response["driver"] != null) {
        StorageService.saveProfile(Map<String, dynamic>.from(response["driver"]));
      }

      StorageService.setDriverStep("selfie", true);
      Get.snackbar("Success", response["message"] ?? "Selfie uploaded");
      Get.offAllNamed('/profile-completion');
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
