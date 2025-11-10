import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/change_phonenumber_controller.dart';

class ChangePhoneNumberScreen extends StatelessWidget {
  const ChangePhoneNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChangePhoneNumberController controller = Get.put(ChangePhoneNumberController());

    // final controller = Get.find<ChangePhoneNumberController>();
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
                  width: sw(24),
                  height: sh(24),
                ),
              ),
            ),

            // 📱 Content
            Positioned(
              top: sh(70),
              left: sw(20),
              right: sw(20),
              bottom: sh(120),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Change Phone Number",
                        style: TextStyle(
                          fontSize: sw(18),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: sh(50)),

                    Text(
                      "Current Phone Number",
                      style: TextStyle(
                        fontSize: sw(14),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: sh(8)),

                    TextField(
                      controller: controller.currentPhoneController,
                      readOnly: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF2F2F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(sw(8)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: sw(12),
                          vertical: sh(14),
                        ),
                      ),
                      style: TextStyle(fontSize: sw(16), color: Colors.black),
                    ),
                    SizedBox(height: sh(30)),

                    Text(
                      "New Phone Number",
                      style: TextStyle(
                        fontSize: sw(14),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: sh(8)),

                    TextField(
                      controller: controller.newPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "Enter new phone number",
                        hintStyle: TextStyle(color: Colors.black45),
                        filled: true,
                        fillColor: const Color(0xFFF2F2F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(sw(8)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: sw(12),
                          vertical: sh(14),
                        ),
                      ),
                      style: TextStyle(fontSize: sw(16), color: Colors.black),
                    ),
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
                  onPressed: controller.savePhoneNumber,
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
