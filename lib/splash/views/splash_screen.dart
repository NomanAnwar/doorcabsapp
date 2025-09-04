import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/constants/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/constants/text_strings.dart';
import '../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashController());

    // Reference screen size (iPhone 16 Pro Max)
    final baseWidth = 440.0;
    final baseHeight = 956.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Scale helpers
    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: FColors.primaryColor,
      body: Stack(
        children: [
          /// Logo
          Positioned(
            top: sh(231),
            left: sw(98),
            child: Image.asset(
              FImages.logo,
              width: sw(244), // optional scaling if needed
            ),
          ),

          /// Tag Line
          Positioned(
            top: sh(396),
            left: sw(76),
            child: Text(
              FTextStrings.splahTagLine,
              style: FTextTheme.lightTextTheme.bodyMedium?.copyWith(
                fontSize: sw(16), // scale font size proportionally
              ),
            ),
          ),

          /// Bottom background image
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              FImages.splash_bg_down,
              width: screenWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}
