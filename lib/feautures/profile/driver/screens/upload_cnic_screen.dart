// lib/features/profile_completion/screens/upload_cnic_screen.dart
import 'dart:io';
import 'package:doorcab/feautures/profile/driver/screens/reuseable_widgets/custome_dashed_border_container.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../../utils/constants/colors.dart';
import '../controllers/upload_cnic_controller.dart';

class UploadCnicScreen extends StatelessWidget {
  const UploadCnicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(UploadCnicController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        return Stack(
          children: [
            SingleChildScrollView(
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
                          "CNIC upload",
                          style: TextStyle(
                            fontSize: sw(18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: sh(98),
                      left: sw(40),
                      child: Text(
                        "Enter CNIC number",
                        style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                          fontSize: sw(16),
                        ),
                      ),
                    ),
                    Positioned(
                      top: sh(125),
                      left: sw(24),
                      child: SizedBox(
                        width: sw(393),
                        height: sh(52),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          onChanged: (v) => c.cnicNumber.value = v,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFE3E3E3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(sw(14)),
                              borderSide: BorderSide.none,
                            ),
                            hintText: "42101-1234567-1",
                            hintStyle: FTextTheme.lightTextTheme.bodyMedium!
                                .copyWith(color: FColors.black.withOpacity(0.2)),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: sw(12),
                              vertical: sh(14),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Front label + container
                    Positioned(
                      top: sh(213),
                      left: sw(112),
                      child: Text(
                        "Upload CNIC Front Side",
                        style: TextStyle(fontSize: sw(16)),
                      ),
                    ),
                    Obx(() {
                      final f = c.frontFile.value;
                      return Positioned(
                        top: sh(249),
                        left: sw(53),
                        child: GestureDetector(
                          onTap: () async => await c.pickFront(),
                          child: DashedBorderContainer(
                            width: sw(331),
                            height: sh(196),
                            borderRadius: sw(8),
                            child: f == null
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Upload File",
                                  style: FTextTheme
                                      .lightTextTheme.titleMedium
                                      ?.copyWith(fontSize: sw(16)),
                                ),
                                SizedBox(height: sh(8)),
                                Text(
                                  "Take a photo or choose from gallery",
                                  style: TextStyle(fontSize: sw(14)),
                                ),
                                SizedBox(height: sh(12)),
                                SizedBox(
                                  width: sw(135),
                                  height: sh(40),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                      const Color(0xFFF2F2F2),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(sw(8)),
                                      ),
                                    ),
                                    onPressed: () => c.pickFront(),
                                    child: Text(
                                      "Choose File",
                                      style:
                                      TextStyle(fontSize: sw(14)),
                                    ),
                                  ),
                                ),
                              ],
                            )
                                : ClipRRect(
                              borderRadius: BorderRadius.circular(sw(8)),
                              child: Image.file(
                                File(f.path),
                                width: sw(331),
                                height: sh(196),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Back side
                    Positioned(
                      top: sh(482),
                      left: sw(112),
                      child: Text(
                        "Upload CNIC Back Side",
                        style: TextStyle(fontSize: sw(16)),
                      ),
                    ),
                    Obx(() {
                      final b = c.backFile.value;
                      return Positioned(
                        top: sh(518),
                        left: sw(53),
                        child: GestureDetector(
                          onTap: () async => await c.pickBack(),
                          child: DashedBorderContainer(
                            width: sw(331),
                            height: sh(196),
                            borderRadius: sw(8),
                            child: b == null
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Upload File",
                                  style: FTextTheme
                                      .lightTextTheme.titleMedium
                                      ?.copyWith(fontSize: sw(16)),
                                ),
                                SizedBox(height: sh(8)),
                                Text(
                                  "Take a photo or choose from gallery",
                                  style: TextStyle(fontSize: sw(14)),
                                ),
                                SizedBox(height: sh(12)),
                                SizedBox(
                                  width: sw(135),
                                  height: sh(40),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                      const Color(0xFFF2F2F2),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(sw(8)),
                                      ),
                                    ),
                                    onPressed: () => c.pickBack(),
                                    child: Text(
                                      "Choose File",
                                      style:
                                      TextStyle(fontSize: sw(14)),
                                    ),
                                  ),
                                ),
                              ],
                            )
                                : ClipRRect(
                              borderRadius: BorderRadius.circular(sw(8)),
                              child: Image.file(
                                File(b.path),
                                width: sw(331),
                                height: sh(196),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Submit
                    Positioned(
                      top: sh(876),
                      left: sw(42),
                      child: SizedBox(
                        width: sw(358),
                        height: sh(48),
                        child: ElevatedButton(
                          onPressed:
                          c.isLoading.value ? null : c.submitCnic,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FColors.secondaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(sw(14)),
                            ),
                          ),
                          child: Text(
                            "Submit",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sw(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fullscreen loader overlay
            if (c.isLoading.value)
              Container(
                width: screenWidth,
                height: screenHeight,
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
