import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/theme/custom_theme/text_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        child: Stack(
          children: [
            // 🔙 Back Arrow
            Positioned(
              top: sh(20),
              left: sw(20),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: SvgPicture.asset(
                  "assets/images/Arrow.svg",
                  width: sw(28),
                  height: sh(28),
                ),
              ),
            ),

            // 🧾 Title
            Positioned(
              top: sh(62),
              left: sw(25),
              right: sw(25),
              child: Center(
                child: Text(
                  "Privacy & Policy",
                  style: FTextTheme.lightTextTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: FTextTheme.lightTextTheme.titleLarge!.fontSize! *
                        screenWidth /
                        baseWidth,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            // 📜 Content
            Positioned(
              top: sh(120),
              left: sw(20),
              right: sw(20),
              bottom: 0,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildExpansionTile(
                      title: "Data Collection",
                      content:
                      "We collect personal information such as name, contact details, and location only to improve your user experience and ensure smooth app functionality.",
                      sw: sw,
                      sh: sh,
                      screenWidth: screenWidth,
                      baseWidth: baseWidth,
                    ),
                    _divider(sw: sw),
                    _buildExpansionTile(
                      title: "Data Usage",
                      content:
                      "Your data is used solely for providing and improving our services. We never sell, rent, or share your personal data with unauthorized parties.",
                      sw: sw,
                      sh: sh,
                      screenWidth: screenWidth,
                      baseWidth: baseWidth,
                    ),
                    _divider(sw: sw),
                    _buildExpansionTile(
                      title: "Data Protection",
                      content:
                      "We use advanced encryption and secure storage mechanisms to protect your information against unauthorized access or misuse.",
                      sw: sw,
                      sh: sh,
                      screenWidth: screenWidth,
                      baseWidth: baseWidth,
                    ),
                    _divider(sw: sw),
                    _buildExpansionTile(
                      title: "User Rights",
                      content:
                      "You have the right to access, correct, or delete your personal data. You can also withdraw consent for data processing anytime by contacting support.",
                      sw: sw,
                      sh: sh,
                      screenWidth: screenWidth,
                      baseWidth: baseWidth,
                    ),
                    _divider(sw: sw),
                    _buildExpansionTile(
                      title: "Policy Updates",
                      content:
                      "We may update our privacy policy occasionally. Users will be notified of significant changes through in-app alerts or email notifications.",
                      sw: sw,
                      sh: sh,
                      screenWidth: screenWidth,
                      baseWidth: baseWidth,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider({required double Function(double) sw}) => Divider(
    color: const Color(0xFFE0E0E0),
    height: 1,
    thickness: sw(1),
  );

  Widget _buildExpansionTile({
    required String title,
    required String content,
    required double Function(double) sw,
    required double Function(double) sh,
    required double screenWidth,
    required double baseWidth,
  }) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: sw(0)),
        title: Text(
          title,
          style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! *
                screenWidth /
                baseWidth,
            color: Colors.black,
          ),
        ),
        iconColor: Colors.black,
        collapsedIconColor: Colors.black,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sw(10), vertical: sh(5)),
            child: Text(
              content,
              style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! *
                    screenWidth /
                    baseWidth,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}