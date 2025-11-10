import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/promo_model.dart';

class PromoGiftController extends GetxController {
  final RxList<PromoModel> promoList = <PromoModel>[
    PromoModel(
      title: "20% off your next ride",
      description: "Use code RIDE20 at checkout",
      code: "RIDE20",
      image: "assets/drawer/test.png",
      expiry: "Expires in 7 days",
    ),
    PromoModel(
      title: "Free ride up to \$10",
      description: "Use code FREERIDE at checkout",
      code: "FREERIDE",
      image: "assets/drawer/test2.png",
      expiry: "Valid until June 30",
    ),
    PromoModel(
      title: "\$5 off your next 3 rides",
      description: "Use code 5OFF3 at checkout",
      code: "5OFF3",
      image: "assets/drawer/test3.png",
      expiry: "Limited time offer",
    ),
  ].obs;

  // Referral + dynamic text
  final RxString referralCode = "61DCN050".obs;
  final RxString inviteTitle = "Invite a friend, get 50% off".obs;
  final RxString inviteDescription = "Share your invite code with a friend, and you'll both get 50% off your next ride when they complete their first trip.".obs;

  // Controller for text field input
  final TextEditingController textController = TextEditingController();

  void applyPromo(String code) {
    if (code.isEmpty) {
      Get.snackbar(
        "Error",
        "Please enter a promo code",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } else {
      debugPrint("Promo tapped: $code");
      Get.snackbar(
        "Success",
        "Promo code '$code' applied!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
