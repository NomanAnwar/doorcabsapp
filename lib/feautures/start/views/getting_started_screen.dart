import 'package:country_picker/country_picker.dart';
import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
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
  Country selectedCountry = Country(
    phoneCode: '92',
    countryCode: 'PK',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Pakistan',
    example: '3012345678',
    displayName: 'Pakistan',
    displayNameNoCountryCode: 'Pakistan',
    e164Key: '',
  );

  void _handleVerification(String method) {
    setState(() {
      phoneError = FValidator.validatePhoneNumber(
        phoneController.text.trim(),
        countryCode: selectedCountry.countryCode,
      );
    });

    if (!controller.acceptedPolicy.value) {
      FSnackbar.show(
        title: "Error",
        message: "You must accept the Privacy Policy.",
        isError: true,
      );
      return;
    }

    if (phoneError != null) {
      FSnackbar.show(
        title: "Error",
        message: "Enter Valid phone number.",
        isError: false,
      );
      return;
    }

    // controller.phoneNumber.value =
    // "+${selectedCountry.phoneCode}${phoneController.text.trim()}";

    String rawInput = phoneController.text.trim();

    rawInput = rawInput.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    rawInput = rawInput.replaceFirst(RegExp(r'^\+'), '');

    if (rawInput.startsWith('0')) {
      rawInput = rawInput.substring(1);
    }

    controller.phoneNumber.value = "+${selectedCountry.phoneCode}$rawInput";

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

        return Stack(
          children: [
            SingleChildScrollView(
              child: SizedBox(
                height: screenHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned(
                      top: sh(54),
                      left: sw(13),
                      right: sw(13),
                      child: Container(
                        width: sw(414),
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

                    Positioned(
                      top: sh(114),
                      left: sw(63),
                      child: Image.asset(
                        FImages.logo,
                        width: sw(99),
                        height: sh(62),
                      ),
                    ),

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

                    Positioned(
                      top: sh(220),
                      left: sw(63),
                      child: Text(
                        FTextStrings.wellcomeSubheading,
                        style: FTextTheme.lightTextTheme.headlineSmall!
                            .copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: FTextTheme
                                .lightTextTheme.titleLarge!.fontSize! *
                                screenWidth /
                                baseWidth),
                      ),
                    ),

                    Positioned(
                      top: sh(252),
                      left: sw(14),
                      right: sw(14),
                      child: Image.asset(
                        FImages.started_bg_down,
                        fit: BoxFit.fitWidth,
                        width: sw(413),
                        height: sh(167),
                      ),
                    ),

                    /// 📱 Country Picker + Phone Input
                    Positioned(
                      top: sh(440),
                      left: sw(42),
                      child: Container(
                        width: sw(356),
                        height: sh(58),
                        padding: EdgeInsets.symmetric(horizontal: sw(12)),
                        decoration: BoxDecoration(
                          color: FColors.phoneInputField,
                          borderRadius: BorderRadius.circular(sw(14)),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showCountryPicker(
                                  context: context,
                                  showPhoneCode: true,
                                  onSelect: (Country country) {
                                    setState(() => selectedCountry = country);
                                  },
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    selectedCountry.flagEmoji, // 🇵🇰 etc.
                                    style: TextStyle(fontSize: sh(26)),
                                  ),
                                  // SizedBox(width: sw(6)),
                                  // Text(
                                  //   "+${selectedCountry.phoneCode}",
                                  //   style: TextStyle(
                                  //       fontSize: sh(16),
                                  //       fontWeight: FontWeight.w500),
                                  // ),
                                  Icon(Icons.arrow_drop_down_rounded,
                                      size: sh(40), color: FColors.black),
                                ],
                              ),
                            ),
                            // const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: FTextTheme.lightTextTheme.titleLarge!
                                    .copyWith(
                                    fontSize: FTextTheme.lightTextTheme
                                        .titleLarge!.fontSize! *
                                        screenWidth /
                                        baseWidth),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Phone Number",
                                  hintStyle:
                                  FTextTheme.lightTextTheme.titleLarge!
                                      .copyWith(
                                      fontSize: FTextTheme
                                          .lightTextTheme
                                          .titleLarge!
                                          .fontSize! *
                                          screenWidth /
                                          baseWidth),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (phoneError != null)
                      Positioned(
                        top: sh(505),
                        left: sw(54),
                        child: Text(
                          phoneError!,
                          style: TextStyle(color: Colors.red, fontSize: sh(12)),
                        ),
                      ),

                    Positioned(
                      top: sh(515),
                      left: sw(54),
                      child: Row(
                        children: [
                          Obx(
                                () => Checkbox(
                              value: controller.acceptedPolicy.value,
                              activeColor: FColors.secondaryColor,
                              onChanged: loading
                                  ? null
                                  : (val) => controller.acceptedPolicy.value =
                                  val ?? false,
                            ),
                          ),
                          Text(
                            "Privacy Policy",
                            style:
                            FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                              fontSize: FTextTheme
                                  .lightTextTheme.bodyLarge!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      top: sh(560),
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

                    Positioned(
                      top: sh(600),
                      left: sw(14),
                      right: sw(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: sh(41),
                            width: sw(165),
                            child: ElevatedButton.icon(
                              onPressed: loading
                                  ? null
                                  : () => _handleVerification("sms"),
                              icon: Image.asset("assets/icons/message.png",
                                  width: sw(24), height: sh(24)),
                              label: Text("Text",
                                  style: FTextTheme.darkTextTheme.bodyLarge!
                                      .copyWith(
                                      fontSize: FTextTheme.darkTextTheme
                                          .bodyLarge!.fontSize! *
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
                                      fontSize: FTextTheme.darkTextTheme
                                          .bodyLarge!.fontSize! *
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

                    // Positioned(
                    //   top: sh(650),
                    //   left: 0,
                    //   right: 0,
                    //   child: Center(
                    //     child: Row(
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: [
                    //         Text(
                    //           "Already Have an account ",
                    //           style: FTextTheme.lightTextTheme.bodyLarge!
                    //               .copyWith(
                    //               fontSize: FTextTheme.lightTextTheme
                    //                   .bodyLarge!.fontSize! *
                    //                   screenWidth /
                    //                   baseWidth),
                    //         ),
                    //         GestureDetector(
                    //           onTap: () => Get.toNamed('/login'),
                    //           child: Text(
                    //             "Log-In",
                    //             style: FTextTheme.lightTextTheme.titleSmall!
                    //                 .copyWith(
                    //                 color: FColors.secondaryColor,
                    //                 fontSize: FTextTheme
                    //                     .lightTextTheme.titleSmall!
                    //                     .fontSize! *
                    //                     screenWidth /
                    //                     baseWidth),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),

            if (loading)
              Container(
                height: screenHeight,
                width: screenWidth,
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
