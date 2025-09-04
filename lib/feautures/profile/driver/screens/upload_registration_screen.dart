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
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Registration Certificate",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Positioned(
            top: 105,
            left: 25,
            child: SizedBox(
              width: 362,
              child: Text(
                "Please upload photos of your vehicle's registration certificate.",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          const Positioned(
            top: 161,
            left: 45,
            child: Text("Vehicle Production Year"),
          ),
          Positioned(
            top: 188,
            left: 24,
            child: SizedBox(
              width: 393,
              height: 52,
              child: TextField(
                onChanged: (v) => c.productionYear.value = v,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE3E3E3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "e.g., 2020",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          const Positioned(
            top: 276,
            left: 135,
            child: Text("Upload Front Side"),
          ),
          Obx(() {
            final f = c.frontFile.value;
            return Positioned(
              top: 312,
              left: 53,
              child: GestureDetector(
                onTap: () => c.pickFront(),
                child: Container(
                  width: 331,
                  height: 196,
                  decoration:
                      f == null
                          ? BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          )
                          : null,
                  child:
                      f == null
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Upload File"),
                              Text("Take a photo or choose from gallery"),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 130,
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF2F2F2),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => c.pickFront(),
                                  child: const Text("Choose File"),
                                ),
                              ),
                            ],
                          )
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(f.path),
                              width: 331,
                              height: 196,
                              fit: BoxFit.cover,
                            ),
                          ),
                ),
              ),
            );
          }),

          const Positioned(
            top: 545,
            left: 112,
            child: Text("Upload Back Side"),
          ),
          Obx(() {
            final b = c.backFile.value;
            return Positioned(
              top: 581,
              left: 53,
              child: GestureDetector(
                onTap: () => c.pickBack(),
                child: Container(
                  width: 331,
                  height: 196,
                  decoration:
                      b == null
                          ? BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          )
                          : null,
                  child:
                      b == null
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Upload File"),
                              Text("Take a photo or choose from gallery"),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 130,
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF2F2F2),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => c.pickBack(),
                                  child: const Text("Choose File"),
                                ),
                              ),
                            ],
                          )
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(b.path),
                              width: 331,
                              height: 196,
                              fit: BoxFit.cover,
                            ),
                          ),
                ),
              ),
            );
          }),

          Positioned(
            top: 876,
            left: 42,
            child: Obx(
              () => SizedBox(
                width: 358,
                height: 48,
                child: ElevatedButton(
                  onPressed: c.isLoading.value ? null : c.submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FColors.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      c.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "Submit",
                            style: TextStyle(color: Colors.white),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
