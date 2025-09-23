// ProfileScreen with SingleChildScrollView
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/widgets/buttons/responsive_button.dart';
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

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: FColors.primaryColor,
      body: Form(
        key: c.formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            height: screenHeight,
            width: screenWidth,
            child: Stack(
              children: [
                /// Header Image
                Positioned(
                  top: sh(14),
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    FImages.started_bg_down,
                    fit: BoxFit.cover,
                    height: sh(200),
                  ),
                ),

                /// Edit Button (commented but responsive)
                /*
                Positioned(
                  top: sh(38),
                  right: sw(20),
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      "Edit",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: sw(16),
                      ),
                    ),
                  ),
                ),
                */

                /// White Background Container
                Positioned(
                  top: sh(131),
                  left: 0,
                  right: 0,
                  child: Container(
                    width: screenWidth,
                    height: screenHeight,
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
                  top: sh(160),
                  left: screenWidth * 0.35,
                  child: Obx(() {
                    return GestureDetector(
                      onTap: () => _showImagePicker(context, c),
                      child: CircleAvatar(
                        radius: sw(55),
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: c.profileImage.value != null
                            ? FileImage(c.profileImage.value!)
                            : const AssetImage(FImages.profile_img_sample)
                        as ImageProvider,
                        child: c.profileImage.value == null
                            ? Icon(Icons.camera_alt,
                            color: Colors.white, size: sw(40))
                            : null,
                      ),
                    );
                  }),
                ),

                /// First Name
                Positioned(
                  top: sh(349),
                  left: sw(21),
                  child: _buildField(
                    width: sw(190),
                    height: sh(52),
                    controller: c.firstNameCtrl,
                    hint: "First Name",
                    icon: Icons.person,
                    validator: (value) =>
                    value == null || value.trim().isEmpty ? "First Name is required" : null,
                  ),
                ),

                /// Last Name
                Positioned(
                  top: sh(349),
                  left: sw(224),
                  child: _buildField(
                    width: sw(190),
                    height: sh(52),
                    controller: c.lastNameCtrl,
                    hint: "Last Name",
                    icon: Icons.person_outline,
                  ),
                ),

                /// Email
                Positioned(
                  top: sh(445),
                  left: sw(25),
                  child: _buildField(
                    width: sw(393),
                    height: sh(52),
                    controller: c.emailCtrl,
                    hint: "Email",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),

                /// Contact
                // Positioned(
                //   top: sh(541),
                //   left: sw(25),
                //   child: _buildField(
                //     width: sw(393),
                //     height: sh(52),
                //     controller: c.contactCtrl,
                //     hint: "Contact Number",
                //     icon: Icons.phone,
                //     keyboardType: TextInputType.phone,
                //
                //   ),
                // ),

                /// Emergency Contact
                Positioned(
                  // top: sh(637),
                  top: sh(541),
                  left: sw(25),
                  child: _buildField(
                    width: sw(393),
                    height: sh(52),
                    controller: c.emergencyCtrl,
                    hint: "Emergency Contact",
                    icon: Icons.contact_phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                    value == null || value.trim().isEmpty ? "Emergency Contact is required" : null,
                  ),
                ),

                /// Country
                Positioned(
                  top: sh(637),
                  // top: sh(733),
                  left: sw(25),
                  child: _buildField(
                    width: sw(190),
                    height: sh(52),
                    controller: c.countryCtrl,
                    hint: "Country",
                    icon: Icons.flag,
                  ),
                ),

                /// City
                Positioned(
                  top: sh(637),
                  // top: sh(733),
                  left: sw(229),
                  child: _buildField(
                    width: sw(190),
                    height: sh(52),
                    controller: c.cityCtrl,
                    hint: "City",
                    icon: Icons.location_city,
                  ),
                ),

                /// Continue Button
                /// Continue Button
                Positioned(
                  bottom: sh(140),
                  left: sw(25),
                  right: sw(25),
                  child: Obx(() {
                    return ResponsiveButton(
                      onPressed: c.isLoading.value ? null : c.saveAndContinue, // disable when loading
                      backgroundColor: FColors.secondaryColor,
                      textColor: Colors.white,
                      sw: sw,
                      sh: sh,
                      baseWidth: baseWidth,
                      screenWidth: screenWidth,
                      width: 343,
                      height: 52,
                      borderRadius: 14,
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      text: FTextStrings.submit,
                      child: c.isLoading.value
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : Text(FTextStrings.submit,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          )),
                    );
                  }),
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
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      width: width,
      // height: height,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator:  validator,
        // validator: (value) => value == null || value.trim().isEmpty ? "$hint is required" : null,
        style: FTextTheme.lightTextTheme.bodySmall,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade700),
          hintText: hint,
          hintStyle: FTextTheme.lightTextTheme.bodySmall,
          filled: true,
          fillColor: const Color(0xFFE3E3E3),
          contentPadding: const EdgeInsets.symmetric(vertical: 1, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Image picker options dialog
  void _showImagePicker(BuildContext context, ProfileController c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Title
            Text(
              "Upload Profile Picture",
              style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: FColors.primaryColor,
              ),
            ),
            const SizedBox(height: 15),

            /// Divider
            Divider(color: Colors.grey.shade300, thickness: 1),

            /// Gallery option
            ListTile(
              leading: Icon(Icons.photo_library, color: FColors.primaryColor),
              title: Text(
                "Pick from Gallery",
                style: FTextTheme.lightTextTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                ),
              ),
              onTap: () {
                c.pickImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),

            /// Camera option
            ListTile(
              leading: Icon(Icons.camera_alt, color: FColors.primaryColor),
              title: Text(
                "Take a Photo",
                style: FTextTheme.lightTextTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                ),
              ),
              onTap: () {
                c.pickImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 10),

            /// Cancel button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: FTextTheme.lightTextTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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