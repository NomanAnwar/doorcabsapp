import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../shared/services/storage_service.dart';
import '../../../start/models/driver_verification_helper.dart';
import '../controllers/profile_completion_controller.dart';

class ProfileCompletionScreen extends StatelessWidget {
  const ProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final vehicleType = args['vehicle'] ?? 'car';
    final controller = Get.put(ProfileCompletionController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    Widget _getStatusIcon(String status) {
      switch (status) {
        case 'approved':
        case 'verified':
          return Icon(Icons.check_circle, color: Colors.green, size: sw(18));
        case 'rejected': // ✅ ADDED: Rejected case
          return Icon(Icons.cancel, color: Colors.red, size: sw(18));
        case 'pending':
          return Icon(Icons.pending, color: FColors.primaryColor, size: sw(18));
        default:
          return Icon(Icons.arrow_forward_ios, color: FColors.black, size: sw(18));
      }
    }

    String _getStatusText(String status) {
      switch (status) {
        case 'approved':
          return 'Approved';
        case 'verified':
          return 'Verified';
        case 'rejected': // ✅ ADDED: Rejected case
          return 'Rejected';
        case 'pending':
          return 'Pending';
        default:
          return '';
      }
    }

    Color _getStatusColor(String status) {
      switch (status) {
        case 'approved':
        case 'verified':
          return FColors.black;
        case 'rejected': // ✅ ADDED: Rejected case
          return Colors.red;
        case 'pending':
          return FColors.primaryColor;
        default:
          return FColors.black;
      }
    }

    Widget _stepTile({
      required String title,
      required String route,
      required String stepKey,
      String? verificationStatus,
    }) {
      final isCompleted = StorageService.getDriverStep(stepKey);
      final hasVerificationStatus = verificationStatus != null && verificationStatus != 'missing';
      final isRejected = verificationStatus == 'rejected';
      final isApproved = verificationStatus == 'approved' || verificationStatus == 'verified'; // ✅ ADDED

      return GestureDetector(
        onTap: () {
          if (isApproved) {
            // ✅ ADDED: Block navigation for approved items
            FSnackbar.show(
              title: "Already Approved",
              message: "Your $title is already approved and cannot be modified.",
              isError: false,
            );
            return;
          }

          if (isRejected) {
            // Show rejection message when tapped
            FSnackbar.show(
              title: "Document Rejected",
              message: "Your $title was rejected. Please re-upload clear documents.",
              isError: true,
            );
          }

          Get.toNamed(route)?.then((completed) {
            if (completed == true) {
              controller.completeStep(stepKey);
              FSnackbar.show(
                title: "Steps Completed",
                message: "$title completed successfully.",
                isError: false,
              );
            }
          });
        },
        child: Container(
          width: double.infinity,
          height: sh(58),
          padding: EdgeInsets.symmetric(horizontal: sw(20)),
          margin: EdgeInsets.only(bottom: sh(16)),
          decoration: BoxDecoration(
            color: FColors.radioField, // ✅ ADDED: Green background for approved
            borderRadius: BorderRadius.circular(sw(12)),
            border: isRejected
                ? Border.all(color: FColors.radioField, width: 1)
                : isApproved
                ? Border.all(color: FColors.radioField, width: 1) // ✅ ADDED: Green border for approved
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: sw(16),
                        fontWeight: FontWeight.w600,
                        color: FColors.black,
                      ),
                    ),
                    if (isRejected) // Show rejection message
                      Text(
                        "Tap to re-upload",
                        style: TextStyle(
                          fontSize: sw(10),
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (isApproved) // ✅ ADDED: Show approved message
                      Text(
                        "Approved - No action needed",
                        style: TextStyle(
                          fontSize: sw(10),
                          color: FColors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (hasVerificationStatus)
                    Padding(
                      padding: EdgeInsets.only(right: sw(8)),
                      child: Text(
                        _getStatusText(verificationStatus!),
                        style: TextStyle(
                          color: _getStatusColor(verificationStatus),
                          fontSize: sw(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  _getStatusIcon(hasVerificationStatus ? verificationStatus! : (isCompleted ? 'completed' : 'not_started')),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// App Bar
            Container(
              height: sh(60),
              padding: EdgeInsets.symmetric(horizontal: sw(20)),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, size: sw(24)),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Complete Your Profile",
                      style: TextStyle(
                        fontSize: sw(18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(sw(20)),
                child: Obx(() {
                  final profile = StorageService.observableProfile.value;
                  final verificationStatus = profile != null
                      ? DriverVerificationHelper.getVerificationStatus(profile)
                      : <String, String>{};

                  final hasRejectedDocs = verificationStatus.containsValue('rejected');

                  return Column(
                    children: [

                      if (hasRejectedDocs)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(sw(16)),
                          margin: EdgeInsets.only(bottom: sh(16)),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(sw(12)),
                            border: Border.all(color: Colors.red, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red, size: sw(20)),
                              SizedBox(width: sw(12)),
                              Expanded(
                                child: Text(
                                  "Some documents were rejected. Please re-upload clear photos.",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: sw(14),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      /// Step Tiles with integrated verification status
                      _stepTile(
                        title: "Basic Info",
                        route: "/profile",
                        stepKey: "basic",
                      ),
                      _stepTile(
                        title: "CNIC",
                        route: "/upload-cnic",
                        stepKey: "cnic",
                        verificationStatus: verificationStatus['cnic'],
                      ),
                      _stepTile(
                        title: "Selfie With Driver Licence",
                        route: "/upload-selfie",
                        stepKey: "selfie",
                        verificationStatus: verificationStatus['selfie'],
                      ),
                      _stepTile(
                        title: "Driver Licence",
                        route: "/upload-license",
                        stepKey: "licence",
                        verificationStatus: verificationStatus['license'],
                      ),
                      _stepTile(
                        title: "Vehicle Info",
                        route: "/upload-vehicle-info",
                        stepKey: "vehicle",
                        verificationStatus: verificationStatus['vehicle'],
                      ),
                      _stepTile(
                        title: "Referral Code",
                        route: "/referral",
                        stepKey: "referral",
                      ),

                      /// Privacy Policy
                      Obx(() => Container(
                        height: sh(58),
                        padding: EdgeInsets.symmetric(horizontal: sw(12)),
                        margin: EdgeInsets.only(bottom: sh(16)),
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
                                activeColor: FColors.secondaryColor,
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
                      )),
                    ],
                  );
                }),
              ),
            ),

            /// Done Button (fixed at bottom)
            Container(
              padding: EdgeInsets.all(sw(20)),
              child: Obx(() => SizedBox(
                width: double.infinity,
                height: sh(58),
                child: ElevatedButton(
                  onPressed: controller.allStepsCompleted
                      ? () {
                    StorageService.setDriverStep("policy", true);
                    StorageService.setProfileCompleted(true);
                    StorageService.printDriverSteps();

                    FSnackbar.show(
                      title: "All Done",
                      message: "Profile completed successfully!",
                    );

                    Get.offAllNamed('/go-online');
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.allStepsCompleted
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
              )),
            ),
          ],
        ),
      ),
    );
  }
}