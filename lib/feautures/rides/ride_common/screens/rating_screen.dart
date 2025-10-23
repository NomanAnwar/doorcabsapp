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
    final driver = args != null ? DriverModel.fromMap(args) : null;
    final c = Get.put(RatingController());

    final role = StorageService.getRole();

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
            height: screenHeight, // Keep the height for proper positioning
            child: Stack(
              children: [
                /// Back button
                Positioned(
                  top: sh(38),
                  left: sw(20),
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: sw(28),
                      height: sh(28),
                      child: Icon(
                        Icons.arrow_back,
                        size: sw(28),
                      ),
                    ),
                  ),
                ),

                /// Title - Rate your ride/passenger
                Positioned(
                  top: sh(62),
                  left: 0,
                  right: 0,
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

                /// Profile Image
                Positioned(
                  top: sh(124),
                  left: screenWidth * 0.5 - sw(64), // Center calculation
                  child: Container(
                    width: sw(128),
                    height: sh(128),
                    child: ClipOval(
                      child: Image.asset(
                        driver?.avatar ?? 'assets/images/profile_img_sample.png',
                        fit: BoxFit.cover,
                        width: sw(128),
                        height: sh(128),
                      ),
                    ),
                  ),
                ),

                /// Subtitle - Rate your experience
                Positioned(
                  top: sh(290),
                  left: 0,
                  right: 0,
                  child: role == "Driver"
                      ? Text(
                    "Rate Your Experience With Passenger?",
                    style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                      fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                          screenWidth /
                          baseWidth,
                    ),
                    textAlign: TextAlign.center,
                  )
                      : Text(
                    "Rate Your Experience With ${driver?.name ?? 'Driver'}?",
                    style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                      fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                          screenWidth /
                          baseWidth,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                /// Stars Rating
                Positioned(
                  top: sh(327),
                  left: 0,
                  right: 0,
                  child: Obx(() {
                    return Row(
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
                    );
                  }),
                ),

                /// Tags Title - What did you like the most?
                Positioned(
                  top: sh(380),
                  left: 0,
                  right: 0,
                  child: Text(
                    "What did you like the most?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16 * screenWidth / baseWidth,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                /// Tags Chips - Show loading or tags based on API response
                Positioned(
                  top: sh(420),
                  left: sw(10),
                  right: sw(10),
                  child: Obx(() {
                    if (c.isLoading.value) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: sh(20)),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(FColors.primaryColor),
                          ),
                        ),
                      );
                    }

                    return Center(
                      child: Wrap(
                        spacing: sw(8),
                        runSpacing: sh(8),
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
                                color: sel ? Colors.black : Colors.black87,
                              ),
                            );
                          });
                        }).toList(),
                      ),
                    );
                  }),
                ),

                /// Message TextField - Moved higher to avoid keyboard
                Positioned(
                  top: sh(636), // Reduced from 636 to 520
                  left: sw(20),
                  right: sw(20),
                  child: TextField(
                    controller: c.messageController,
                    maxLines: 6,
                    style: TextStyle(
                      fontSize: 14 * screenWidth / baseWidth,
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
                    ),
                  ),
                ),

                /// Submit Button - Moved higher

                Positioned(
                  top: sh(867),
                  left: sw(30),
                  right: sw(30),
                  child: Obx(() {
                    return SizedBox(
                      width: sw(320),
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
        ),
      ),
    );
  }
}