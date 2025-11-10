import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import '../controllers/complaint_controller.dart';

class SubmitComplaintScreen extends StatelessWidget {
  const SubmitComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;
    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    final ComplaintController controller = Get.find<ComplaintController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sw(25), vertical: sh(25)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Arrow
              GestureDetector(
                onTap: () => Get.back(),
                child: SvgPicture.asset(
                  "assets/images/Arrow.svg",
                  width: sw(28),
                  height: sh(28),
                ),
              ),
              SizedBox(height: sh(5)),

              // Title
              Center(
                child: Text(
                  "Submit Complaint",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta Sans",
                    fontWeight: FontWeight.w700,
                    fontSize: sw(18),
                    color: const Color(0xFF000000),
                  ),
                ),
              ),

              SizedBox(height: sh(20)),

              // Driver Info Card - Centered Profile
              Obx(() {
                final driver = controller.driverInfo.value;
                if (driver == null) return const SizedBox.shrink();

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Driver Avatar
                      Container(
                        width: sw(100),
                        height: sw(100),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: driver.imageUrl != null
                            ? ClipOval(
                          child: Image.network(
                            driver.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFE8F4F8),
                                ),
                                child: Center(
                                  child: Text(
                                    driver.name[0].toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: "Plus Jakarta Sans",
                                      fontWeight: FontWeight.w700,
                                      fontSize: sw(36),
                                      color: const Color(0xFF0A2C4B),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                            : Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE8F4F8),
                          ),
                          child: Center(
                            child: Text(
                              driver.name[0].toUpperCase(),
                              style: TextStyle(
                                fontFamily: "Plus Jakarta Sans",
                                fontWeight: FontWeight.w700,
                                fontSize: sw(36),
                                color: const Color(0xFF0A2C4B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: sh(16)),

                      // Driver Name
                      Text(
                        driver.name,
                        style: TextStyle(
                          fontFamily: "Plus Jakarta Sans",
                          fontWeight: FontWeight.w600,
                          fontSize: sw(14),
                          color: const Color(0xFF000000),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: sh(6)),

                      // Rating and rides
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star,
                            color: const Color(0xFFFFA000),
                            size: sw(14),
                          ),
                          SizedBox(width: sw(4)),
                          Text(
                            "${driver.rating} (${driver.totalRides} rides)",
                            style: TextStyle(
                              fontFamily: "Plus Jakarta Sans",
                              fontWeight: FontWeight.w400,
                              fontSize: sw(8),
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: sh(6)),

                      // Driver Role
                      Text(
                        driver.role,
                        style: TextStyle(
                          fontFamily: "Plus Jakarta Sans",
                          fontWeight: FontWeight.w400,
                          fontSize: sw(10),
                          color: const Color(0xFF0A2C4B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: sh(25)),

              // Scrollable Form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Complaint Description - Updated Background Color
                      Container(
                        padding: EdgeInsets.all(sw(16)),
                        height: sh(150),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E3E3), // Updated color
                          borderRadius: BorderRadius.circular(sw(12)),
                        ),
                        child: TextField(
                          onChanged: (value) => controller.updateDescription(value),
                          maxLines: null,
                          expands: true,
                          style: TextStyle(
                            fontFamily: "Plus Jakarta Sans",
                            fontSize: sw(14),
                            color: const Color(0xFF000000),
                          ),
                          decoration: InputDecoration(
                            hintText: "Describe your complaint",
                            hintStyle: TextStyle(
                              fontFamily: "Plus Jakarta Sans",
                              fontSize: sw(14),
                              color: Colors.black38,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      SizedBox(height: sh(20)),

                      // Category Dropdown - Updated Background Color & Icon
                      Obx(() => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: sw(16),
                          vertical: sh(4),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E3E3), // Updated color
                          borderRadius: BorderRadius.circular(sw(12)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: Text(
                              "Select a category",
                              style: TextStyle(
                                fontFamily: "Plus Jakarta Sans",
                                fontSize: sw(14),
                                color: Colors.black38,
                              ),
                            ),
                            value: controller.selectedCategory.value.isEmpty
                                ? null
                                : controller.selectedCategory.value,
                            // Custom up/down arrow icon
                            icon: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/Dashboard/up.svg',
                                ),
                                SizedBox(height: sh(3)), // small spacing if you want
                                SvgPicture.asset(
                                  'assets/Dashboard/down.svg',
                                ),
                              ],
                            ),

                            items: controller.categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontFamily: "Plus Jakarta Sans",
                                    fontSize: sw(14),
                                    color: const Color(0xFF000000),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                controller.updateCategory(value);
                              }
                            },
                          ),
                        ),
                      )),

                      SizedBox(height: sh(25)),

                      // Upload Files Section
                      // Upload Files Section - Centered Title
                      Center(
                        child: Text(
                          "Upload Supporting Evidence (Optional)",
                          style: TextStyle(
                            fontFamily: "Plus Jakarta Sans",
                            fontWeight: FontWeight.w700,
                            fontSize: sw(18),
                            color: const Color(0xFF000000),
                          ),
                        ),
                      ),

                      SizedBox(height: sh(15)),

// Upload Box - Fixed dimensions with dashed border
                      GestureDetector(
                        onTap: () => controller.uploadFiles(),
                        child: Obx(() => Container(
                          width: sw(370),
                          height: sh(210),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.transparent,
                              width: 0,
                            ),
                            // borderRadius: BorderRadius.circular(sw(12)),
                          ),
                          child: CustomPaint(
                            painter: DashedBorderPainter(
                              color: const Color(0xFFE0E0E0),
                              strokeWidth: 1,
                              dashWidth: sw(5),
                              dashSpace: sw(5),
                              borderRadius: sw(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (controller.uploadedFiles.isEmpty) ...[
                                    Text(
                                      "Upload Files",
                                      style: TextStyle(
                                        fontFamily: "Plus Jakarta Sans",
                                        fontWeight: FontWeight.w600,
                                        fontSize: sw(15),
                                        color: const Color(0xFF000000),
                                      ),
                                    ),
                                    SizedBox(height: sh(4)),
                                    Text(
                                      "Add screenshots or videos to help us\nunderstand the issue better.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: "Plus Jakarta Sans",
                                        fontWeight: FontWeight.w400,
                                        fontSize: sw(12),
                                        color: Colors.black54,
                                      ),
                                    ),
                                    SizedBox(height: sh(15)),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: sw(20),
                                        vertical: sh(8),
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8E8E8),
                                        borderRadius: BorderRadius.circular(sw(8)),
                                      ),
                                      child: Text(
                                        "Choose Files",
                                        style: TextStyle(
                                          fontFamily: "Plus Jakarta Sans",
                                          fontWeight: FontWeight.w500,
                                          fontSize: sw(14),
                                          color: const Color(0xFF000000),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    // Show uploaded files
                                    Expanded(
                                      child: ListView(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.symmetric(horizontal: sw(16)),
                                        children: controller.uploadedFiles.map((file) {
                                          return Padding(
                                            padding: EdgeInsets.symmetric(vertical: sh(4)),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.insert_drive_file,
                                                  size: sw(20),
                                                  color: const Color(0xFF0A2C4B),
                                                ),
                                                SizedBox(width: sw(8)),
                                                Expanded(
                                                  child: Text(
                                                    file.split('/').last,
                                                    style: TextStyle(
                                                      fontFamily: "Plus Jakarta Sans",
                                                      fontSize: sw(13),
                                                      color: const Color(0xFF000000),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => controller.removeFile(file),
                                                  child: Icon(
                                                    Icons.close,
                                                    size: sw(18),
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    SizedBox(height: sh(10)),
                                    Text(
                                      "Tap to add more files",
                                      style: TextStyle(
                                        fontFamily: "Plus Jakarta Sans",
                                        fontSize: sw(12),
                                        color: Colors.black54,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )),
                      ),

                      SizedBox(height: sh(30)),
                    ],
                  ),
                ),
              ),

              // Submit Button
              Obx(() => GestureDetector(
                onTap: controller.isSubmitting.value
                    ? null
                    : () => controller.submitComplaint(),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: sh(16)),
                  decoration: BoxDecoration(
                    color: controller.isSubmitting.value
                        ? const Color(0xFF0A2C4B).withOpacity(0.5)
                        : const Color(0xFF0A2C4B),
                    borderRadius: BorderRadius.circular(sw(14)),
                  ),
                  child: Center(
                    child: controller.isSubmitting.value
                        ? SizedBox(
                      width: sw(20),
                      height: sw(20),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      "Submit",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta Sans",
                        fontWeight: FontWeight.w500,
                        fontSize: sw(16),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Dashed Border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    final Path dest = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double length = draw ? dashWidth : dashSpace;
        final double end = distance + length;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, end),
            Offset.zero,
          );
        }
        distance = end;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashWidth != oldDelegate.dashWidth ||
        dashSpace != oldDelegate.dashSpace ||
        borderRadius != oldDelegate.borderRadius;
  }
}