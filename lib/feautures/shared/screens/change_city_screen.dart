import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../controllers/change_city_controller.dart';

class ChangeCityScreen extends StatelessWidget {
  const ChangeCityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangeCityController());
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
              top: sh(39),
              left: sw(33),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: SvgPicture.asset(
                  "assets/images/Arrow.svg",
                  width: sw(24),
                  height: sh(24),
                ),
              ),
            ),

            // 🏙️ Main Content
            Positioned(
              top: sh(62),
              left: sw(25),
              right: sw(20),
              bottom: sh(120),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Center(
                      child: Text(
                        "Change City",
                        style: TextStyle(
                          fontSize: sw(18),
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: sh(20)),

                    // Current City
                    Text(
                      "Current City",
                      style: TextStyle(
                        fontSize: sw(16),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: sh(8)),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: sw(12),
                        vertical: sh(14),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(sw(8)),
                      ),
                      child: Obx(() => Text(
                        controller.currentCity.value,
                        style: TextStyle(
                          fontSize: sw(16),
                          color: Colors.black,
                        ),
                      )),
                    ),
                    SizedBox(height: sh(30)),

                    // Select New City
                    Text(
                      "Select New City",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta Sans",
                        fontSize: sw(16),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: sh(8)),

                    Obx(() => Container(
                      padding: EdgeInsets.symmetric(horizontal: sw(12)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(sw(8)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.selectedCity.value.isEmpty
                              ? null
                              : controller.selectedCity.value,
                          hint: const Text("Choose city"),
                          items: controller.availableCities
                              .map(
                                (city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            ),
                          )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedCity.value = value;
                            }
                          },
                          isExpanded: true,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),

            // 💾 Save Button
            Positioned(
              left: sw(41),
              bottom: sh(28),
              child: SizedBox(
                width: sw(358),
                height: sh(48),
                child: ElevatedButton(
                  onPressed: controller.saveCity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sw(8)),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Save",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: sw(16),
                      fontWeight: FontWeight.w600,
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
