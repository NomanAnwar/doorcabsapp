import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            width: screenWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header with Back Button and Title
                Padding(
                  padding: EdgeInsets.only(
                    left: sw(25),
                    right: sw(25),
                    top: sh(20),
                    bottom: sh(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back arrow at top-left
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: SvgPicture.asset(
                          "assets/images/Arrow.svg",
                          width: sw(28),
                          height: sh(28),
                        ),
                      ),
                      SizedBox(height: sh(10)),

                      // Centered "Settings" text below the arrow
                      Center(
                        child: Text(
                          "Settings",
                          style: TextStyle(
                            fontFamily: "Plus Jakarta Sans",
                            fontWeight: FontWeight.w700,
                            fontSize: sw(18),
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sh(10)),


                /// Account Section
                Padding(
                  padding: EdgeInsets.only(left: sw(40)),
                  child: Text(
                    "Account",
                    style: TextStyle(
                      fontFamily: "Plus Jakarta Sans",
                      fontWeight: FontWeight.w700,
                      fontSize: sw(18),
                      color: Colors.black,
                    ),
                  ),
                ),

                SizedBox(height: sh(16)),

                /// Account Items
                Obx(() => Column(
                  children: controller.accountSettings.map((item) {
                    return _buildSettingItem(
                      title: item.title,
                      iconPath: item.iconPath,
                      onTap: item.onTap,
                      sw: sw,
                      sh: sh,
                    );
                  }).toList(),
                )),

                SizedBox(height: sh(15)),

                /// Support Section
                Padding(
                  padding: EdgeInsets.only(left: sw(40)),
                  child: Text(
                    "Support",
                    style: TextStyle(
                      fontFamily: "Plus Jakarta Sans",
                      fontWeight: FontWeight.w700,
                      fontSize: sw(18),
                      color: Colors.black,
                    ),
                  ),
                ),

                SizedBox(height: sh(16)),

                /// Support Items
                Obx(() => Column(
                  children: controller.supportSettings.map((item) {
                    return _buildSettingItem(
                      title: item.title,
                      iconPath: item.iconPath,
                      onTap: item.onTap,
                      sw: sw,
                      sh: sh,
                    );
                  }).toList(),
                )),

                SizedBox(height: sh(140)),

                /// Logout Button
                Padding(
                  padding: EdgeInsets.only(left: sw(41), right: sw(25)),
                  child: GestureDetector(
                    onTap: controller.logout,
                    child: Container(
                      width: sw(358),
                      height: sh(48),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(sw(12)),
                      ),
                      child: Center(
                        child: Text(
                          "Logout",
                          style: TextStyle(
                            fontFamily: "Plus Jakarta Sans",
                            fontWeight: FontWeight.w500,
                            fontSize: sw(16),
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: sh(16)),

                /// Delete Account Button
                Padding(
                  padding: EdgeInsets.only(left: sw(41), right: sw(25)),
                  child: GestureDetector(
                    onTap: controller.deleteAccount,
                    child: Container(
                      width: sw(358),
                      height: sh(48),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(sw(12)),
                      ),
                      child: Center(
                        child: Text(
                          "Delete Account",
                          style: TextStyle(
                            fontFamily: "Plus Jakarta Sans",
                            fontWeight: FontWeight.w500,
                            fontSize: sw(16),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: sh(40)),
              ],
            ),
          ),
        ),
      )
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String iconPath,
    Function()? onTap,
    required double Function(double) sw,
    required double Function(double) sh,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: sw(399),
        height: sh(55),
        margin: EdgeInsets.only(
          left: sw(25),
          right: sw(25),
          bottom: sh(5),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: sw(16),
          vertical: sh(8),
        ),
        child: Row(
          children: [
            /// Icon Container
            Container(
              // width: sw(40),
              // height: sh(40),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  // color: Colors.black87,
                ),
              ),
            ),

            SizedBox(width: sw(16)),

            /// Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: "Plus Jakarta Sans",
                  fontWeight: FontWeight.w600,
                  fontSize: sw(16),
                  color: Colors.black87,
                ),
              ),
            ),

            /// Arrow Icon
            SvgPicture.asset(
              "assets/images/arrow_right.svg",
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}