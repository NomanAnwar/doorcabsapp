// lib/features/profile_completion/controllers/upload_cnic_controller.dart
import 'dart:io';
import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
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

      print("Auth Token : "+ StorageService.getAuthToken().toString());
      final model = CNICResponse.fromJson(response);

      // Save returned driver info for later usage
      if (model.driver.isNotEmpty) {
        StorageService.saveProfile(model.driver);
      }

      // Mark step completed
      StorageService.setDriverStep("cnic", true);

      // Get.snackbar("Success", model.message);
      FSnackbar.show(title: "Success",message: model.message);
      // go back to profile completion screen
      Get.offAllNamed('/profile-completion');
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
