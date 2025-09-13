// ProfileCompletionScreen with responsiveness and SingleChildScrollView
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../shared/services/storage_service.dart';
import '../controllers/profile_completion_controller.dart';

class ProfileCompletionScreen extends StatelessWidget {
  const ProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileCompletionController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    Widget _stepTile({
      required String title,
      required String route,
      required String stepKey,
      required double top,
      required double left,
      required double width,
      required double height,
    }) {
      return Positioned(
        top: sh(top),
        left: sw(left),
        child: GestureDetector(
          onTap: () {
            Get.toNamed(route)?.then((completed) {
              if (completed == true) {
                controller.completeStep(stepKey);
                FSnackbar.show(
                  title: "Step Completed",
                  message: "$title completed successfully.",
                  isError: false,
                );
              }
            });
          },
          child: Container(
            width: sw(width),
            height: sh(height),
            padding: EdgeInsets.symmetric(horizontal: sw(20)),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(sw(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: sw(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  StorageService.getDriverStep(stepKey) ? Icons.radio_button_checked : Icons.arrow_forward_ios,
                  size: sw(18),
                  color: StorageService.getDriverStep(stepKey) ? FColors.textGreen : FColors.black,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Obx(
                () => Stack(
              children: [
                /// Back + Title
                Positioned(
                  top: sh(48),
                  left: sw(29),
                  right: sw(29),
                  child: SizedBox(
                    height: sh(60),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: sh(12),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back, size: sw(24)),
                            onPressed: () => Get.back(),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.only(top: sh(12.0)),
                            child: Text(
                              "Complete Your Profile",
                              style: TextStyle(
                                fontSize: sw(18),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Step tiles positioned like Vehicle screen
                _stepTile(
                  title: "Basic Info",
                  route: "/profile",
                  stepKey: "basic",
                  top: 123,
                  left: 20,
                  width: 402,
                  height: 58,
                ),
                _stepTile(
                  title: "CNIC",
                  route: "/upload-cnic",
                  stepKey: "cnic",
                  top: 189,
                  left: 20,
                  width: 402,
                  height: 58,
                ),
                _stepTile(
                  title: "Selfie With Driver Licence",
                  route: "/upload-selfie",
                  stepKey: "selfie",
                  top: 255,
                  left: 20,
                  width: 402,
                  height: 58,
                ),
                _stepTile(
                  title: "Driver Licence",
                  route: "/upload-license",
                  stepKey: "licence",
                  top: 321,
                  left: 20,
                  width: 402,
                  height: 58,
                ),
                _stepTile(
                  title: "Vehicle Info",
                  route: "/upload-vehicle-info",
                  stepKey: "vehicle",
                  top: 387,
                  left: 20,
                  width: 402,
                  height: 58,
                ),
                _stepTile(
                  title: "Referral Code",
                  route: "/referral",
                  stepKey: "referral",
                  top: 453,
                  left: 20,
                  width: 402,
                  height: 58,
                ),

                /// Privacy Policy
                Positioned(
                  top: sh(520),
                  left: sw(20),
                  right: sw(20),
                  child: Container(
                    height: sh(58),
                    padding: EdgeInsets.symmetric(horizontal: sw(12)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(sw(12)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: sw(24),
                          height: sh(24),
                          child: Checkbox(
                            value: controller.acceptedPolicy.value,
                            onChanged: (val) {
                              controller.acceptedPolicy.value = val ?? false;
                              StorageService.setDriverStep("policy", val ?? false);
                            },
                          ),
                        ),
                        SizedBox(width: sw(8)),
                        Text(
                          "Privacy Policy",
                          style: TextStyle(
                            fontSize: sw(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Done Button
                Positioned(
                  bottom: sh(40),
                  left: sw(20),
                  right: sw(20),
                  child: SizedBox(
                    height: sh(58),
                    child: ElevatedButton(
                      onPressed:
                      controller.allStepsCompleted
                          ? () {
                        StorageService.setDriverStep("policy", true);
                        StorageService.setProfileCompleted(true);

                        StorageService.printDriverSteps();

                        FSnackbar.show(
                          title: "All Done",
                          message: "Profile completed successfully!",
                        );

                        // Get.offAllNamed('/home');
                        Get.offAllNamed('/ride-request-list');
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        controller.allStepsCompleted
                            ? FColors.secondaryColor
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(sw(14)),
                        ),
                      ),
                      child: Text(
                        "Done",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sw(18),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}