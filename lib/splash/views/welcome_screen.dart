import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/constants/text_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/widgets/buttons/elevated_button.dart';
import '../../common/widgets/dropdowns/dropdown_button.dart';
import '../../utils/constants/image_strings.dart';
import '../controllers/welcome_controller.dart';

class WelcomeScreen extends StatelessWidget {
  final WelcomeController controller = Get.put(WelcomeController());

  @override
  Widget build(BuildContext context) {
    // Reference screen size (iPhone 16 Pro Max)
    final baseWidth = 440.0;
    final baseHeight = 956.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Scale helpers
    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      body: Container(
        width: screenWidth,
        decoration: const BoxDecoration(color: FColors.primaryColor),
        child: SingleChildScrollView(
          child: SizedBox(
            height: screenHeight, // Ensure the scroll view takes full height
            child: Stack(
              children: [
                /// Logo
                Positioned(
                  top: sh(160),
                  left: sw(128),
                  child: Image.asset(
                    FImages.logo,
                    width: sw(183),
                    height: sh(114),
                  ),
                ),

                /// Language Dropdown
                Positioned(
                  top: sh(329),
                  left: sw(121),
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 70),
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (controller.languages.isEmpty) {
                      return const Text(
                        "No languages found",
                        style: TextStyle(color: Colors.white),
                      );
                    }

                    return SizedBox(
                      width: sw(197),
                      child: FDropdown(
                        value: controller.selectedLanguage.value?.language,
                        items: controller.languages
                            .map((lang) => {
                          "lang": lang.language,
                          "flag": lang.flag,
                        })
                            .toList(),
                        width: sw(197),
                        backgroundColor: FColors.white,
                        onChanged: (val) {
                          final selected = controller.languages
                              .firstWhere((l) => l.language == val);
                          controller.selectLanguage(selected);
                        },
                      ),
                    );
                  }),
                ),

                /// Driver Button
                Positioned(
                  top: sh(445),
                  left: sw(150),
                  child: FElevatedButton(
                    text: FTextStrings.driver.toUpperCase(),
                    width: sw(140),
                    onPressed: () {
                      controller.selectRole(FTextStrings.driver);
                      controller.saveAndContinue();
                    },
                  ),
                ),

                /// Passenger Button
                Positioned(
                  top: sh(535),
                  left: sw(128),
                  child: FElevatedButton(
                    text: FTextStrings.passenger.toUpperCase(),
                    width: sw(185),
                    onPressed: () {
                      controller.selectRole(FTextStrings.passenger);
                      controller.saveAndContinue();
                    },
                  ),
                ),

                /// Bottom BG Image
                Positioned(
                  top: sh(630),
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    FImages.splash_bg_down,
                    width: screenWidth,
                    fit: BoxFit.fitWidth,
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