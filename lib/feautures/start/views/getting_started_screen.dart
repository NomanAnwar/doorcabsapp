import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:doorcab/utils/constants/sizes.dart';
import 'package:doorcab/utils/constants/text_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/theme/custom_theme/text_theme.dart';
import '../../../utils/validators/validator.dart';
import '../controllers/getting_started_controller.dart';

class GettingStartedScreen extends StatefulWidget {
  const GettingStartedScreen({super.key});

  @override
  State<GettingStartedScreen> createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen> {
  final phoneController = TextEditingController();
  final controller = Get.put(GettingStartedController());

  String? phoneError;

  void _handleVerification(String method) {
    setState(() {
      phoneError = FValidator.validatePhoneNumber(phoneController.text.trim());
    });

    if (!controller.acceptedPolicy.value) {
      // Get.snackbar("Error", "You must accept the Privacy Policy.",
      //     backgroundColor: Colors.red.shade100, colorText: Colors.black);
      FSnackbar.show(
        title: "Error",
        message: "You must accept the Privacy Policy.",
        isError: true,
      );

      return;
    }

    if (phoneError != null) {
      Get.snackbar("Invalid Phone", phoneError!,
          backgroundColor: Colors.red.shade100, colorText: Colors.black);
      return;
    }

    controller.phoneNumber.value = phoneController.text.trim();
    controller.signUp(method);
  }

  @override
  Widget build(BuildContext context) {
    final baseWidth = 440.0;
    final baseHeight = 956.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      body: Obx(() {
        final loading = controller.isLoading.value;

        return SingleChildScrollView(
          child: SizedBox(
            height: screenHeight,
            width: double.infinity,
            child: Stack(
              children: [
                /// Background container
                Positioned(
                  top: sh(54),
                  left: sw(13),
                  right: sw(13),
                  child: Container(
                    height: sh(365),
                    decoration: BoxDecoration(
                      color: FColors.primaryColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(sw(30)),
                        topLeft: Radius.circular(sw(30)),
                      ),
                    ),
                  ),
                ),

                /// Logo
                Positioned(
                  top: sh(114),
                  left: sw(63),
                  child: Image.asset(
                    FImages.logo,
                    width: sw(99),
                    height: sh(62),
                  ),
                ),

                /// First Text
                Positioned(
                  top: sh(181),
                  left: sw(63),
                  child: Text(
                    FTextStrings.wellcomeTagLine.toUpperCase(),
                    style: FTextTheme.lightTextTheme.displayMedium!
                        .copyWith(
                        color: FColors.secondaryColor,
                        fontSize: FTextTheme
                            .lightTextTheme.displayMedium!.fontSize! *
                            screenWidth /
                            baseWidth),
                  ),
                ),

                /// Second Text
                Positioned(
                  top: sh(220),
                  left: sw(63),
                  child: Text(
                    FTextStrings.wellcomeSubheading,
                    style: FTextTheme.lightTextTheme.titleLarge!.copyWith(
                        fontSize: FTextTheme
                            .lightTextTheme.titleLarge!.fontSize! *
                            screenWidth /
                            baseWidth),
                  ),
                ),

                /// City Background
                Positioned(
                  top: sh(252),
                  left: sw(14),
                  right: sw(14),
                  child: Image.asset(
                    FImages.started_bg_down,
                    fit: BoxFit.fitWidth,
                  ),
                ),

                /// Phone Input
                Positioned(
                  top: sh(440),
                  left: sw(42),
                  child: Container(
                    width: sw(356),
                    height: sh(52),
                    padding: EdgeInsets.symmetric(horizontal: sw(12)),
                    decoration: BoxDecoration(
                      color: FColors.phoneInputField,
                      borderRadius: BorderRadius.circular(sw(14)),
                    ),
                    child: Row(
                      children: [
                        Image.asset(FImages.urdu_flag,
                            width: sw(28), height: sh(18)),
                        Icon(Icons.arrow_drop_down_rounded,
                            size: sh(40), color: FColors.black),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            style: FTextTheme.lightTextTheme.titleLarge!
                                .copyWith(
                                fontSize: FTextTheme
                                    .lightTextTheme.titleLarge!.fontSize! *
                                    screenWidth /
                                    baseWidth),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Phone Number",
                              hintStyle: FTextTheme.lightTextTheme.titleLarge!
                                  .copyWith(
                                  fontSize: FTextTheme
                                      .lightTextTheme.titleLarge!.fontSize! *
                                      screenWidth /
                                      baseWidth),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Phone Error (if invalid)
                if (phoneError != null)
                  Positioned(
                    top: sh(495),
                    left: sw(54),
                    child: Text(
                      phoneError!,
                      style: TextStyle(color: Colors.red, fontSize: sh(12)),
                    ),
                  ),

                /// Privacy Policy Row
                Positioned(
                  top: sh(510),
                  left: sw(54),
                  child: Row(
                    children: [
                      Obx(
                            () => Checkbox(
                          value: controller.acceptedPolicy.value,
                          onChanged: loading
                              ? null
                              : (val) =>
                          controller.acceptedPolicy.value = val ?? false,
                        ),
                      ),
                      Text(
                        "Privacy Policy",
                        style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                            fontSize: FTextTheme
                                .lightTextTheme.bodyLarge!.fontSize! *
                                screenWidth /
                                baseWidth),
                      ),
                    ],
                  ),
                ),

                /// Verification text
                Positioned(
                  top: sh(555),
                  left: sw(119),
                  child: Center(
                    child: Text(
                      "get verification code via",
                      style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: FTextTheme
                              .lightTextTheme.bodyLarge!.fontSize! *
                              screenWidth /
                              baseWidth),
                    ),
                  ),
                ),

                /// Buttons Row
                Positioned(
                  top: sh(590),
                  left: sw(14),
                  right: sw(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: sh(41),
                        width: sw(165),
                        child: ElevatedButton.icon(
                          onPressed:
                          loading ? null : () => _handleVerification("sms"),
                          icon: Image.asset("assets/icons/message.png",
                              width: sw(24), height: sh(24)),
                          label: Text("Text",
                              style: FTextTheme.darkTextTheme.bodyLarge!
                                  .copyWith(
                                  fontSize: FTextTheme
                                      .darkTextTheme.bodyLarge!.fontSize! *
                                      screenWidth /
                                      baseWidth)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FColors.secondaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(sw(14)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: sw(12)),
                      SizedBox(
                        height: sh(41),
                        width: sw(175),
                        child: ElevatedButton.icon(
                          onPressed: loading
                              ? null
                              : () => _handleVerification("whatsapp"),
                          icon: Image.asset("assets/icons/whatsapp.png",
                              width: sw(24), height: sh(24)),
                          label: Text("WhatsApp",
                              style: FTextTheme.darkTextTheme.bodyLarge!
                                  .copyWith(
                                  fontSize: FTextTheme
                                      .darkTextTheme.bodyLarge!.fontSize! *
                                      screenWidth /
                                      baseWidth)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FColors.buttonWhatsApp,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(sw(14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Login Link
                Positioned(
                  top: sh(650),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Already Have an account ",
                          style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                              fontSize: FTextTheme
                                  .lightTextTheme.bodyLarge!.fontSize! *
                                  screenWidth /
                                  baseWidth),
                        ),
                        GestureDetector(
                          onTap: () => Get.toNamed('/login'),
                          child: Text(
                            "Log-In",
                            style: FTextTheme.lightTextTheme.titleSmall!
                                .copyWith(
                                color: FColors.secondaryColor,
                                fontSize: FTextTheme
                                    .lightTextTheme.titleSmall!.fontSize! *
                                    screenWidth /
                                    baseWidth),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
