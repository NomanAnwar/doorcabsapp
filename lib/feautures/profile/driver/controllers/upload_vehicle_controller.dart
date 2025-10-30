// lib/features/profile_completion/controllers/upload_vehicle_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
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
  final isDataLoading = false.obs;

  final brands = <String>[].obs;
  final models = <String>[].obs;
  final colours = <String>[].obs;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();

    // ✅ FIXED: Use delayed initialization to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _prefillFromProfile();
    });
  }

  // ✅ FIXED: Separate method for profile prefill with model loading
  void _prefillFromProfile() {
    final profile = StorageService.getProfile();
    if (profile != null) {
      // attempt to prefill fields
      brand.value = profile['vehicle']?['type']?.toString() ?? '';
      model.value = profile['vehicle']?['model']?.toString() ?? '';
      colour.value = profile['vehicle']?['colour']?.toString() ?? '';
      plateNo.value = profile['vehicle']?['plate_no']?.toString() ?? '';

      // ✅ FIXED: Load models for the pre-filled brand (if brand exists)
      if (brand.value.isNotEmpty) {
        loadModelsForBrand(brand.value);
      }
    }
  }

  Future<void> _loadInitialData() async {
    try {
      isDataLoading.value = true;

      // Load brands and colors simultaneously
      await Future.wait([
        _loadBrands(),
        _loadColors()
      ]);

    } catch (_) {
      // Fallback to hardcoded data if API fails
      brands.assignAll(["Toyota", "Honda", "Suzuki", "Kia", "Hyundai"]);
      colours.assignAll(["White", "Black", "Silver", "Red", "Blue", "Grey"]);
    } finally {
      isDataLoading.value = false;
    }
  }

  Future<void> _loadBrands() async {
    try {
      final response = await FHttpHelper.get("brand/brandName");

      if (response["success"] == true && response["brands"] != null) {
        final brandsList = List<String>.from(
            response["brands"].map<String>((brandData) => brandData["brand"].toString())
        );
        brands.assignAll(brandsList);
      } else {
        // Fallback to hardcoded brands if API fails
        brands.assignAll(["Toyota", "Honda", "Suzuki", "Kia", "Hyundai"]);
      }
    } catch (_) {
      // Fallback to hardcoded brands if API fails
      brands.assignAll(["Toyota", "Honda", "Suzuki", "Kia", "Hyundai"]);
    }
  }

  Future<void> _loadColors() async {
    try {
      final response = await FHttpHelper.get("brand/colors");

      if (response["success"] == true && response["colors"] != null) {
        final colorsList = List<String>.from(
            response["colors"].map<String>((colorData) => colorData["name"].toString())
        );
        colours.assignAll(colorsList);
      } else {
        // Fallback to hardcoded colors if API fails
        colours.assignAll(["White", "Black", "Silver", "Red", "Blue", "Grey"]);
      }
    } catch (_) {
      // Fallback to hardcoded colors if API fails
      colours.assignAll(["White", "Black", "Silver", "Red", "Blue", "Grey"]);
    }
  }

  Future<void> loadModelsForBrand(String brandName) async {
    try {
      if (brandName.isEmpty) return;

      // Clear current models and reset model selection
      models.clear();
      model.value = '';

      final response = await FHttpHelper.get("brand/brandName");

      if (response["success"] == true && response["brands"] != null) {
        final brandData = response["brands"].firstWhere(
              (brandData) => brandData["brand"].toString().toLowerCase() == brandName.toLowerCase(),
          orElse: () => null,
        );

        if (brandData != null && brandData["models"] != null) {
          // Remove duplicates by converting to Set and back to List
          final modelsList = List<String>.from(
              brandData["models"].map<String>((model) => model.toString())
          );
          final uniqueModels = modelsList.toSet().toList(); // Remove duplicates
          models.assignAll(uniqueModels);
        } else {
          // Fallback if brand not found in API response
          _setFallbackModels(brandName);
        }
      } else {
        // Fallback if API fails
        _setFallbackModels(brandName);
      }
    } catch (_) {
      // Fallback if any error occurs
      _setFallbackModels(brandName);
    }
  }

  void _setFallbackModels(String brandName) {
    // Fallback mapping; same as your original logic
    if (brandName.toLowerCase() == 'toyota') {
      models.assignAll(["Corolla 2020", "Corolla 2019", "Yaris"]);
    } else if (brandName.toLowerCase() == 'honda') {
      models.assignAll(["Civic 2020", "Civic 2019"]);
    } else {
      models.assignAll(["Model A", "Model B"]);
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

      await Future.wait(vehicleImages.entries.map((entry) async {
        final file = File(entry.value!);
        final dataUri = await ImageToDataUri.fileToDataUri(file);
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
}