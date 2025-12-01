import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';

import '../controllers/rules_terms_controller.dart';

class RulesTermsScreen extends StatelessWidget {
  const RulesTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RulesTermsController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base reference (iPhone 16 Pro Max)
    final baseWidth = 440.0;
    final baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        final loading = controller.isLoading.value;

        return Stack(
          children: [
            /// Main UI
            SafeArea(
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
                        style: FTextTheme.lightTextTheme.headlineLarge?.copyWith(
                          fontSize: sw(18),
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Positioned(
                    top: sh(120),
                    left: sw(20),
                    right: sw(20),
                    bottom: 0,
                    child: Obx(() {
                      if (controller.rulesTerms.isEmpty && !loading) {
                        return Center(
                          child: Text(
                            "No rules & terms available",
                            style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                              fontSize: sw(16),
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            ...controller.rulesTerms.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Column(
                                children: [
                                  _buildExpansionTile(
                                    title: item['title'] ?? 'Untitled',
                                    content: item['content'] ?? 'No content available',
                                    sw: sw,
                                  ),
                                  if (index < controller.rulesTerms.length - 1) _divider(),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            /// Loader Overlay
            if (loading)
              Container(
                height: screenHeight,
                width: screenWidth,
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: CircularProgressIndicator(
                    color: FColors.secondaryColor,
                  ),
                ),
              ),
          ],
        );
      }),
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
          style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
            fontSize: sw(16),
            fontWeight: FontWeight.w600,
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
              style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                fontSize: sw(14),
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