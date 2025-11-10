import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sw(25)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: sh(20)),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: SvgPicture.asset(
                    "assets/images/Arrow.svg",
                    width: sw(28),
                    height: sh(28),
                  ),
                ),
              ),
              SizedBox(height: sh(20)),
              Center(
                child: Text(
                  "Delete Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Plus Jakarta Sans",
                    fontWeight: FontWeight.w700,
                    fontSize: sw(18),
                    height: 23 / 18,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: sh(45)),

              // 🧾 Confirmation Text
              Text(
                "Are you sure you want to delete your account?",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: "Plus Jakarta Sans",
                  fontWeight: FontWeight.w700,
                  fontSize: sw(22),
                  height: 28 / 22,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: sh(20)),

              Text(
                "Deleting your account will permanently remove all your data, including ratings, reviews, and payment information. This action cannot be undone.",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: "Plus Jakarta Sans",
                  fontWeight: FontWeight.w400,
                  fontSize: sw(16),
                  height: 24 / 16,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                width: sw(405),
                height: sh(163),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E3E3),
                  borderRadius: BorderRadius.circular(sw(14)),
                ),
                child: const TextField(
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: "Write reason",
                    hintStyle: TextStyle(color: Colors.black45),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              SizedBox(height: sh(30)),

              SizedBox(
                width: sw(358),
                height: sh(48),
                child: ElevatedButton(
                  onPressed: () {
                    // Handle delete action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDF0A0A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sw(8)),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Delete Account",
                    style: TextStyle(
                      fontFamily: "Plus Jakarta Sans",
                      fontWeight: FontWeight.w600,
                      fontSize: sw(16),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: sh(20)),

              SizedBox(
                width: sw(358),
                height: sh(48),
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3E3E3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sw(8)),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontFamily: "Plus Jakarta Sans",
                      fontWeight: FontWeight.w600,
                      fontSize: sw(16),
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(height: sh(20)),
            ],
          ),
        ),
      ),
    );
  }
}
