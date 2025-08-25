import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/constants/image_strings.dart';
import 'package:doorcab/utils/constants/sizes.dart';
import 'package:doorcab/utils/constants/text_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashController());

    return Scaffold(
      backgroundColor: FColors.primaryColor,
      body: Stack(
        children: [
          /// logo
          Positioned(
            top: 231,
            left: 98,
            child: Image.asset(
              FImages.logo,
            ),
          ),

          /// Tag Line
          Positioned(
            top: 396,
            left: 76,
            child: Text(
              FTextStrings.splahTagLine,
              style: FTextTheme.lightTextTheme.bodyMedium,
            ),
          ),

          /// Bottom background image
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              FImages.splash_bg_down,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}
