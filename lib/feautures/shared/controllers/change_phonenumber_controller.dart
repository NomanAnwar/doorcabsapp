import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePhoneNumberController extends GetxController {
  final currentPhoneController = TextEditingController(text: "03001234567");
  final newPhoneController = TextEditingController();

  void savePhoneNumber() {
    final newPhone = newPhoneController.text.trim();

    // Hide keyboard safely
    if (Get.context != null) {
      FocusScope.of(Get.context!).unfocus();
    }

    if (newPhone.isEmpty) {
      _showSnackbar("Error", "Please enter a new phone number.", Colors.redAccent);
    } else if (!RegExp(r'^[0-9]{11}$').hasMatch(newPhone)) {
      _showSnackbar("Invalid Number", "Phone number must be exactly 11 digits and only numbers allowed.", Colors.redAccent);
    } else {
      _showSnackbar("Success", "Phone number updated to $newPhone", Colors.green);
      newPhoneController.clear();
    }
  }

  void _showSnackbar(String title, String message, Color color) {
    // Debug print to confirm execution
    debugPrint("Snackbar triggered: $title -> $message");

    Get.closeAllSnackbars();

    // Use Get.overlayContext fallback if Get.context is null
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
    } else {
      // Emergency fallback if no context is available
      debugPrint("⚠️ Snackbar failed — no context available!");
    }
  }

  @override
  void onClose() {
    currentPhoneController.dispose();
    newPhoneController.dispose();
    super.onClose();
  }
}
