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
      title, // Use title directly as first parameter
      message, // Use message directly as second parameter
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError ? FColors.textError : FColors.secondaryColor,
      colorText: Colors.white,
      // This sets text color for both title and message
      margin: const EdgeInsets.all(10),
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
        size: 28,
      ),
      shouldIconPulse: false,
      overlayBlur: 0.5,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }
}
