import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/local_storage/storage_utility.dart';
import '../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/otp_controller.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OtpController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          width: double.infinity,
          child: Stack(
            children: [
              /// Logo
              Positioned(
                top: 100,
                left: 164, // center horizontally (99/2)
                child: Image.asset(
                  FImages.logo,
                  width: 99,
                  height: 62,
                ),
              ),

              /// First Text
              Positioned(
                top: 198,
                left: 83, // adjust to center
                child: Text(
                  FTextStrings.otpTagLine.toUpperCase(),
                  style: FTextTheme.lightTextTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),

              /// Second Text
              Positioned(
                top: 245,
                left: 89, // adjust to center
                child: Text(
                  FTextStrings.otpSubheading,
                  style: FTextTheme.lightTextTheme.titleLarge,
                ),
              ),

              /// OTP input fields
              Positioned(
                top: 350,
                left: 66, // adjust to center
                child: SizedBox(
                  width: 308,

                  child: Pinput(
                    length: 4,
                    defaultPinTheme: PinTheme(
                      width: 56,
                      height: 57,
                      textStyle: FTextTheme.lightTextTheme.displaySmall,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: FColors.buttonDisabled, width: 5),
                        ),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 56,
                      height: 57,
                      textStyle: FTextTheme.lightTextTheme.displaySmall,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: FColors.secondaryColor, width: 5),
                        ),
                      ),
                    ),
                    onCompleted: controller.verifyOtp,
                  ),
                ),
              ),

              /// Timer / Resend
              Positioned(
                top: 440,
                left: (size.width / 2) - 70, // center align
                child: Obx(
                      () => controller.secondsRemaining.value > 0
                      ? Text(
                    "Resend OTP in ${controller.secondsRemaining.value}s",
                    style: FTextTheme.lightTextTheme.titleMedium,
                  )
                      : TextButton(
                    onPressed: controller.resendOtp,
                    child: Text(
                      "Resend OTP",
                      style: FTextTheme.lightTextTheme.titleSmall,
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
