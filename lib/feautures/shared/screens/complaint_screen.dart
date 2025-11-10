import 'package:doorcab/feautures/shared/screens/submit_complaint_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../controllers/complaint_controller.dart';

class ComplaintsListScreen extends StatelessWidget {
  const ComplaintsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;
    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    final ComplaintController controller = Get.put(ComplaintController());

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
                  "Complaint / Disputes",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta Sans",
                    fontWeight: FontWeight.w700,
                    fontSize: sw(18),
                    color: const Color(0xFF000000),
                  ),
                ),
              ),

              SizedBox(height: sh(50)),

              // Submitted Complaints Section
              Text(
                "Submitted Complaints",
                style: TextStyle(
                  fontFamily: "Plus Jakarta Sans",
                  fontWeight: FontWeight.w700,
                  fontSize: sw(22),
                  color: const Color(0xFF000000),
                ),
              ),

              SizedBox(height: sh(15)),

              // Complaints List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.complaintsList.isEmpty) {
                    return Center(
                      child: Text(
                        "No complaints submitted yet",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta Sans",
                          fontSize: sw(16),
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.complaintsList.length,
                    itemBuilder: (context, index) {
                      final complaint = controller.complaintsList[index];
                      return _complaintCard(
                        sw,
                        sh,
                        status: complaint.status,
                        issue: complaint.issue,
                        onTap: () => controller.viewComplaintDetails(complaint),
                      );
                    },
                  );
                }),
              ),

              SizedBox(height: sh(20)),

              GestureDetector(
                onTap: () => Get.to(() => const SubmitComplaintScreen()),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: sh(16)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2C4B),
                    borderRadius: BorderRadius.circular(sw(10)),
                  ),
                  child: Center(
                    child: Text(
                      "Submit New Complaint",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta Sans",
                        fontWeight: FontWeight.w500,
                        fontSize: sw(16),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _complaintCard(
      double Function(double) sw,
      double Function(double) sh, {
        required String status,
        required String issue,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: sh(10)),
        padding: EdgeInsets.symmetric(
          horizontal: sw(5),
          vertical: sh(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Status: $status",
                    style: TextStyle(
                      fontFamily: "Plus Jakarta Sans",
                      fontWeight: FontWeight.w500,
                      fontSize: sw(16),
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: sh(4)),
                  Text(
                    "Issue: $issue",
                    style: TextStyle(
                      fontFamily: "Plus Jakarta Sans",
                      fontWeight: FontWeight.w400,
                      fontSize: sw(14),
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            SvgPicture.asset(
              "assets/Dashboard/arrows.svg",
            ),
          ],
        ),
      ),
    );
  }
}
