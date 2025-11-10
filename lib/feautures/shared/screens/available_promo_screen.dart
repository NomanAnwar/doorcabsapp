import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../controllers/promos_gifts_controller.dart';

class AvailablePromoScreen extends StatelessWidget {
  const AvailablePromoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;
    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    final PromoGiftController controller = Get.put(PromoGiftController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sw(25), vertical: sh(25)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Arrow
              GestureDetector(
                onTap: () => Get.back(),
                child: SvgPicture.asset(
                  "assets/images/Arrow.svg",
                  width: sw(28),
                  height: sh(28),
                ),
              ),
              SizedBox(height: sh(5)),

              // Title
              Center(
                child: Text(
                  "Promotions",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta Sans",
                    fontWeight: FontWeight.w700,
                    fontSize: sw(18),
                    color: const Color(0xFF000000), // 🟦 Text color added
                  ),
                ),
              ),

              SizedBox(height: sh(20)),

              Text(
                "Available Promotions",
                style: TextStyle(
                  fontFamily: "Plus Jakarta Sans",
                  fontWeight: FontWeight.w700,
                  fontSize: sw(22),
                  color: const Color(0xFF000000),
                ),
              ),

              SizedBox(height: sh(15)),

              // Promo list
              Expanded(
                child: Obx(() => ListView.builder(
                  itemCount: controller.promoList.length,
                  itemBuilder: (context, index) {
                    final promo = controller.promoList[index];
                    return _promoCard(
                      sw,
                      sh,
                      title: promo.title,
                      desc: promo.description,
                      expiry: promo.expiry,
                      image: promo.image,
                      onApply: () => controller.applyPromo(promo.code),
                    );
                  },
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promoCard(
      double Function(double) sw,
      double Function(double) sh, {
        required String title,
        required String desc,
        required String expiry,
        required String image,
        required VoidCallback onApply,
      }) {
    return Container(
      margin: EdgeInsets.only(bottom: sh(15)),
      padding: EdgeInsets.all(sw(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side (text)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expiry,
                  style: TextStyle(
                    fontFamily: "Plus Jakarta Sans",
                    fontWeight: FontWeight.w400,
                    fontSize: sw(13),
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: sh(4)),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: "Plus Jakarta Sans",
                    fontWeight: FontWeight.w700,
                    fontSize: sw(15),
                    color: const Color(0xFF000000),
                  ),
                ),
                SizedBox(height: sh(4)),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: "Plus Jakarta Sans",
                    fontWeight: FontWeight.w400,
                    fontSize: sw(13),
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: sh(10)),

                // Apply button connected
                GestureDetector(
                  onTap: onApply,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sw(16),
                      vertical: sh(6),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0F0),
                      borderRadius: BorderRadius.circular(sw(6)),
                    ),
                    child: Text(
                      "Apply",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta Sans",
                        fontSize: sw(14),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: sw(12)),

          // Right side (PNG image)
          ClipRRect(
            borderRadius: BorderRadius.circular(sw(10)),
            child: Image.asset(
              image,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
