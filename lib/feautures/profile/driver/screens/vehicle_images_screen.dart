import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/vehicle_images_controller.dart';
import '../models/vehicle_verification_model.dart';

class VehicleImagesScreen extends StatelessWidget {
  const VehicleImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final controller = Get.put(VehicleImagesController());

    final controller = Get.put(VehicleImagesController());

    // Read the argument (if any)
    final int initialPage = Get.arguments?['startPage'] ?? 0;

    // Schedule the jump AFTER the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.pageController.hasClients) {
        controller.pageController.jumpToPage(initialPage);
      }
    });


    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(sh(140)),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Stack(
            children: [
              Positioned(
                top: sh(60),
                left: sw(21),
                child: IconButton(
                  icon: SvgPicture.asset(
                    "assets/images/Arrow.svg",
                    width: sw(28.01),
                    height: sh(28.01),
                  ),
                  onPressed: () => Get.back(),
                ),
              ),
              Positioned(
                top: sh(78),
                left: sw(29),
                right: sw(29),
                child: Text(
                  'Vehicle Verification',
                  textAlign: TextAlign.center,
                  style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
                    fontSize:
                    FTextTheme.lightTextTheme.titleLarge!.fontSize! *
                        screenWidth /
                        baseWidth,
                    fontWeight: FontWeight.w700,
                    color: FColors.black,
                  ),
                ),
              ),
              Positioned(
                top: sh(115),
                left: sw(29),
                right: sw(29),
                child: Text(
                  "Please provide detailed information about your vehicle.",
                  textAlign: TextAlign.center,
                  style: FTextTheme.lightTextTheme.titleSmall?.copyWith(
                    fontSize:
                    FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                    fontWeight: FontWeight.w400,
                    color: FColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: PageView.builder(
        controller: controller.pageController,
        itemCount: controller.steps.length,
        itemBuilder: (context, index) {
          if (index == controller.steps.length - 1) {
            return _buildFinalReviewPage(controller, sw, sh);
          }
          final step = controller.steps[index];
          return _buildStepPage(step, index, controller, sw, sh);
        },
      ),
    );
  }

  Widget _buildStepPage(
      VehicleImagesStep step,
      int index,
      VehicleImagesController controller,
      double Function(double) sw,
      double Function(double) sh,
      ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: FTextTheme.lightTextTheme.titleMedium?.copyWith(
                  ),
                ),
                SizedBox(height: sh(50)),
                Center(
                  child: SizedBox(
                    width: step.width,
                    height: step.height,
                    child: Obx(() {
                      final capturedImage = controller.capturedImages[index];
                      if (capturedImage != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(sw(8)),
                          child: Image.file(
                            File(capturedImage),
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return Padding(
                        padding: EdgeInsets.all(sw(20)),
                        child: SvgPicture.asset(
                          step.imagePath,
                          width: sw(step.width),
                          height: sh(step.height),
                          fit: BoxFit.contain,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: sh(30), left: sw(2)),
          child: SizedBox(
            width: sw(126),
            height: sh(34),
            child: ElevatedButton(
              onPressed: () => _openCamera(index, controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: FColors.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(sw(14)),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'Take Photo',
                textAlign: TextAlign.center,
                style: FTextTheme.darkTextTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontSize: sw(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalReviewPage(
      VehicleImagesController controller,
      double Function(double) sw,
      double Function(double) sh,
      ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(sw(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: sh(1)),
                Center(
                  child: Text(
                    'Vehicle Photos',
                    style: FTextTheme.lightTextTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: FColors.black,
                    ),
                  ),
                ),
                SizedBox(height: sh(15)),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: sw(16),
                    mainAxisSpacing: sh(16),
                    childAspectRatio: 1.2,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return Obx(() {
                      final imagePath = controller.capturedImages[index];
                      return GestureDetector(
                        onTap: () {
                          controller.jumpToStep(index);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: FColors.phoneInputField,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            child: imagePath != null
                                ? Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                                : Container(
                              color: Colors.grey.shade100,
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: sw(40),
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),

              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(sw(20)),
          child: Obx(() {
            final allPhotosUploaded = controller.capturedImages
                .take(6)
                .every((image) => image != null);

            return SizedBox(
              width: double.infinity,
              height: sh(48),
              child: ElevatedButton(
                onPressed: allPhotosUploaded && !controller.isLoading.value
                    ? controller.submitVerification
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FColors.secondaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(sw(12)),
                  ),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  allPhotosUploaded
                      ? 'Submit'
                      : 'Complete All Photos',
                  style: FTextTheme.darkTextTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _openCamera(
      int index, VehicleImagesController controller) async {
    final ImagePicker picker = ImagePicker();

    // Show bottom sheet with two options
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: const Text('Take Photo'),
                onTap: () async {
                  Get.back(); // close the bottom sheet
                  await _pickImage(index, controller, picker, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Get.back(); // close the bottom sheet
                  await _pickImage(index, controller, picker, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.red),
                title: const Text('Cancel'),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper function to handle image picking logic
  Future<void> _pickImage(
      int index,
      VehicleImagesController controller,
      ImagePicker picker,
      ImageSource source,
      ) async {
    try {
      final XFile? photo = await picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        controller.capturedImages[index] = photo.path;

        // Move to next step automatically
        if (index < controller.steps.length - 2) {
          await Future.delayed(const Duration(milliseconds: 500));
          controller.nextPage();
        } else if (index == controller.steps.length - 2) {
          await Future.delayed(const Duration(milliseconds: 500));
          controller.nextPage();
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

}
