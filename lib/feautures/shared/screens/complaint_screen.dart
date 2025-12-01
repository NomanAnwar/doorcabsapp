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

    final baseWidth = 440.0;
    final baseHeight = 956.0;
    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    final ComplaintController controller = Get.put(ComplaintController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              /// White Background Container
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white,
                ),
              ),

              /// Back Arrow
              Positioned(
                top: sh(23),
                left: sw(20),
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: SvgPicture.asset(
                    "assets/images/Arrow.svg",
                    width: sw(28),
                    height: sh(28),
                  ),
                ),
              ),

              /// Title
              Positioned(
                top: sh(23),
                left: 0,
                right: 0,
                child: Center(
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
              ),

              /// Submitted Complaints Section
              Positioned(
                top: sh(80),
                left: sw(25),
                child: Text(
                  "Submitted Complaints",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta Sans",
                    fontWeight: FontWeight.w700,
                    fontSize: sw(22),
                    color: const Color(0xFF000000),
                  ),
                ),
              ),

              /// Complaints List
              Positioned(
                top: sh(130),
                left: sw(25),
                right: sw(25),
                bottom: sh(20),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.blue,
                          ),
                          SizedBox(height: sh(16)),
                          Text(
                            "Loading complaints...",
                            style: TextStyle(
                              fontFamily: "Plus Jakarta Sans",
                              fontSize: sw(16),
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.hasError.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_empty_outlined,
                            size: sw(48),
                            color: Colors.red,
                          ),
                          SizedBox(height: sh(16)),
                          Text(
                            "No Submitted Complaints Yet",
                            style: TextStyle(
                              fontFamily: "Plus Jakarta Sans",
                              fontSize: sw(16),
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: sh(16)),
                          ElevatedButton(
                            onPressed: controller.retryFetchComplaints,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              "Retry",
                              style: TextStyle(
                                fontFamily: "Plus Jakarta Sans",
                                fontSize: sw(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.complaintsList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: sw(64),
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: sh(16)),
                          Text(
                            "No complaints submitted yet",
                            style: TextStyle(
                              fontFamily: "Plus Jakarta Sans",
                              fontSize: sw(16),
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: sh(8)),
                          Text(
                            "Your submitted complaints will appear here",
                            style: TextStyle(
                              fontFamily: "Plus Jakarta Sans",
                              fontSize: sw(14),
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
                        issue: complaint.comment,
                        complaint_type: complaint.type,
                        onTap: () => controller.viewComplaintDetails(complaint),
                      );
                    },
                  );
                }),
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
        required String complaint_type,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Status : $status",
                          // "Status : $complaint_type".toUpperCase(),
                          style: TextStyle(
                            fontFamily: "Plus Jakarta Sans",
                            fontWeight: FontWeight.w500,
                            fontSize: sw(16),
                            color: Colors.black,
                          ),
                        ),
                      ),
                      // Text(
                      //   "$status".toUpperCase(),
                      //   style: TextStyle(
                      //     fontFamily: "Plus Jakarta Sans",
                      //     fontWeight: FontWeight.w500,
                      //     fontSize: sw(16),
                      //     color: Colors.black,
                      //   ),
                      // ),
                    ],
                  ),
                  SizedBox(height: sh(4)),
                  Text(
                    "Issue: $complaint_type",
                    // "Issue: $issue",
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