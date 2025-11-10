import 'package:doorcab/feautures/shared/screens/support_chat.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/help_controller.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HelpController controller = Get.put(HelpController());

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
            // 🔙 Back Arrow + Title
            // 🔙 Back Arrow (above the title)
            Positioned(
              top: sh(10),
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

// 🧾 Centered Title below the arrow
            Positioned(
              top: sh(42), // below arrow
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Help',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: sw(18),
                    color: Colors.black,
                  ),
                ),
              ),
            ),


            // 🔍 Search Bar
            Positioned(
              top: sh(95),
              left: sw(19),
              right: sw(19),
              child: Container(
                height: sh(48),
                padding: EdgeInsets.symmetric(horizontal: sw(16)),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(242, 242, 242, 1),
                  borderRadius: BorderRadius.circular(sw(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey, size: 20),
                    SizedBox(width: sw(12)),
                    Text(
                      'Search',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: sw(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🧾 FAQ Title
            Positioned(
              top: sh(172),
              left: sw(27),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: sw(20),
                  color: Colors.black,
                ),
              ),
            ),

            // 📋 FAQ List
            Positioned(
              top: sh(210),
              left: sw(27),
              right: sw(27),
              bottom: sh(140),
              child: Obx(() => ListView.builder(
                itemCount: controller.faqs.length,
                itemBuilder: (context, index) {
                  final faq = controller.faqs[index];
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
                        style: FTextTheme.lightTextTheme.titleSmall,
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
                              style: FTextTheme.lightTextTheme.bodySmall
                                  ?.copyWith(
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )),
            ),

            // 📞 Contact Support Button
            Positioned(
              bottom: sh(28),
              left: sw(41),
              child: SizedBox(
                width: sw(358),
                height: sh(48),
                child: ElevatedButton(
                  onPressed: () => Get.to(() =>  SupportChat()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC300),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sw(14)),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: sw(16),
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
    );
  }
}
