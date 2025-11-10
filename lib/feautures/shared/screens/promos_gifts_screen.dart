import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../controllers/promos_gifts_controller.dart';
import 'available_promo_screen.dart';
import 'gift_discount_screen.dart';


class PromoGiftScreen extends StatelessWidget {
  final PromoGiftController controller = Get.put(PromoGiftController());

  PromoGiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header block (arrow slightly up, title closer)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row containing back arrow (left) — we push it left but title is centered below
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Padding(
                        // small bottom padding to make arrow sit slightly higher than title
                        padding: EdgeInsets.only(bottom: sh(15)),
                        child: SvgPicture.asset(
                          "assets/images/Arrow.svg",
                          width: sw(24),
                          height: sh(24),
                        ),
                      ),
                    ),
                  ),

                  // Title centered and placed tightly below the arrow
                  Padding(
                    padding: EdgeInsets.only(top: sh(2), bottom: sh(6)),
                    child: Center(
                      child: Text(
                        "Promo & Gift",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta Sans",
                          fontWeight: FontWeight.w700,
                          fontSize: sw(18),
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Small separation
            SizedBox(height: sh(6)),

            // Options list
            _buildOption(
              title: "Available Promo Code",
              icon: "assets/images/promo.svg",
              sw: sw,
              sh: sh,
              onTap: () => Get.to(() => AvailablePromoScreen()),
            ),

            _buildOption(
              title: "Gift discount",
              icon: "assets/images/gift1.svg",
              sw: sw,
              sh: sh,
              onTap: () => Get.to(() => GiftDiscountScreen()),
            ),

            // Fill remaining space so invite button sits at bottom
            const Spacer(),

            // Invite Friend button (matches 358x48 design)
            Padding(
              padding: EdgeInsets.only(left: sw(24), right: sw(24), bottom: sh(18)),
              child: GestureDetector(
                onTap: () {
                  Get.to(() => GiftDiscountScreen());
                },
                child: Container(
                  width: double.infinity,
                  height: sh(48),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC727),
                    borderRadius: BorderRadius.circular(sw(10)),
                  ),
                  child: Center(
                    child: Text(
                      "Invite Friend",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta Sans",
                        fontWeight: FontWeight.w700,
                        fontSize: sw(16),
                        color: const Color.fromRGBO(0, 53, 102, 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String icon,
    required double Function(double) sw,
    required double Function(double) sh,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: sw(16), vertical: sh(2)),
        padding: EdgeInsets.symmetric(horizontal: sw(12), vertical: sh(10)),
        decoration: BoxDecoration(
          // intentionally no border or background to match the screenshot: minimal look
          borderRadius: BorderRadius.circular(sw(10)),
        ),
        child: Row(
          children: [
            // icon inside small rounded square background
            Container(
              width: sw(38),
              height: sw(38),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(sw(8)),
              ),
              child: Center(
                child: icon.toLowerCase().endsWith('.svg')
                    ? SvgPicture.asset(
                  icon,
                  // width: sw(20),
                  // height: sw(20),
                )
                    : Image.asset(
                  icon,
                  width: sw(20),
                  height: sw(20),
                  fit: BoxFit.contain,
                ),
              ),
            ),

            SizedBox(width: sw(12)),

            // title text
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: "Plus Jakarta Sans",
                  fontWeight: FontWeight.w600,
                  fontSize: sw(15),
                  color: Colors.black,
                ),
              ),
            ),

            // right chevron arrow
            SvgPicture.asset(
              "assets/images/arrow_right.svg",
            ),
          ],
        ),
      ),
    );
  }
}
