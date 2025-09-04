// lib/features/profile_completion/screens/upload_vehicle_info_screen.dart
import 'dart:io';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../../utils/constants/colors.dart';
import '../controllers/upload_vehicle_controller.dart';

class UploadVehicleInfoScreen extends StatelessWidget {
  const UploadVehicleInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(UploadVehicleController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 60,
            left: 29,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
            ),
          ),
          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Vehicle Info",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Positioned(
            top: 101,
            left: 25,
            child: SizedBox(
              width: 362,
              child: Text(
                "Please provide detailed information about your vehicle.",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          const Positioned(top: 152, left: 29, child: Text("Vehicle Photo")),
          Obx(() {
            final f = c.vehImage.value;
            return Positioned(
              top: 188,
              left: 65,
              child: GestureDetector(
                onTap: () => c.pickVehImage(),
                child: Container(
                  width: 309,
                  height: 209,
                  decoration:
                      f == null
                          ? BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                          )
                          : null,
                  child:
                      f == null
                          ? Image.asset(FImages.car_placeholder)
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(f.path),
                              width: 309,
                              height: 209,
                              fit: BoxFit.cover,
                            ),
                          ),
                ),
              ),
            );
          }),
          Positioned(
            top: 414,
            left: 172,
            child: SizedBox(
              width: 125,
              height: 34,
              child: ElevatedButton(
                onPressed: () => c.pickVehImage(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FColors.secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text("Add a Photo", style: FTextTheme.darkTextTheme.labelSmall,),
              ),
            ),
          ),

          // Vehicle details label
          const Positioned(top: 462, left: 22, child: Text("Vehicle Details")),

          // Brand dropdown
          Positioned(
            top: 493,
            left: 22,
            child: Obx(
              () => SizedBox(
                width: 393,
                height: 52,
                child: DropdownButtonFormField<String>(
                  value: c.brand.value.isEmpty ? null : c.brand.value,
                  items:
                      c.brands
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                  onChanged: (v) {
                    c.brand.value = v ?? '';
                    c.loadModelsForBrand(c.brand.value);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF2F2F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Model dropdown
          Positioned(
            top: 563,
            left: 22,
            child: Obx(
              () => SizedBox(
                width: 393,
                height: 52,
                child: DropdownButtonFormField<String>(
                  value: c.model.value.isEmpty ? null : c.model.value,
                  items:
                      c.models
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                  onChanged: (v) {
                    c.model.value = v ?? '';
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF2F2F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Colour dropdown
          Positioned(
            top: 633,
            left: 22,
            child: Obx(
              () => SizedBox(
                width: 393,
                height: 52,
                child: DropdownButtonFormField<String>(
                  value: c.colour.value.isEmpty ? null : c.colour.value,
                  items:
                      c.colours
                          .map(
                            (col) =>
                                DropdownMenuItem(value: col, child: Text(col)),
                          )
                          .toList(),
                  onChanged: (v) {
                    c.colour.value = v ?? '';
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF2F2F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Plate no
          Positioned(
            top: 703,
            left: 22,
            child: SizedBox(
              width: 393,
              height: 52,
              child: TextField(
                onChanged: (v) => c.plateNo.value = v,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE3E3E3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "Registration plate",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Registration certificate field (navigates to registration screen)
          Positioned(
            top: 773,
            left: 22,
            child: GestureDetector(
              onTap: () {
                Get.toNamed('/upload-registration')?.then((_) {
                  // after return, reload any profile data (registration present)
                });
              },
              child: SizedBox(
                width: 393,
                height: 52,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E3E3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Registration Certificate"),
                      Icon(StorageService.getDriverStep("registration") ? Icons.check_circle : Icons.arrow_forward_ios, color: StorageService.getDriverStep("registration") ? FColors.textGreen : FColors.black , size: StorageService.getDriverStep("registration") ? 18 : 15,),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 876,
            left: 42,
            child: Obx(
              () => SizedBox(
                width: 358,
                height: 48,
                child: ElevatedButton(
                  onPressed: c.isLoading.value ? null : c.submitVehicleInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FColors.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      c.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
