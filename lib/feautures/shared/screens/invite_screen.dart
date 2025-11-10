import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/invite_controller.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(inviteController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;
    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Padding(
            padding: EdgeInsets.only(left: sw(16)),
            child: SvgPicture.asset(
              "assets/images/Arrow.svg",
              width: sw(20),
              height: sh(20),
            ),
          ),
        ),
        title: Padding(
          padding: EdgeInsets.only(top: sh(40)),
          child: Text(
            "Invite a friend",
            style: TextStyle(
              fontFamily: "Plus Jakarta Sans",
              fontWeight: FontWeight.w700,
              fontSize: sw(18),
              color: Colors.black,
            ),
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Stack(
          children: [
            // 🎁 Gift Box Icon
            Positioned(
              top: sh(150),
              left: 0,
              right: 0,
              child: Center(
                child: SvgPicture.asset(
                  "assets/images/gift_discount.svg",
                  width: sw(270),
                  height: sh(271),
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // 🏷️ Invite Title (Dynamic from Controller)
            Positioned(
              top: sh(480),
              left: 0,
              right: 10,
              child: Center(
                child: Obx(() => Text(
                  controller.inviteTitle.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Plus Jakarta Sans",
                    fontWeight: FontWeight.w700,
                    fontSize: sw(28),
                    color: Colors.black,
                  ),
                )),
              ),
            ),

            // 📄 Description (Dynamic from Controller)
            Positioned(
              top: sh(570),
              left: sw(30),
              right: sw(30),
              child: Obx(() => Text(
                controller.inviteDescription.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Plus Jakarta Sans",
                  fontWeight: FontWeight.w400,
                  fontSize: sw(16),
                  color: Colors.black54,
                  height: 1.4,
                ),
              )),
            ),

            // 💬 Referral Code Input Field
            Positioned(
              top: sh(670),
              left: sw(41),
              width: sw(358),
              height: sh(56),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: sw(16)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(sw(12)),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.textController,
                        onChanged: (value) => controller.referralCode.value = value,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter referral code",
                        ),
                        style: TextStyle(
                          fontFamily: "Plus Jakarta Sans",
                          fontWeight: FontWeight.w600,
                          fontSize: sw(16),
                          color: Colors.black,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: controller.referralCode.value),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Copied to clipboard"),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.black87,
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(
                              bottom: sh(80),
                              left: sw(80),
                              right: sw(80),
                            ),
                          ),
                        );
                      },
                      child: const Icon(Icons.copy, color: Colors.black54, size: 22),
                    ),
                  ],
                ),
              ),
            ),

            // 🚀 Send Promo Code Button
            Positioned(
              top: sh(770),
              left: sw(41),
              width: sw(358),
              height: sh(48),
              child: GestureDetector(
                onTap: () {
                  controller.applyPromo(controller.referralCode.value);
                },
                child: Obx(() => Container(
                  decoration: BoxDecoration(
                    color: controller.referralCode.value.isNotEmpty
                        ? const Color.fromRGBO(0, 53, 102, 1)
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(sw(8)),
                  ),
                  child: Center(
                    child: Text(
                      "Send Promo Code",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta Sans",
                        fontWeight: FontWeight.w600,
                        fontSize: sw(16),
                        color: controller.referralCode.value.isNotEmpty
                            ? Colors.white
                            : Colors.black54,
                      ),
                    ),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
