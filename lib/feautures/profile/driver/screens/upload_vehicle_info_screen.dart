import 'dart:io';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/upload_vehicle_controller.dart';

class UploadVehicleInfoScreen extends StatelessWidget {
  const UploadVehicleInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<UploadVehicleController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference base size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;
    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        return Stack(
          children: [
            /// Main UI
            SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                height: screenHeight,
                child: Stack(
                  children: [
                    /// Back button
                    Positioned(
                      top: sh(60),
                      left: sw(29),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, size: sw(28)),
                        onPressed: () => Get.back(),
                      ),
                    ),

                    /// Title
                    Positioned(
                      top: sh(70),
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          "Vehicle Info",
                          style: FTextTheme.lightTextTheme.headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize:
                            FTextTheme.lightTextTheme.headlineSmall!.fontSize! *
                                screenWidth /
                                baseWidth,
                          ),
                        ),
                      ),
                    ),

                    /// Subtitle
                    Positioned(
                      top: sh(115),
                      left: sw(20),
                      right: sw(20),
                      child: Text(
                        "Please provide detailed information about your vehicle.",
                        textAlign: TextAlign.center,
                        style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                          fontSize:
                          FTextTheme.lightTextTheme.bodyLarge!.fontSize! *
                              screenWidth /
                              baseWidth,
                          color: FColors.chipBg,
                        ),
                      ),
                    ),

                    /// Vehicle Photo Label
                    Positioned(
                      top: sh(170),
                      left: sw(30),
                      child: Text(
                        "Vehicle Photo",
                        style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: FColors.black,
                          fontSize:
                          FTextTheme.lightTextTheme.titleLarge!.fontSize! *
                              screenWidth /
                              baseWidth,
                        ),
                      ),
                    ),

                    /// Vehicle Photo Preview
                    Obx(() {
                      final f = c.vehImage.value;
                      return Positioned(
                        top: sh(205),
                        left: (screenWidth / 2) - sw(155),
                        child: GestureDetector(
                          // onTap: () => Get.toNamed('/vehicle-images'),
                          onTap: () async {
                            // final result = await Get.toNamed('/vehicle-images');
                            // if (result != null && result is Map<String, String?>) {
                            //   c.setVehicleImages(result);
                            // }

                            final allDone = c.vehicleImages.values.every((v) => v != null);

                            final result = await Get.toNamed(
                              '/vehicle-images',
                              arguments: {'startPage': allDone ? 6 : 0},
                            );

                            if (result != null && result is Map<String, String?>) {
                              c.setVehicleImages(result);
                            }
                          },

                          child: Container(
                            width: sw(310),
                            height: sh(210),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(sw(12)),
                              color: f == null
                                  ? Colors.grey.shade200
                                  : Colors.transparent,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(sw(12)),
                              child: f == null
                                  ? Image.asset(
                                FImages.car_placeholder,
                                width: sw(310),
                                height: sh(210),
                                fit: BoxFit.cover,
                              )
                                  : Image.file(
                                File(f.path),
                                width: sw(310),
                                height: sh(210),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    /// Add Photo Button
                    Positioned(
                      top: sh(430),
                      left: (screenWidth / 2) - sw(75),
                      child: SizedBox(
                        width: sw(150),
                        height: sh(42),
                        child: ElevatedButton(
                          // onPressed: () => Get.toNamed('/vehicle-images'),
                          onPressed: () async {
                            // final result = await Get.toNamed('/vehicle-images');
                            // if (result != null && result is Map<String, String?>) {
                            //   c.setVehicleImages(result);
                            // }

                            final allDone = c.vehicleImages.values.every((v) => v != null);

                            final result = await Get.toNamed(
                              '/vehicle-images',
                              arguments: {'startPage': allDone ? 6 : 0},
                            );

                            if (result != null && result is Map<String, String?>) {
                              c.setVehicleImages(result);
                            }

                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: FColors.secondaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(sw(30)),
                            ),
                          ),
                          child: Text(
                            "Add a Photo",
                            style: FTextTheme.darkTextTheme.labelLarge?.copyWith(
                              fontSize: FTextTheme
                                  .darkTextTheme.labelLarge!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Vehicle Details Label
                    Positioned(
                      top: sh(480),
                      left: sw(30),
                      child: Text(
                        "Vehicle Details",
                        style: FTextTheme.lightTextTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: FColors.black,
                          fontSize:
                          FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                              screenWidth /
                              baseWidth,
                        ),
                      ),
                    ),

                    /// Brand Dropdown
                    Positioned(
                      top: sh(520),
                      left: sw(30),
                      child: Obx(
                            () => SizedBox(
                          width: sw(380),
                          height: sh(52),
                          child: DropdownButtonFormField<String>(
                            value: c.brand.value.isEmpty ? null : c.brand.value,
                            items: c.brands
                                .map(
                                  (b) => DropdownMenuItem(
                                value: b,
                                child: Text(
                                  b,
                                  style:
                                  FTextTheme.lightTextTheme.bodyLarge!
                                      .copyWith(
                                    fontSize: sw(16),
                                  ),
                                ),
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

                    /// Model Dropdown
                    Positioned(
                      top: sh(590),
                      left: sw(30),
                      child: Obx(
                            () => SizedBox(
                          width: sw(380),
                          height: sh(52),
                          child: DropdownButtonFormField<String>(
                            value: c.model.value.isEmpty ? null : c.model.value,
                            items: c.models
                                .map(
                                  (m) => DropdownMenuItem(
                                value: m,
                                child: Text(
                                  m,
                                  style:
                                  FTextTheme.lightTextTheme.bodyLarge!
                                      .copyWith(fontSize: sw(16)),
                                ),
                              ),
                            )
                                .toList(),
                            onChanged: (v) => c.model.value = v ?? '',
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

                    /// Colour Dropdown
                    Positioned(
                      top: sh(660),
                      left: sw(30),
                      child: Obx(
                            () => SizedBox(
                          width: sw(380),
                          height: sh(52),
                          child: DropdownButtonFormField<String>(
                            value:
                            c.colour.value.isEmpty ? null : c.colour.value,
                            items: c.colours
                                .map(
                                  (col) => DropdownMenuItem(
                                value: col,
                                child: Text(
                                  col,
                                  style:
                                  FTextTheme.lightTextTheme.bodyLarge!
                                      .copyWith(fontSize: sw(16)),
                                ),
                              ),
                            )
                                .toList(),
                            onChanged: (v) => c.colour.value = v ?? '',
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

                    /// Plate Number
                    Positioned(
                      top: sh(730),
                      left: sw(30),
                      child: SizedBox(
                        width: sw(380),
                        height: sh(52),
                        child: TextField(
                          onChanged: (v) => c.plateNo.value = v,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF2F2F2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(sw(14)),
                              borderSide: BorderSide.none,
                            ),
                            hintText: "Registration Plate",
                            hintStyle: FTextTheme.lightTextTheme.bodyLarge!
                                .copyWith(color: FColors.chipBg, fontSize: sw(16)),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: sw(12),
                              vertical: sh(14),
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Registration Certificate Field
                    Positioned(
                      top: sh(800),
                      left: sw(30),
                      child: GestureDetector(
                        onTap: () {
                          Get.toNamed('/upload-registration');
                        },
                        child: Container(
                          width: sw(380),
                          height: sh(52),
                          padding: EdgeInsets.symmetric(horizontal: sw(12)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(sw(14)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Registration Certificate",
                                style: FTextTheme.lightTextTheme.bodyLarge!
                                    .copyWith(fontSize: sw(16)),
                              ),
                              Icon(
                                StorageService.getDriverStep("registration")
                                    ? Icons.check_circle
                                    : Icons.arrow_forward_ios,
                                color: StorageService.getDriverStep("registration")
                                    ? FColors.textGreen
                                    : FColors.black,
                                size: sw(18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// Submit Button
                    Positioned(
                      top: sh(880),
                      left: sw(42),
                      child: SizedBox(
                        width: sw(358),
                        height: sh(50),
                        child: ElevatedButton(
                          onPressed:
                          c.isLoading.value ? null : c.submitVehicleInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FColors.secondaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(sw(14)),
                            ),
                          ),
                          child: Text(
                            "Submit",
                            style: FTextTheme.darkTextTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontSize: FTextTheme
                                  .darkTextTheme.bodyLarge!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Loader Overlay
            if (c.isLoading.value)
              Container(
                width: screenWidth,
                height: screenHeight,
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        );
      }),
    );
  }
}
