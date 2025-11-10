import 'package:flutter/material.dart';
import 'package:get/get.dart';

class inviteController extends GetxController {
  // 🎁 Dynamic title and description (shown in the screen)
  final RxString inviteTitle = "Invite a friend, you’ll both get 20% bonus".obs;
  final RxString inviteDescription =
      "Refer a friend to drive with us and you’ll both get a 20% bonus after they complete their first 10 trips.".obs;

  // 🎫 Referral code
  final RxString referralCode = "61DCN050".obs;

  // TextField controller
  final TextEditingController textController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    textController.text = referralCode.value; // prefill text field
  }

  // 🚀 Apply promo code or handle invite logic
  void applyPromo(String code) {
    if (code.isEmpty) {
      Get.snackbar(
        "Error",
        "Please enter a promo code before sending.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    // You can later integrate API or sharing logic here.
    Get.snackbar(
      "Success",
      "Promo code sent successfully!",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
