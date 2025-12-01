import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../models/complaint_model.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final ComplaintModel complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final baseWidth = 440.0;
    final baseHeight = 956.0;
    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

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
                  "Complaint Details",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta Sans",
                    fontWeight: FontWeight.w700,
                    fontSize: sw(18),
                    color: const Color(0xFF000000),
                  ),
                ),
              ),

              SizedBox(height: sh(20)),

              // Complainant Info Card - Centered Profile
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Complainant Avatar
                    Container(
                      width: sw(100),
                      height: sw(100),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE8F4F8),
                        ),
                        child: Center(
                          child: Text(
                            complaint.complainantName[0].toUpperCase(),
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

                    // Complainant Name
                    Text(
                      complaint.complainantName,
                      style: TextStyle(
                        fontFamily: "Plus Jakarta Sans",
                        fontWeight: FontWeight.w600,
                        fontSize: sw(14),
                        color: const Color(0xFF000000),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: sh(6)),

                    // User Type
                    Text(
                      complaint.complaintByType,
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
              ),

              SizedBox(height: sh(25)),

              // Scrollable Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Complaint Details Section
                      Text(
                        "Complaint Details",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta Sans",
                          fontWeight: FontWeight.w700,
                          fontSize: sw(16),
                          color: const Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: sh(15)),

                      // Status and Type Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailBox(
                              sw,
                              sh,
                              label: "Status",
                              value: complaint.status,
                              valueColor: _getStatusColor(complaint.status),
                            ),
                          ),
                          SizedBox(width: sw(10)),
                          Expanded(
                            child: _buildDetailBox(
                              sw,
                              sh,
                              label: "Type",
                              value: complaint.type,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: sh(15)),

                      // Category and Date Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailBox(
                              sw,
                              sh,
                              label: "Category",
                              value: complaint.complaintType,
                            ),
                          ),
                          SizedBox(width: sw(10)),
                          Expanded(
                            child: _buildDetailBox(
                              sw,
                              sh,
                              label: "Date",
                              value: complaint.complaintDate,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: sh(20)),

                      // Complaint Description - Same as Submit Screen
                      Text(
                        "Complaint Description",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta Sans",
                          fontWeight: FontWeight.w700,
                          fontSize: sw(16),
                          color: const Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: sh(10)),

                      Container(
                        padding: EdgeInsets.all(sw(16)),
                        width: screenWidth,
                        height: sh(150),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E3E3),
                          borderRadius: BorderRadius.circular(sw(12)),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            complaint.comment.isNotEmpty
                                ? complaint.comment
                                : "No description provided",
                            style: TextStyle(
                              fontFamily: "Plus Jakarta Sans",
                              fontSize: sw(14),
                              color: const Color(0xFF000000),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: sh(20)),

                      // Ride Information
                      Text(
                        "Ride Information",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta Sans",
                          fontWeight: FontWeight.w700,
                          fontSize: sw(16),
                          color: const Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: sh(10)),

                      Container(
                        padding: EdgeInsets.all(sw(16)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E3E3),
                          borderRadius: BorderRadius.circular(sw(12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // _buildInfoRow(
                            //   sw,
                            //   sh,
                            //   label: "Ride ID:",
                            //   value: complaint.rideId,
                            // ),
                            // SizedBox(height: sh(8)),
                            _buildInfoRow(
                              sw,
                              sh,
                              label: "Complaint Against:",
                              value: complaint.complaintForType,
                            ),
                            SizedBox(height: sh(8)),
                            _buildInfoRow(
                              sw,
                              sh,
                              label: "Submitted On:",
                              value: complaint.createdAt,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: sh(25)),

                      // Attachment Section - Same as Submit Screen
                      if (complaint.attachmentUrl != null && complaint.attachmentUrl!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                "Supporting Evidence",
                                style: TextStyle(
                                  fontFamily: "Plus Jakarta Sans",
                                  fontWeight: FontWeight.w700,
                                  fontSize: sw(18),
                                  color: const Color(0xFF000000),
                                ),
                              ),
                            ),
                            SizedBox(height: sh(15)),

                            // Attachment Box - Same dashed border design
                            Container(
                              width: sw(370),
                              height: sh(210),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 0,
                                ),
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
                                      // Show image preview or file icon
                                      if (_isImageFile(complaint.attachmentUrl!)) ...[
                                        Container(
                                          width: sw(120),
                                          height: sh(120),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(sw(8)),
                                            image: DecorationImage(
                                              image: NetworkImage(complaint.attachmentUrl!),
                                              fit: BoxFit.cover,
                                              onError: (exception, stackTrace) {
                                                // Handle image loading error
                                              },
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: sh(10)),
                                        Text(
                                          "Attached Image",
                                          style: TextStyle(
                                            fontFamily: "Plus Jakarta Sans",
                                            fontWeight: FontWeight.w600,
                                            fontSize: sw(15),
                                            color: const Color(0xFF000000),
                                          ),
                                        ),
                                      ] else ...[
                                        Icon(
                                          Icons.insert_drive_file,
                                          size: sw(50),
                                          color: const Color(0xFF0A2C4B),
                                        ),
                                        SizedBox(height: sh(10)),
                                        Text(
                                          "Attached File",
                                          style: TextStyle(
                                            fontFamily: "Plus Jakarta Sans",
                                            fontWeight: FontWeight.w600,
                                            fontSize: sw(15),
                                            color: const Color(0xFF000000),
                                          ),
                                        ),
                                        SizedBox(height: sh(5)),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: sw(20)),
                                          child: Text(
                                            complaint.attachmentUrl!.split('/').last,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: "Plus Jakarta Sans",
                                              fontWeight: FontWeight.w400,
                                              fontSize: sw(12),
                                              color: Colors.black54,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      // SizedBox(height: sh(15)),
                                      // GestureDetector(
                                      //   onTap: () {
                                      //     // Handle viewing attachment
                                      //     Get.snackbar(
                                      //       "Attachment",
                                      //       "Opening attachment...",
                                      //       snackPosition: SnackPosition.BOTTOM,
                                      //     );
                                      //   },
                                      //   child: Container(
                                      //     padding: EdgeInsets.symmetric(
                                      //       horizontal: sw(20),
                                      //       vertical: sh(8),
                                      //     ),
                                      //     decoration: BoxDecoration(
                                      //       color: const Color(0xFFE8E8E8),
                                      //       borderRadius: BorderRadius.circular(sw(8)),
                                      //     ),
                                      //     child: Text(
                                      //       "View Attachment",
                                      //       style: TextStyle(
                                      //         fontFamily: "Plus Jakarta Sans",
                                      //         fontWeight: FontWeight.w500,
                                      //         fontSize: sw(14),
                                      //         color: const Color(0xFF000000),
                                      //       ),
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      SizedBox(height: sh(30)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailBox(
      double Function(double) sw,
      double Function(double) sh, {
        required String label,
        required String value,
        Color? valueColor,
      }) {
    return Container(
      padding: EdgeInsets.all(sw(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E3E3),
        borderRadius: BorderRadius.circular(sw(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: "Plus Jakarta Sans",
              fontWeight: FontWeight.w500,
              fontSize: sw(12),
              color: Colors.black54,
            ),
          ),
          SizedBox(height: sh(4)),
          Text(
            value,
            style: TextStyle(
              fontFamily: "Plus Jakarta Sans",
              fontWeight: FontWeight.w600,
              fontSize: sw(14),
              color: valueColor ?? const Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      double Function(double) sw,
      double Function(double) sh, {
        required String label,
        required String value,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: "Plus Jakarta Sans",
            fontWeight: FontWeight.w600,
            fontSize: sw(14),
            color: Colors.black87,
          ),
        ),
        SizedBox(width: sw(8)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: "Plus Jakarta Sans",
              fontWeight: FontWeight.w400,
              fontSize: sw(14),
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  bool _isImageFile(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains(ext));
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'open':
        return Colors.blue;
      case 'unresolve':
        return Colors.orange;
      case 'closed':
        return Colors.grey;
      default:
        return const Color(0xFF000000);
    }
  }
}

// Custom Painter for Dashed Border (Same as Submit Screen)
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
    for (final PathMetric metric in source.computeMetrics()) {
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