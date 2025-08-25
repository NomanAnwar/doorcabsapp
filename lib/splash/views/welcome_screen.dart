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
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(color: FColors.primaryColor),
        child: Stack(
          children: [
            /// Logo
            Positioned(
              top: 160,
              left: 128,
              child: Image.asset(
                FImages.logo,
                width: 183,
                height: 114,
              ),
            ),

            /// Language Dropdown
            Positioned(
              top: 329,
              left: 121,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const CircularProgressIndicator(color: Colors.white);
                }

                if (controller.languages.isEmpty) {
                  return const Text(
                    "No languages found",
                    style: TextStyle(color: Colors.white),
                  );
                }

                return SizedBox(
                  width: 197,
                  child: FDropdown(
                    value: controller.selectedLanguage.value?.language,
                    items: controller.languages
                        .map((lang) => {
                      "lang": lang.language,
                      "flag": lang.flag,
                    })
                        .toList(),
                    width: 197,
                    backgroundColor: Colors.grey.shade200,
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
              top: 445,
              left: 128,
              child: FElevatedButton(
                text: FTextStrings.driver.toUpperCase(),
                width: 185,
                onPressed: () {
                  controller.selectRole(FTextStrings.driver);
                  controller.saveAndContinue();
                },
              ),
            ),

            /// Passenger Button
            Positioned(
              top: 535,
              left: 128,
              child: FElevatedButton(
                text: FTextStrings.passenger.toUpperCase(),
                width: 185,
                onPressed: () {
                  controller.selectRole(FTextStrings.passenger);
                  controller.saveAndContinue();
                },
              ),
            ),

            /// Bottom BG Image
            Positioned(
              top: 630,
              left: 0,
              right: 0,
              child: Image.asset(
                FImages.splash_bg_down,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fitWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
