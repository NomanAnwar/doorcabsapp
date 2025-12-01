import 'package:cached_network_image/cached_network_image.dart';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/rating_controller.dart';
import '../../passenger/models/driver_model.dart';

class RatingScreen extends StatelessWidget {
  const RatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final c = Get.put(RatingController());
    final role = StorageService.getRole();

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
            /// White Background Container (like ProfileScreen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
              ),
            ),

            /// Back Arrow button - positioned like ProfileScreen
            Positioned(
              top: sh(23),
              left: sw(23),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: sw(28),
                  height: sh(28),
                  child: Icon(
                    Icons.arrow_back,
                    size: sw(28),
                    color: Colors.black, // Black color for white background
                  ),
                ),
              ),
            ),

            /// Title - positioned centrally at top
            Positioned(
              top: sh(23),
              left: 0,
              right: 0,
              child: Container(
                height: sh(28),
                alignment: Alignment.center,
                child: Text(
                  role == "Driver" ? "Rate passenger" : "Rate your ride",
                  style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                    fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                        screenWidth /
                        baseWidth,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            /// Profile Image - positioned below header
            Positioned(
              top: sh(80), // Adjusted from margin.only(top: sh(20))
              left: (screenWidth - sw(128)) / 2, // Center horizontally
              child: Container(
                width: sw(128),
                height: sh(128),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: args!['image']?.toString() ?? '',
                    fit: BoxFit.cover,
                    width: sw(128),
                    height: sh(128),
                    placeholder: (context, url) => Image.asset(
                      'assets/images/profile_img_sample.png',
                      fit: BoxFit.cover,
                      width: sw(128),
                      height: sh(128),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/profile_img_sample.png',
                      fit: BoxFit.cover,
                      width: sw(128),
                      height: sh(128),
                    ),
                  ),
                ),
              ),
            ),

            /// Subtitle - below profile image
            Positioned(
              top: sh(230), // profile top(80) + profile height(128) + spacing(22)
              left: sw(20),
              right: sw(20),
              child: Text(
                role == "Driver"
                    ? "Rate Your Experience With ${args['name']}?"
                    : "Rate Your Experience With ${args['name']}?",
                style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                  fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                      screenWidth /
                      baseWidth,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            /// Stars Rating - below subtitle
            Positioned(
              top: sh(280), // subtitle top(230) + subtitle height + spacing
              left: 0,
              right: 0,
              child: Obx(() {
                return Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      final filled = c.rating.value >= idx;
                      return GestureDetector(
                        onTap: () => c.rating.value = idx.toDouble(),
                        child: Icon(
                          Icons.star,
                          size: sw(42),
                          color: filled ? Colors.amber : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),

            /// Tags Section - scrollable content area
            Positioned(
              top: sh(350), // stars top(280) + stars height + spacing
              left: 0,
              right: 0,
              bottom: sh(100), // Space for submit button
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sw(20)),
                child: Column(
                  children: [
                    /// Tags Title
                    Container(
                      margin: EdgeInsets.only(bottom: sh(20)),
                      child: Text(
                        "What did you like the most?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16 * screenWidth / baseWidth,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    /// Tags Chips - Dynamic height
                    Obx(() {
                      if (c.isLoading.value) {
                        return Container(
                          height: sh(100),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(FColors.primaryColor),
                            ),
                          ),
                        );
                      }

                      return Wrap(
                        spacing: sw(8),
                        runSpacing: sh(8),
                        alignment: WrapAlignment.center,
                        children: c.tags.map((t) {
                          return Obx(() {
                            final sel = c.selectedTags.contains(t);
                            return InputChip(
                              label: Text(
                                t,
                                style: TextStyle(
                                  fontSize: 14 * screenWidth / baseWidth,
                                ),
                              ),
                              selected: sel,
                              onSelected: (_) => c.toggleTag(t),
                              selectedColor: FColors.primaryColor,
                              backgroundColor: Colors.grey.shade200,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: sel ? Colors.white : Colors.black87,
                              ),
                            );
                          });
                        }).toList(),
                      );
                    }),

                    /// Spacer between tags and message
                    SizedBox(height: sh(30)),

                    /// Message TextField
                    TextField(
                      controller: c.messageController,
                      maxLines: 7,
                      style: TextStyle(
                        fontSize: 16 * screenWidth / baseWidth,
                      ),
                      decoration: InputDecoration(
                        hintText: "Write Message",
                        hintStyle: TextStyle(
                          fontSize: 14 * screenWidth / baseWidth,
                          color: Colors.black54,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: sw(16),
                          vertical: sh(12),
                        ),
                      ),
                    ),

                    /// Spacer before button (extra space for scroll)
                    SizedBox(height: sh(30)),
                  ],
                ),
              ),
            ),

            /// Submit Button - Fixed at bottom (like ProfileScreen)
            Positioned(
              left: sw(30),
              right: sw(30),
              bottom: sh(20),
              child: Obx(() {
                return SizedBox(
                  height: sh(48),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFF003366),
                    ),
                    onPressed: c.isSubmitting.value ? null : () => c.submitRating(),
                    child: c.isSubmitting.value
                        ? SizedBox(
                      width: sw(20),
                      height: sh(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      "Submit",
                      style: FTextTheme.darkTextTheme.titleSmall!.copyWith(
                        fontSize: FTextTheme.darkTextTheme.titleSmall!.fontSize! *
                            screenWidth /
                            baseWidth,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}