import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class RulesTermsScreen extends StatelessWidget {
  const RulesTermsScreen({super.key});

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
                  height: sw(28),
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
                  "Rules & Terms",
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: sw(18),
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            Positioned(
              top: sh(120),
              left: sw(20),
              right: sw(20),
              bottom: 0,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildExpansionTile(
                      title: "Service Agreement",
                      content:
                      "This section outlines the terms of service agreement between the app and the user.",
                      sw: sw,
                    ),
                    _divider(),
                    _buildExpansionTile(
                      title: "Privacy Policy",
                      content:
                      "This section describes how your data is collected, stored, and used.",
                      sw: sw,
                    ),
                    _divider(),
                    _buildExpansionTile(
                      title: "Community Guidelines",
                      content:
                      "This section provides behavioral rules and expectations for all users.",
                      sw: sw,
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

  Widget _divider() => const Divider(
    color: Color(0xFFE0E0E0),
    height: 1,
    thickness: 1,
  );

  Widget _buildExpansionTile({
    required String title,
    required String content,
    required double Function(double) sw,
  }) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: sw(0)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: sw(15),
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        iconColor: Colors.black,
        collapsedIconColor: Colors.black,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sw(10), vertical: sw(5)),
            child: Text(
              content,
              style: TextStyle(
                fontSize: sw(13),
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
