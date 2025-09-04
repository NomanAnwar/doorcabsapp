// lib/features/profile_completion/screens/upload_cnic_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../../utils/constants/colors.dart';
import '../controllers/upload_cnic_controller.dart';

class UploadCnicScreen extends StatelessWidget {
  const UploadCnicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(UploadCnicController());

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
                "CNIC upload",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Positioned(
            top: 98,
            left: 40,
            child: Text(
              "Enter CNIC number",
              style: FTextTheme.lightTextTheme.bodyLarge,
            ),
          ),
          Positioned(
            top: 125,
            left: 24,
            child: SizedBox(
              width: 393,
              height: 52,
              child: TextField(
                keyboardType: TextInputType.number,
                onChanged: (v) => c.cnicNumber.value = v,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE3E3E3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "42101-1234567-1",
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Front label + container
          const Positioned(
            top: 213,
            left: 112,
            child: Text("Upload CNIC Front Side"),
          ),
          Obx(() {
            final f = c.frontFile.value;
            return Positioned(
              top: 249,
              left: 53,
              child: GestureDetector(
                onTap: () async => await c.pickFront(),
                child: DashedBorderContainer(
                  width: 331,
                  height: 196,
                  borderRadius: 8,
                  child:
                      f == null
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Upload File",
                                style: FTextTheme.lightTextTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
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

          // Back side
          const Positioned(
            top: 482,
            left: 112,
            child: Text("Upload CNIC Back Side"),
          ),
          Obx(() {
            final b = c.backFile.value;
            return Positioned(
              top: 518,
              left: 53,
              child: GestureDetector(
                onTap: () async => await c.pickBack(),
                child: DashedBorderContainer(
                  width: 331,
                  height: 196,
                  borderRadius: 8,
                  child:
                      b == null
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Upload File",
                                style: FTextTheme.lightTextTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
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

          // Submit
          Positioned(
            top: 876,
            left: 42,
            child: Obx(
              () => SizedBox(
                width: 358,
                height: 48,
                child: ElevatedButton(
                  onPressed: c.isLoading.value ? null : c.submitCnic,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FColors.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      c.isLoading.value
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

// Custom Dashed Border Container Widget
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
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            Radius.circular(borderRadius),
          ),
        );

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
