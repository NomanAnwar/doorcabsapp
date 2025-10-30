// lib/features/profile_completion/screens/upload_selfie_screen.dart
import 'dart:io';
import 'package:doorcab/utils/constants/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../../utils/constants/colors.dart';
import '../controllers/upload_selfie_controller.dart';

class UploadSelfieScreen extends StatelessWidget {
  const UploadSelfieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(UploadSelfieController());

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
                          "Selfie with ID",
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
                        width: sw(390),
                        child: Text(
                          "Take a selfie holding your ID document (CNIC, driving license, etc.) clearly visible. Ensure your face and the document details are in focus",
                          style: TextStyle(fontSize: sw(14)),
                        ),
                      ),
                    ),
                    Obx(() {
                      final f = c.selfieFile.value;
                      return Positioned(
                        top: sh(203),
                        left: sw(41),
                        child: GestureDetector(
                          onTap: () => c.pickSelfie(),
                          child: Container(
                            width: sw(358),
                            height: sh(537),
                            decoration: f == null
                                ? BoxDecoration(
                              borderRadius: BorderRadius.circular(sw(8)),
                              color: Colors.grey.shade200,
                            )
                                : null,
                            child: f == null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(sw(8)),
                              child: Image.asset(
                                FImages.selfie_placeholder,
                                width: sw(358),
                                height: sh(537),
                                fit: BoxFit.cover,
                              ),
                            )
                                : ClipRRect(
                              borderRadius: BorderRadius.circular(sw(8)),
                              child: Image.file(
                                File(f.path),
                                width: sw(358),
                                height: sh(537),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    Positioned(
                      top: sh(767),
                      left: sw(172),
                      child: SizedBox(
                        width: sw(139),
                        height: sh(34),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FColors.secondaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(sw(30)),
                            ),
                          ),
                          onPressed: () => c.pickSelfie(),
                          child: Text(
                            "Take Photo",
                            style: FTextTheme.darkTextTheme.labelSmall
                                ?.copyWith(fontSize: sw(14)),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: sh(876),
                      left: sw(42),
                      child: SizedBox(
                        width: sw(358),
                        height: sh(48),
                        child: ElevatedButton(
                          onPressed:
                          c.isLoading.value ? null : c.submitSelfie,
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
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        );
      }),
    );
  }
}
