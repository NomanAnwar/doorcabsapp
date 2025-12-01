import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import '../controllers/privacy_policy_controller.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final PrivacyPolicyController controller = Get.put(PrivacyPolicyController());

  PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base reference (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        final loading = controller.isLoading.value;

        return Stack(
          children: [
            /// Main UI
            SingleChildScrollView(
              child: SizedBox(
                height: screenHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    /// 🔙 Back Arrow
                    Positioned(
                      top: sh(50),
                      left: sw(20),
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: SvgPicture.asset(
                          "assets/images/Arrow.svg",
                          width: sw(28),
                          height: sw(28),
                        ),
                      ),
                    ),

                    /// 🧾 Title
                    Positioned(
                      top: sh(100),
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          "Privacy & Policy",
                          style: FTextTheme.lightTextTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: FTextTheme.lightTextTheme.titleLarge!.fontSize! *
                                screenWidth /
                                baseWidth,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    /// 📜 Content
                    Positioned(
                      top: sh(160),
                      left: sw(20),
                      right: sw(20),
                      bottom: 0,
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: FColors.secondaryColor,
                                ),
                                SizedBox(height: sh(16)),
                                Text(
                                  "Loading Privacy Policy...",
                                  style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                                    fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                                        screenWidth /
                                        baseWidth,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (controller.hasError.value) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: sw(48),
                                  color: Colors.grey,
                                ),
                                SizedBox(height: sh(16)),
                                Text(
                                  'Failed to load Privacy Policy',
                                  style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                                    fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                                        screenWidth /
                                        baseWidth,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: sh(16)),
                                ElevatedButton(
                                  onPressed: controller.fetchPrivacyPolicy,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FColors.secondaryColor,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: Text(
                                    'Retry',
                                    style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                                      fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                                          screenWidth /
                                          baseWidth,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final privacyPolicy = controller.privacyPolicy.value;

                        if (privacyPolicy == null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.privacy_tip_outlined,
                                  size: sw(48),
                                  color: Colors.grey,
                                ),
                                SizedBox(height: sh(16)),
                                Text(
                                  'No Privacy Policy available',
                                  style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                                    fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                                        screenWidth /
                                        baseWidth,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildPolicySection(
                                title: privacyPolicy.title, // Access the value
                                content: privacyPolicy.description, // Access the value
                                sw: sw,
                                sh: sh,
                                screenWidth: screenWidth,
                                baseWidth: baseWidth,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            /// Loader Overlay (same as OtpScreen)
            // if (loading)
            //   Container(
            //     height: screenHeight,
            //     width: screenWidth,
            //     color: Colors.black.withOpacity(0.4),
            //     child: const Center(
            //       child: CircularProgressIndicator(color: Colors.white),
            //     ),
            //   ),
          ],
        );
      }),
    );
  }

  Widget _divider({required double Function(double) sw}) => Divider(
    color: const Color(0xFFE0E0E0),
    height: 1,
    thickness: sw(1),
  );

  Widget _buildPolicySection({
    required String title,
    required String content,
    required double Function(double) sw,
    required double Function(double) sh,
    required double screenWidth,
    required double baseWidth,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: sh(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          // Text(
          //   title,
          //   style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
          //     fontWeight: FontWeight.w700,
          //     fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
          //         screenWidth /
          //         baseWidth,
          //     color: Colors.black,
          //   ),
          // ),
          // SizedBox(height: sh(8)),
          // Content
          Text(
            content,
            style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
              fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! *
                  screenWidth /
                  baseWidth,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}