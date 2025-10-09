import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/otp_controller.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OtpController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base reference (iPhone 16 Pro Max)
    final baseWidth = 440.0;
    final baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
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
                    /// Logo
                    Positioned(
                      top: sh(100),
                      left: sw(164),
                      child: Image.asset(
                        FImages.logo,
                        width: sw(99),
                        height: sh(62),
                      ),
                    ),

                    /// First Text
                    Positioned(
                      top: sh(198),
                      left: sw(83),
                      child: Text(
                        FTextStrings.otpTagLine.toUpperCase(),
                        style: FTextTheme.lightTextTheme.displayLarge?.copyWith(
                          // fontWeight: FontWeight.bold,
                          color: FColors.secondaryColor,
                          fontSize:
                          FTextTheme.lightTextTheme.displayLarge!.fontSize! *
                              screenWidth /
                              baseWidth,
                        ),
                      ),
                    ),

                    /// Second Text
                    Positioned(
                      top: sh(245),
                      left: sw(89),
                      child: Text(
                        FTextStrings.otpSubheading,
                        style: FTextTheme.lightTextTheme.titleLarge!.copyWith(
                          fontSize: FTextTheme
                              .lightTextTheme.titleLarge!.fontSize! *
                              screenWidth /
                              baseWidth,
                        ),
                      ),
                    ),

                    /// OTP input fields
                    Positioned(
                      top: sh(350),
                      left: sw(66),
                      child: SizedBox(
                        width: sw(308),
                        child: Pinput(
                          length: 4,
                          defaultPinTheme: PinTheme(
                            width: sw(56),
                            height: sh(57),
                            textStyle: FTextTheme.lightTextTheme.displaySmall!
                                .copyWith(
                              fontSize: FTextTheme
                                  .lightTextTheme.displaySmall!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: FColors.buttonDisabled,
                                  width: sh(5),
                                ),
                              ),
                            ),
                          ),
                          focusedPinTheme: PinTheme(
                            width: sw(56),
                            height: sh(57),
                            textStyle: FTextTheme.lightTextTheme.displaySmall!
                                .copyWith(
                              fontSize: FTextTheme
                                  .lightTextTheme.displaySmall!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: FColors.secondaryColor,
                                  width: sh(5),
                                ),
                              ),
                            ),
                          ),
                          onCompleted: controller.verifyOtp,
                        ),
                      ),
                    ),

                    /// Timer / Resend
                    Positioned(
                      top: sh(440),
                      left: (screenWidth / 2) - sw(70),
                      child: Obx(
                            () => controller.secondsRemaining.value > 0
                            ? Text(
                          "Resend OTP in ${controller.secondsRemaining.value}s",
                          style: FTextTheme.lightTextTheme.titleMedium!
                              .copyWith(
                            fontSize: FTextTheme.lightTextTheme
                                .titleMedium!.fontSize! *
                                screenWidth /
                                baseWidth,
                          ),
                        )
                            : TextButton(
                          onPressed: controller.resendOtp,
                          child: Text(
                            "Resend OTP",
                            style: FTextTheme.lightTextTheme.titleSmall!
                                .copyWith(
                              fontSize: FTextTheme.lightTextTheme
                                  .titleSmall!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Get OTP Button
                    Positioned(
                      top: sh(470),
                      left: (screenWidth / 2) - sw(70),
                      child: TextButton(
                        onPressed: controller.getOtp,
                        child: Text(
                          "Get OTP",
                          style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                            fontSize: FTextTheme
                                .lightTextTheme.titleSmall!.fontSize! *
                                screenWidth /
                                baseWidth,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Loader Overlay
            if (loading)
              Container(
                height: screenHeight,
                width: screenWidth,
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
