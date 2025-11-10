import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangeLanguageController extends GetxController {
  var currentLanguage = "English".obs;
  var selectedLanguage = "".obs;

  final availableLanguages = [
    "English",
    "Urdu",
    "Arabic",
    "French",
    "German",
    "Spanish",
    "Chinese",
  ];

  void saveLanguage() {
    final newLang = selectedLanguage.value;

    if (newLang.isEmpty) {
      _showSnackbar("Error", "Please select a language.", Colors.redAccent);
    } else {
      currentLanguage.value = newLang;
      _showSnackbar("Success", "Language changed to $newLang.", Colors.green);
    }
  }

  void _showSnackbar(String title, String message, Color color) {
    Get.closeAllSnackbars();
    final overlayContext = Get.overlayContext ?? Get.context;
    if (overlayContext != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: color,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 8,
        isDismissible: true,
      );
    }
  }
}
