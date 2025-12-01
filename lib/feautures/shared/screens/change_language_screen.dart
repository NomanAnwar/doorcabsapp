import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';

import '../controllers/change_language_controller.dart';

class ChangeLanguageScreen extends StatelessWidget {
  const ChangeLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangeLanguageController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base reference (iPhone 16 Pro Max)
    final baseWidth = 440.0;
    final baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        final loading = controller.isLoading.value;
        final saving = controller.isSaving.value;

        return Stack(
          children: [
            /// Main UI - Keep your original UI structure
            SafeArea(
              child: Stack(
                children: [
                  // 🔙 Back Arrow
                  Positioned(
                    top: sh(39),
                    left: sw(33),
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: SvgPicture.asset(
                        "assets/images/Arrow.svg",
                        width: sw(24),
                        height: sh(24),
                      ),
                    ),
                  ),

                  // 🌐 Content
                  Positioned(
                    top: sh(62),
                    left: sw(25),
                    right: sw(20),
                    bottom: sh(120),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "Change Language",
                              style: FTextTheme.lightTextTheme.headlineLarge?.copyWith(
                                fontSize: sw(18),
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(height: sh(20)),

                          Text(
                            "Current Language",
                            style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
                              fontSize: sw(16),
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: sh(8)),

                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: sw(12),
                              vertical: sh(14),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(sw(8)),
                            ),
                            child: Obx(() => Text(
                              controller.currentLanguage.value,
                              style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                                fontSize: sw(16),
                                color: Colors.black,
                              ),
                            )),
                          ),
                          SizedBox(height: sh(30)),

                          Text(
                            "Select New Language",
                            style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
                              fontSize: sw(16),
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: sh(8)),

                          Obx(() => Container(
                            padding: EdgeInsets.symmetric(horizontal: sw(12)),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(sw(8)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.selectedLanguage.value.isEmpty
                                    ? null
                                    : controller.selectedLanguage.value,
                                hint: Text(
                                  "Choose language",
                                  style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                                    fontSize: sw(16),
                                  ),
                                ),
                                items: controller.availableLanguages
                                    .map(
                                      (lang) => DropdownMenuItem(
                                    value: lang,
                                    child: Text(
                                      lang,
                                      style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                                        fontSize: sw(16),
                                      ),
                                    ),
                                  ),
                                )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.selectedLanguage.value = value;
                                  }
                                },
                                isExpanded: true,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),

                  // 💾 Save Button
                  Positioned(
                    left: sw(41),
                    bottom: sh(28),
                    child: SizedBox(
                      width: sw(358),
                      height: sh(48),
                      child: ElevatedButton(
                        onPressed: controller.isSaving.value ? null : controller.saveLanguage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(sw(8)),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isSaving.value
                            ? SizedBox(
                          width: sh(20),
                          height: sh(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                            : Text(
                          "Save",
                          style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
                            fontSize: sw(16),
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Loader Overlay for initial loading
            if (loading)
              Container(
                height: screenHeight,
                width: screenWidth,
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: CircularProgressIndicator(
                    color: FColors.secondaryColor,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}