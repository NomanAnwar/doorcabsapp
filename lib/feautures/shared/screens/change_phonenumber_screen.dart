import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import '../controllers/change_phonenumber_controller.dart';

class ChangePhoneNumberScreen extends StatelessWidget {
  const ChangePhoneNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChangePhoneNumberController controller = Get.put(ChangePhoneNumberController());
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

        return Stack(
          children: [
            /// Main UI
            SafeArea(
              child: Stack(
                children: [
                  // 🔙 Back Arrow
                  Positioned(
                    top: sh(20),
                    left: sw(20),
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: SvgPicture.asset(
                        "assets/images/Arrow.svg",
                        width: sw(24),
                        height: sh(24),
                      ),
                    ),
                  ),

                  // 📱 Content
                  Positioned(
                    top: sh(70),
                    left: sw(20),
                    right: sw(20),
                    bottom: sh(120),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "Change Phone Number",
                              style: FTextTheme.lightTextTheme.headlineLarge?.copyWith(
                                fontSize: sw(18),
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(height: sh(50)),

                          Text(
                            "Current Phone Number",
                            style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
                              fontSize: sw(14),
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: sh(8)),

                          TextField(
                            controller: controller.currentPhoneController,
                            readOnly: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF2F2F2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(sw(8)),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: sw(12),
                                vertical: sh(14),
                              ),
                            ),
                            style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                              fontSize: sw(16),
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: sh(30)),

                          Text(
                            "New Phone Number",
                            style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
                              fontSize: sw(14),
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: sh(8)),

                          // TextField(
                          //   controller: controller.newPhoneController,
                          //   keyboardType: TextInputType.phone,
                          //   decoration: InputDecoration(
                          //     hintText: "Enter new phone number",
                          //     hintStyle: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                          //       fontSize: sw(16),
                          //       color: Colors.black45,
                          //     ),
                          //     filled: true,
                          //     fillColor: const Color(0xFFF2F2F2),
                          //     border: OutlineInputBorder(
                          //       borderRadius: BorderRadius.circular(sw(8)),
                          //       borderSide: BorderSide.none,
                          //     ),
                          //     contentPadding: EdgeInsets.symmetric(
                          //       horizontal: sw(12),
                          //       vertical: sh(14),
                          //     ),
                          //   ),
                          //   style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                          //     fontSize: sw(16),
                          //     color: Colors.black,
                          //   ),
                          // ),

                          TextField(
                            controller: controller.newPhoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: controller.maxPhoneLength.value,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\+?[0-9]*$')),
                            ],
                            onChanged: controller.handlePhoneInput,
                            decoration: InputDecoration(
                              hintText: "Enter new phone number",
                              hintStyle: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                                fontSize: sw(16),
                                color: Colors.black45,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF2F2F2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(sw(8)),
                                borderSide: BorderSide.none,
                              ),
                              counterText: '',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: sw(12),
                                vertical: sh(14),
                              ),
                            ),
                            style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                              fontSize: sw(16),
                              color: Colors.black,
                            ),
                          ),

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
                        onPressed: controller.isLoading.value ? null : controller.savePhoneNumber,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(sw(8)),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isLoading.value
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
                            color: Colors.black,
                            fontSize: sw(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Loader Overlay
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