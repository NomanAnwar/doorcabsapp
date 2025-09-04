// lib/features/profile_completion/screens/upload_license_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../../utils/constants/colors.dart';
import '../controllers/upload_license_controller.dart';

class UploadLicenseScreen extends StatelessWidget {
  const UploadLicenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(UploadLicenseController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 60,
            left: 29,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
            ),
          ),
          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Driver License",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Positioned(
            top: 111,
            left: 135,
            child: Text("Upload Front Side"),
          ),
          Obx(() {
            final f = c.frontFile.value;
            return Positioned(
              top: 147,
              left: 53,
              child: GestureDetector(
                onTap: () => c.pickFront(),
                child: DashedBorderContainer(
                  width: 331,
                  height: 196,
                  borderRadius: 8,
                  child: f == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Upload File"),
                      const Text("Take a photo or choose from gallery"),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 130,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F2F2),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => c.pickFront(),
                          child: const Text("Choose File"),
                        ),
                      ),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(f.path),
                      width: 331,
                      height: 196,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          }),

          Obx(() {
            final b = c.backFile.value;
            return Positioned(
              top: 397,
              left: 53,
              child: GestureDetector(
                onTap: () => c.pickBack(),
                child: DashedBorderContainer(
                  width: 331,
                  height: 196,
                  borderRadius: 8,
                  child: b == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Upload File"),
                      const Text("Take a photo or choose from gallery"),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 130,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F2F2),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => c.pickBack(),
                          child: const Text("Choose File"),
                        ),
                      ),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(b.path),
                      width: 331,
                      height: 196,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          }),

          const Positioned(top: 625, left: 36, child: Text("License Number")),
          Positioned(
            top: 665,
            left: 24,
            child: SizedBox(
              width: 393,
              height: 52,
              child: TextField(
                onChanged: (v) => c.licenseNumber.value = v,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE3E3E3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "License number",
                ),
              ),
            ),
          ),
          const Positioned(top: 737, left: 36, child: Text("Expiry Date")),
          Positioned(
            top: 771,
            left: 24,
            child: SizedBox(
              width: 393,
              height: 52,
              child: TextField(
                onChanged: (v) => c.licenseExpiry.value = v,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE3E3E3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "MM-DD-YYYY",
                ),
              ),
            ),
          ),

          Positioned(
            top: 876,
            left: 42,
            child: Obx(
                  () => SizedBox(
                width: 358,
                height: 48,
                child: ElevatedButton(
                  onPressed: c.isLoading.value ? null : c.submitLicense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FColors.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: c.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Dashed Border Container Widget (Same as in upload_cnic_screen.dart)
class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final Color borderColor;
  final double strokeWidth;
  final double dashWidth;
  final double gap;

  const DashedBorderContainer({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.borderColor = Colors.grey,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.gap = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: borderColor,
              strokeWidth: strokeWidth,
              dashWidth: dashWidth,
              gap: gap,
              borderRadius: borderRadius,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double gap;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.gap,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}