import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ProfileController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: FColors.primaryColor,
      body: Form(
        key: c.formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height,
            width: size.width,
            child: Stack(
              children: [
                /// Header Image
                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    FImages.started_bg_down,
                    fit: BoxFit.cover,
                    height: 200,
                  ),
                ),

                /// Edit Button
                Positioned(
                  top: 38,
                  right: 20,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Edit",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                /// White Background Container
                Positioned(
                  top: 131,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: size.width,
                    height: size.height,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),

                /// Profile Avatar
                Positioned(
                  top: 180,
                  left: size.width * 0.35,
                  child: Image.asset(
                    FImages.profile_img_sample,
                    fit: BoxFit.cover,
                    height: 100,
                    width: 100,
                  ),
                ),

                /// First Name
                Positioned(
                  top: 349,
                  left: 21,
                  child: _buildField(
                    width: 190,
                    height: 52,
                    controller: c.firstNameCtrl,
                    hint: "First Name",
                    icon: Icons.person,
                  ),
                ),

                /// Last Name
                Positioned(
                  top: 349,
                  left: 224,
                  child: _buildField(
                    width: 190,
                    height: 52,
                    controller: c.lastNameCtrl,
                    hint: "Last Name",
                    icon: Icons.person_outline,
                  ),
                ),

                /// Email
                Positioned(
                  top: 445,
                  left: 25,
                  child: _buildField(
                    width: 393,
                    height: 52,
                    controller: c.emailCtrl,
                    hint: "Email",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),

                /// Contact
                Positioned(
                  top: 541,
                  left: 25,
                  child: _buildField(
                    width: 393,
                    height: 52,
                    controller: c.contactCtrl,
                    hint: "Contact Number",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ),

                /// Emergency Contact
                Positioned(
                  top: 637,
                  left: 25,
                  child: _buildField(
                    width: 393,
                    height: 52,
                    controller: c.emergencyCtrl,
                    hint: "Emergency Contact",
                    icon: Icons.contact_phone,
                    keyboardType: TextInputType.phone,
                  ),
                ),

                /// Country
                Positioned(
                  top: 733,
                  left: 25,
                  child: _buildField(
                    width: 190,
                    height: 52,
                    controller: c.countryCtrl,
                    hint: "Country",
                    icon: Icons.flag,
                  ),
                ),

                /// City
                Positioned(
                  top: 733,
                  left: 229,
                  child: _buildField(
                    width: 190,
                    height: 52,
                    controller: c.cityCtrl,
                    hint: "City",
                    icon: Icons.location_city,
                  ),
                ),

                /// Continue Button
                Positioned(
                  bottom: 40,
                  left: 25,
                  right: 25,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: c.saveAndContinue,
                      child: const Text(FTextStrings.submit),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// --- Text Field with validation ---
  Widget _buildField({
    required double width,
    required double height,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) =>
        value == null || value.trim().isEmpty ? "$hint is required" : null,
        style: FTextTheme.lightTextTheme.bodySmall,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade700),
          hintText: hint,
          hintStyle: FTextTheme.lightTextTheme.bodySmall,
          filled: true,
          fillColor: const Color(0xFFE3E3E3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
