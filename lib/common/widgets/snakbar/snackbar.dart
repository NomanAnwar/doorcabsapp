import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/theme/custom_theme/text_theme.dart';

class FSnackbar {
  static void show({
    required String title,
    required String message,
    bool isError = false,
  }) {
    Get.snackbar(
      "", "",
      titleText: Text(
        title,
        style: FTextTheme.lightTextTheme.titleLarge!.copyWith(
          color: FColors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      messageText: Text(
        message,
        style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
          color: isError ? FColors.white : FColors.secondaryColor,
        ),
      ),
      backgroundColor: isError
          ? FColors.error
          : FColors.primaryColor,
      snackPosition: SnackPosition.TOP,
      borderRadius: 16,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
        size: 28,
      ),
      shouldIconPulse: false,
      duration: const Duration(seconds: 3),
      overlayBlur: 0.5,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }
}
