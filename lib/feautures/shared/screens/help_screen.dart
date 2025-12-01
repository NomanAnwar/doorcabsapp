import 'package:doorcab/feautures/shared/screens/support_chat.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/help_controller.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HelpController controller = Get.put(HelpController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base reference (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              /// White Background Container
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white,
                ),
              ),

              /// 🔙 Back Arrow
              Positioned(
                top: sh(23),
                left: sw(20),
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: SvgPicture.asset(
                    'assets/images/Arrow.svg',
                    width: sw(28),
                    height: sw(28),
                  ),
                ),
              ),

              /// 🧾 Centered Title
              Positioned(
                top: sh(23),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Help',
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

              /// 🔍 Search Bar
              Positioned(
                top: sh(70),
                left: sw(20),
                right: sw(20),
                child: Container(
                  height: sh(48),
                  padding: EdgeInsets.symmetric(horizontal: sw(16)),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(242, 242, 242, 1),
                    borderRadius: BorderRadius.circular(sw(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search,
                          color: Colors.grey,
                          size: sw(20)),
                      SizedBox(width: sw(12)),
                      Expanded(
                        child: TextField(
                          controller: controller.searchController, // Added controller
                          onChanged: controller.updateSearchQuery,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search',
                            hintStyle: FTextTheme.lightTextTheme.bodyMedium!.copyWith(
                              color: Colors.grey,
                              fontSize: FTextTheme.lightTextTheme.bodyMedium!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                            ),
                          ),
                          style: FTextTheme.lightTextTheme.bodyMedium!.copyWith(
                            color: Colors.black,
                            fontSize: FTextTheme.lightTextTheme.bodyMedium!.fontSize! *
                                screenWidth /
                                baseWidth,
                          ),
                        ),
                      ),
                      Obx(() => controller.searchQuery.isNotEmpty
                          ? GestureDetector(
                        onTap: controller.clearSearch,
                        child: Icon(Icons.close,
                            color: Colors.grey,
                            size: sw(20)),
                      )
                          : const SizedBox()),
                    ],
                  ),
                ),
              ),

              /// 🧾 FAQ Title
              Positioned(
                top: sh(140),
                left: sw(27),
                right: sw(27),
                child: Center(
                  child: Text(
                    'Frequently Asked Questions',
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

              /// 📋 FAQ List
              Positioned(
                top: sh(190),
                left: sw(20),
                right: sw(20),
                bottom: sh(100),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: FColors.secondaryColor,
                          ),
                          SizedBox(height: sh(16)),
                          Text(
                            'Loading FAQs...',
                            style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                              fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.hasError.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: sw(48),
                            color: Colors.grey,
                          ),
                          SizedBox(height: sh(16)),
                          Text(
                            'Failed to load FAQs',
                            style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                              fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: sh(16)),
                          ElevatedButton(
                            onPressed: controller.retryFetchFAQs,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FColors.secondaryColor,
                              foregroundColor: Colors.black,
                            ),
                            child: Text(
                              'Retry',
                              style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                                fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                                    screenWidth /
                                    baseWidth,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.filteredFaqs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: sw(48),
                            color: Colors.grey,
                          ),
                          SizedBox(height: sh(16)),
                          Text(
                            controller.searchQuery.isEmpty
                                ? 'No FAQs available'
                                : 'No matching FAQs found',
                            style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                              fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                              color: Colors.grey,
                            ),
                          ),
                          if (controller.searchQuery.isNotEmpty) ...[
                            SizedBox(height: sh(8)),
                            Text(
                              'Try different keywords',
                              style: FTextTheme.lightTextTheme.bodyMedium!.copyWith(
                                fontSize: FTextTheme.lightTextTheme.bodyMedium!.fontSize! *
                                    screenWidth /
                                    baseWidth,
                                color: Colors.grey,
                              ),
                            ),
                            // SizedBox(height: sh(16)),
                            // ElevatedButton(
                            //   onPressed: controller.clearSearch,
                            //   style: ElevatedButton.styleFrom(
                            //     backgroundColor: FColors.secondaryColor,
                            //     foregroundColor: Colors.black,
                            //   ),
                            //   child: Text(
                            //     'Clear Search',
                            //     style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                            //       fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                            //           screenWidth /
                            //           baseWidth,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = controller.filteredFaqs[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: sh(12)),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFFF0F0F0),
                              width: 1,
                            ),
                          ),
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.only(
                            bottom: sh(16),
                            top: sh(8),
                          ),
                          title: Text(
                            faq.question,
                            style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                              fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                            ),
                          ),
                          trailing: Icon(
                            faq.isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.black,
                            size: sw(24),
                          ),
                          onExpansionChanged: (expanded) {
                            controller.toggleFAQ(index);
                          },
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(right: sw(10)),
                                child: Text(
                                  faq.answer,
                                  style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                                    color: FColors.chipBg,
                                    height: 1.4,
                                    fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! *
                                        screenWidth /
                                        baseWidth,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),

              /// 📞 Contact Support Button
              Positioned(
                left: sw(25),
                right: sw(25),
                bottom: sh(30),
                child: SizedBox(
                  height: sh(48),
                  child: ElevatedButton(
                    onPressed: () => Get.to(() => SupportChat()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FColors.primaryColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(sw(14)),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Contact Support',
                      style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                        fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                            screenWidth /
                            baseWidth,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}