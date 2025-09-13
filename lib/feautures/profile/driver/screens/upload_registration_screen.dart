// lib/features/profile_completion/screens/upload_registration_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../../utils/constants/colors.dart';
import '../controllers/upload_registration_controller.dart';

class UploadRegistrationScreen extends StatelessWidget {
  const UploadRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(UploadRegistrationController());

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
                top: sh(70),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "Registration Certificate",
                    style: TextStyle(
                      fontSize: sw(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: sh(105),
                left: sw(25),
                child: SizedBox(
                  width: sw(362),
                  child: Text(
                    "Please upload photos of your vehicle's registration certificate.",
                    style: TextStyle(fontSize: sw(14)),
                  ),
                ),
              ),
              Positioned(
                top: sh(161),
                left: sw(45),
                child: Text(
                  "Vehicle Production Year",
                  style: TextStyle(fontSize: sw(16)),
                ),
              ),
              Positioned(
                top: sh(188),
                left: sw(24),
                child: SizedBox(
                  width: sw(393),
                  height: sh(52),
                  child: TextField(
                    onChanged: (v) => c.productionYear.value = v,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFE3E3E3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(sw(14)),
                        borderSide: BorderSide.none,
                      ),
                      hintText: "e.g., 2020",
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: sw(12),
                        vertical: sh(14),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: sh(276),
                left: sw(135),
                child: Text(
                  "Upload Front Side",
                  style: TextStyle(fontSize: sw(16)),
                ),
              ),
              Obx(() {
                final f = c.frontFile.value;
                return Positioned(
                  top: sh(312),
                  left: sw(53),
                  child: GestureDetector(
                    onTap: () => c.pickFront(),
                    child: Container(
                      width: sw(331),
                      height: sh(196),
                      decoration: f == null
                          ? BoxDecoration(
                        borderRadius: BorderRadius.circular(sw(8)),
                        border: Border.all(color: Colors.grey),
                      )
                          : null,
                      child: f == null
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Upload File",
                            style: TextStyle(fontSize: sw(16)),
                          ),
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
                                backgroundColor: const Color(0xFFF2F2F2),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(sw(8)),
                                ),
                              ),
                              onPressed: () => c.pickFront(),
                              child: Text(
                                "Choose File",
                                style: TextStyle(fontSize: sw(14)),
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

              Positioned(
                top: sh(545),
                left: sw(112),
                child: Text(
                  "Upload Back Side",
                  style: TextStyle(fontSize: sw(16)),
                ),
              ),
              Obx(() {
                final b = c.backFile.value;
                return Positioned(
                  top: sh(581),
                  left: sw(53),
                  child: GestureDetector(
                    onTap: () => c.pickBack(),
                    child: Container(
                      width: sw(331),
                      height: sh(196),
                      decoration: b == null
                          ? BoxDecoration(
                        borderRadius: BorderRadius.circular(sw(8)),
                        border: Border.all(color: Colors.grey),
                      )
                          : null,
                      child: b == null
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Upload File",
                            style: TextStyle(fontSize: sw(16)),
                          ),
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
                                backgroundColor: const Color(0xFFF2F2F2),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(sw(8)),
                                ),
                              ),
                              onPressed: () => c.pickBack(),
                              child: Text(
                                "Choose File",
                                style: TextStyle(fontSize: sw(14)),
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

              Positioned(
                top: sh(876),
                left: sw(42),
                child: Obx(
                      () => SizedBox(
                    width: sw(358),
                    height: sh(48),
                    child: ElevatedButton(
                      onPressed: c.isLoading.value ? null : c.submitRegistration,
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