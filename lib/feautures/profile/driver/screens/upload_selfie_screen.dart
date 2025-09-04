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
                "Selfie with ID",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Positioned(
            top: 101,
            left: 25,
            child: SizedBox(
              width: 390,
              child: Text(
                "Take a selfie holding your ID document (CNIC, driving license, etc.) clearly visible. Ensure your face and the document details are in focus",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          Obx(() {
            final f = c.selfieFile.value;
            return Positioned(
              top: 203,
              left: 41,
              child: GestureDetector(
                onTap: () => c.pickSelfie(),
                child: Container(
                  width: 358,
                  height: 537,
                  decoration:
                      f == null
                          ? BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                          )
                          : null,
                  child:
                      f == null
                          ? Image.asset(FImages.selfie_placeholder)
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(f.path),
                              width: 358,
                              height: 537,
                              fit: BoxFit.cover,
                            ),
                          ),
                ),
              ),
            );
          }),
          Positioned(
            top: 767,
            left: 172,
            child: SizedBox(
              width: 120,
              height: 34,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FColors.secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => c.pickSelfie(),
                child: Text("Take Photo", style: FTextTheme.darkTextTheme.labelSmall,),
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
                  onPressed: c.isLoading.value ? null : c.submitSelfie,
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
