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

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              Positioned(
                top: sh(60),
                left: sw(29),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, size: sw(24)),
                  onPressed: () => Get.back(),
                ),
              ),
              Positioned(
                top: sh(60),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "Vehicle Info",
                    style: TextStyle(
                      fontSize: sw(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: sh(101),
                left: sw(25),
                child: SizedBox(
                  width: sw(362),
                  child: Text(
                    "Please provide detailed information about your vehicle.",
                    style: TextStyle(fontSize: sw(14)),
                  ),
                ),
              ),
              Positioned(
                top: sh(152),
                left: sw(29),
                child: Text(
                  "Vehicle Photo",
                  style: TextStyle(fontSize: sw(16)),
                ),
              ),
              Obx(() {
                final f = c.vehImage.value;
                return Positioned(
                  top: sh(188),
                  left: sw(65),
                  child: GestureDetector(
                    onTap: () => c.pickVehImage(),
                    child: Container(
                      width: sw(309),
                      height: sh(209),
                      decoration: f == null
                          ? BoxDecoration(
                        borderRadius: BorderRadius.circular(sw(8)),
                        color: Colors.grey.shade200,
                      )
                          : null,
                      child: f == null
                          ? Image.asset(
                        FImages.car_placeholder,
                        width: sw(309),
                        height: sh(209),
                        fit: BoxFit.contain,
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(sw(8)),
                        child: Image.file(
                          File(f.path),
                          width: sw(309),
                          height: sh(209),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Positioned(
                top: sh(414),
                left: sw(172),
                child: SizedBox(
                  width: sw(148),
                  height: sh(34),
                  child: ElevatedButton(
                    onPressed: () => c.pickVehImage(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FColors.secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(sw(30)),
                      ),
                    ),
                    child: Text(
                      "Add a Photo",
                      style: FTextTheme.darkTextTheme.labelSmall?.copyWith(
                        fontSize: sw(14),
                      ),
                    ),
                  ),
                ),
              ),

              // Vehicle details label
              Positioned(
                top: sh(462),
                left: sw(22),
                child: Text(
                  "Vehicle Details",
                  style: TextStyle(fontSize: sw(16)),
                ),
              ),

              // Brand dropdown
              Positioned(
                top: sh(493),
                left: sw(22),
                child: Obx(
                      () => SizedBox(
                    width: sw(393),
                    height: sh(52),
                    child: DropdownButtonFormField<String>(
                      value: c.brand.value.isEmpty ? null : c.brand.value,
                      items: c.brands
                          .map(
                            (b) => DropdownMenuItem(
                          value: b,
                          child: Text(b, style: TextStyle(fontSize: sw(16))),
                        ),
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
                          borderRadius: BorderRadius.circular(sw(14)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: sw(12),
                          vertical: sh(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Model dropdown
              Positioned(
                top: sh(563),
                left: sw(22),
                child: Obx(
                      () => SizedBox(
                    width: sw(393),
                    height: sh(52),
                    child: DropdownButtonFormField<String>(
                      value: c.model.value.isEmpty ? null : c.model.value,
                      items: c.models
                          .map(
                            (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m, style: TextStyle(fontSize: sw(16))),
                        ),
                      )
                          .toList(),
                      onChanged: (v) {
                        c.model.value = v ?? '';
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF2F2F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(sw(14)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: sw(12),
                          vertical: sh(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Colour dropdown
              Positioned(
                top: sh(633),
                left: sw(22),
                child: Obx(
                      () => SizedBox(
                    width: sw(393),
                    height: sh(52),
                    child: DropdownButtonFormField<String>(
                      value: c.colour.value.isEmpty ? null : c.colour.value,
                      items: c.colours
                          .map(
                            (col) => DropdownMenuItem(
                          value: col,
                          child: Text(col, style: TextStyle(fontSize: sw(16))),
                        ),
                      )
                          .toList(),
                      onChanged: (v) {
                        c.colour.value = v ?? '';
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF2F2F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(sw(14)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: sw(12),
                          vertical: sh(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Plate no
              Positioned(
                top: sh(703),
                left: sw(22),
                child: SizedBox(
                  width: sw(393),
                  height: sh(52),
                  child: TextField(
                    onChanged: (v) => c.plateNo.value = v,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFE3E3E3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(sw(14)),
                        borderSide: BorderSide.none,
                      ),
                      hintText: "Registration plate",
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: sw(12),
                        vertical: sh(14),
                      ),
                    ),
                  ),
                ),
              ),

              // Registration certificate field (navigates to registration screen)
              Positioned(
                top: sh(773),
                left: sw(22),
                child: GestureDetector(
                  onTap: () {
                    Get.toNamed('/upload-registration')?.then((_) {
                      // after return, reload any profile data (registration present)
                    });
                  },
                  child: SizedBox(
                    width: sw(393),
                    height: sh(52),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: sw(12)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E3E3),
                        borderRadius: BorderRadius.circular(sw(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Registration Certificate",
                            style: TextStyle(fontSize: sw(16)),
                          ),
                          Icon(
                            StorageService.getDriverStep("registration")
                                ? Icons.check_circle
                                : Icons.arrow_forward_ios,
                            color: StorageService.getDriverStep("registration")
                                ? FColors.textGreen
                                : FColors.black,
                            size: StorageService.getDriverStep("registration")
                                ? sw(18)
                                : sw(15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: sh(876),
                left: sw(42),
                child: Obx(
                      () => SizedBox(
                    width: sw(358),
                    height: sh(48),
                    child: ElevatedButton(
                      onPressed: c.isLoading.value ? null : c.submitVehicleInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FColors.secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(sw(14)),
                        ),
                      ),
                      child: c.isLoading.value
                          ? CircularProgressIndicator(color: Colors.white, strokeWidth: sw(2))
                          : Text(
                        "Submit",
                        style: TextStyle(color: Colors.white, fontSize: sw(16)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}