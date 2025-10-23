// lib/features/profile_completion/controllers/upload_vehicle_controller.dart
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../utils/helpers/image_to_datauri.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/storage_service.dart';

class UploadVehicleController extends GetxController {
  final brand = ''.obs;
  final model = ''.obs;
  final colour = ''.obs;
  final plateNo = ''.obs;
  final vehImage = Rxn<File>();
  final isLoading = false.obs;

  final brands = <String>[].obs;
  final models = <String>[].obs;
  final colours = <String>[].obs;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _loadBrands();
    // prefill from saved profile if present
    final profile = StorageService.getProfile();
    if (profile != null) {
      // attempt to prefill fields
      brand.value = profile['vehicle']?['type']?.toString() ?? '';
      model.value = profile['vehicle']?['model']?.toString() ?? '';
      colour.value = profile['vehicle']?['colour']?.toString() ?? '';
      plateNo.value = profile['vehicle']?['plate_no']?.toString() ?? '';
    }
  }

  Future<void> _loadBrands() async {
    // NOTE: You said to fetch from package/API. If you have an endpoint provide it,
    // otherwise we'll use a small static fallback plus attempt to call a public sample API.
    try {
      brands.assignAll(["Toyota", "Honda", "Suzuki", "Kia", "Hyundai"]);
      // Optionally fetch remote list here and replace brands
    } catch (_) {}
  }

  Future<void> loadModelsForBrand(String brandName) async {
    // placeholder mapping; ideally call real API
    if (brandName.toLowerCase() == 'toyota') {
      models.assignAll(["Corolla 2020", "Corolla 2019", "Yaris"]);
      colours.assignAll(["White", "Black", "Silver"]);
    } else if (brandName.toLowerCase() == 'honda') {
      models.assignAll(["Civic 2020", "Civic 2019"]);
      colours.assignAll(["Red", "White", "Grey"]);
    } else {
      models.assignAll(["Model A", "Model B"]);
      colours.assignAll(["White", "Black"]);
    }
  }

  Future<void> pickVehImage() async {
    final XFile? x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;
    vehImage.value = File(x.path);
  }

  final Map<String, String?> vehicleImages = {
    "front_side": null,
    "back_side": null,
    "side_one": null,
    "side_two": null,
    "inside_front": null,
    "inside_back": null,
  };

  void setVehicleImages(Map<String, String?> images) {
    vehicleImages.addAll(images);
    // Show first image in preview
    final first = images["front_side"];
    if (first != null) vehImage.value = File(first);
  }


  Future<void> submitVehicleInfo() async {
    final profile = StorageService.getProfile();
    final reg = profile?['registration_card'];
    if (reg == null) {
      Get.snackbar("Error", "Please upload registration certificate first");
      return;
    }

    if (brand.value.trim().isEmpty ||
        model.value.trim().isEmpty ||
        colour.value.trim().isEmpty ||
        plateNo.value.trim().isEmpty ||
        vehicleImages.values.any((v) => v == null)) {
      Get.snackbar("Error", "Please complete vehicle details and all 6 photos");
      return;
    }

    try {
      isLoading.value = true;

      final Map<String, dynamic> vehicleImagesBase64 = {};
      // for (var entry in vehicleImages.entries) {
      //   vehicleImagesBase64[entry.key] =
      //   await ImageToDataUri.fileToDataUri(File(entry.value!));
      // }

      await Future.wait(vehicleImages.entries.map((entry) async {
        final file = File(entry.value!);

        // optionally compress image before encoding
        final dataUri = await ImageToDataUri.fileToDataUri(file,);
        vehicleImagesBase64[entry.key] = dataUri;
      }));

      final body = {
        "brand": brand.value,
        "model": model.value,
        "colour": colour.value,
        "plate_no": plateNo.value,
        "registration_certificate": true,
        "preferred_vehicle": StorageService.getVehicleType(),
        "preferred_rideType": StorageService.getDriverType(),
        "vehicle_images": vehicleImagesBase64,
      };

      final token = StorageService.getAuthToken();
      if (token == null) {
        Get.snackbar("Error", "User token not found. Please login again.");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response = await FHttpHelper.post("driver/upload-vehicleInfo", body);

      if (response["vehicle"] != null) {
        final profileMap = StorageService.getProfile() ?? {};
        profileMap['vehicle'] = Map<String, dynamic>.from(response["vehicle"]);
        StorageService.saveProfile(profileMap);
      }

      StorageService.setDriverStep("vehicle", true);
      Get.snackbar("Success", response["message"] ?? "Vehicle info updated");
      Get.offAllNamed('/profile-completion');
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }


// Future<void> submitVehicleInfo() async {
  //   // must ensure registration uploaded — check saved profile for registration_card
  //   final profile = StorageService.getProfile();
  //   final reg = profile?['registration_card'];
  //   if (reg == null) {
  //     Get.snackbar("Error", "Please upload registration certificate first");
  //     return;
  //   }
  //
  //   if (brand.value.trim().isEmpty || model.value.trim().isEmpty || colour.value.trim().isEmpty || plateNo.value.trim().isEmpty || vehImage.value == null) {
  //     Get.snackbar("Error", "Please complete vehicle details and add a photo");
  //     return;
  //   }
  //
  //   try {
  //     isLoading.value = true;
  //     final body = {
  //       "brand": brand.value,
  //       "model": model.value,
  //       "colour": colour.value,
  //       "plate_no": plateNo.value,
  //       "vehical_image": await ImageToDataUri.fileToDataUri(vehImage.value!),
  //       "registration_card": reg, // send reg info saved earlier (or server may expect an id/url)
  //     };
  //
  //     final token = StorageService.getAuthToken();
  //     if (token == null) {
  //       Get.snackbar("Error", "User token not found. Please login again.");
  //       return;
  //     }
  //
  //     FHttpHelper.setAuthToken(token, useBearer: true);
  //
  //
  //     final response = await FHttpHelper.post("driver/upload-vehicleInfo", body);
  //
  //     // save updated vehicle into profile (if returned)
  //     if (response["vehicle"] != null) {
  //       final profileMap = StorageService.getProfile() ?? {};
  //       profileMap['vehicle'] = Map<String, dynamic>.from(response["vehicle"]);
  //       StorageService.saveProfile(profileMap);
  //     }
  //
  //     StorageService.setDriverStep("vehicle", true);
  //     Get.snackbar("Success", response["message"] ?? "Vehicle info updated");
  //     Get.offAllNamed('/profile-completion');
  //   } catch (e) {
  //     Get.snackbar("Error", e.toString());
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
}
