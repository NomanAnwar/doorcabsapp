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

    Widget _stepTile({
      required String title,
      required String route,
      required String stepKey,
      required double top,
      required double left,
      required double width,
      required double height,
    }) {
      return PositionedScaled(
        top: top,
        left: left,
        width: width,
        height: height,
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  StorageService.getDriverStep(stepKey) ? Icons.radio_button_checked : Icons.arrow_forward_ios,
                  size: 18,
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
      body: Obx(
        () => Stack(
          children: [
            /// Back + Title
            PositionedScaled(
              top: 48,
              left: 29,
              right: 29,
              child: SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 12,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Get.back(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: const Text(
                          "Complete Your Profile",
                          style: TextStyle(
                            fontSize: 18,
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
            PositionedScaled(
              top: 520,
              left: 20,
              right: 20,
              height: 58,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: controller.acceptedPolicy.value,
                      onChanged: (val) {
                        controller.acceptedPolicy.value = val ?? false;
                        StorageService.setDriverStep("policy", val ?? false);
                      },
                    ),
                    const Text(
                      "Privacy Policy",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Done Button
            PositionedScaled(
              bottom: 40,
              left: 20,
              right: 20,
              height: 58,
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
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      controller.allStepsCompleted
                          ? FColors.secondaryColor
                          : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
