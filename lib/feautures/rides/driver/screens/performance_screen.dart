import 'package:doorcab/feautures/rides/driver/screens/reuseable_widgets/driver_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../controllers/performance_controller.dart';

class PerformanceScreen extends StatelessWidget {
  final PerformanceController controller = Get.put(PerformanceController());

  PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Stack(
          children: [
            /// Main Content
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sw(16), vertical: sh(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// App Bar Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Back Arrow
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: SvgPicture.asset(
                          "assets/images/Arrow.svg",
                          width: sw(28),
                          height: sh(28),
                        ),
                      ),

                      /// Title
                      Text(
                        "Performance",
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: sw(18),
                          color: Colors.black,
                        ),
                      ),

                      /// Menu Icon
                      Builder(
                          builder: (context) {
                            return GestureDetector(
                              onTap: () {
                                Scaffold.of(context).openDrawer();
                              },
                              child: Container(
                                width: sw(39),
                                height: sh(39),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(sw(8)),
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    "assets/images/Menu.svg",
                                    width: sw(24),
                                    height: sh(24),
                                  ),
                                ),
                              ),
                            );
                          }
                      ),
                    ],
                  ),

                  SizedBox(height: sh(20)),

                  /// Online Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Online",
                        style: TextStyle(
                          fontFamily: 'Public Sans',
                          fontWeight: FontWeight.w500,
                          fontSize: sw(16),
                          color: Colors.black,
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, sh(-2)),
                        child: Obx(() => Switch(
                          value: controller.isOnline.value,
                          activeColor: Colors.amber,
                          onChanged: controller.toggleOnline,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )),
                      ),
                    ],
                  ),

                  SizedBox(height: sh(20)),

                  /// Performance Content
                  Obx(() {
                    var data = controller.performance.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Total Rides Box
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Rides",
                              style: TextStyle(
                                fontSize: sw(16),
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                fontFamily: 'Public Sans',
                              ),
                            ),
                            SizedBox(height: sh(8)),
                            Container(
                              width: double.infinity,
                              height: sh(52),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(sw(16)),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1.5,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: sw(16)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Rides",
                                    style: TextStyle(
                                      fontSize: sw(16),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Public Sans',
                                    ),
                                  ),
                                  Text(
                                    data.totalRides.toString(),
                                    style: TextStyle(
                                      fontSize: sw(24),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      fontFamily: 'Public Sans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: sh(12)),

                        /// Account Status
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Account Status",
                              style: TextStyle(
                                fontSize: sw(16),
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                fontFamily: 'Public Sans',
                              ),
                            ),
                            SizedBox(height: sh(8)),
                            Container(
                              width: double.infinity,
                              height: sh(52),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(sw(16)),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1.5,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: sw(16)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    data.accountStatus,
                                    style: TextStyle(
                                      fontSize: sw(16),
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                      fontFamily: 'Public Sans',
                                    ),
                                  ),
                                  SvgPicture.asset(
                                    "assets/icons/green_circle.svg",
                                    width: sw(20),
                                    height: sh(20),
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: sh(12)),

                        /// My Reviews
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "My Reviews",
                              style: TextStyle(
                                fontSize: sw(16),
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: sh(8)),
                            GestureDetector(
                              onTap: () {
                                final performanceController = Get.find<PerformanceController>();
                                Get.toNamed('/reviews', arguments: {
                                  'rating': performanceController.performance.value.rating,
                                  'reviewCount': performanceController.performance.value.reviewCount,
                                });
                              },
                              child: Obx(() {
                                final data = controller.performance.value;
                                return Container(
                                  width: double.infinity,
                                  height: sh(52),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(sw(16)),
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: sw(16)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(width: sw(6)),
                                          Text(
                                            "${data.rating.toStringAsFixed(1)} (${data.reviewCount} Reviews)",
                                            style: TextStyle(
                                              fontSize: sw(16),
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SvgPicture.asset(
                                        'assets/icons/Rarrow.svg',
                                        width: sw(24),
                                        height: sh(24),
                                        colorFilter: ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                                      )
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),

                        SizedBox(height: sh(20)),

                        /// My Status Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: sw(4), bottom: sh(8)),
                              child: Text(
                                "My Status",
                                style: TextStyle(
                                  fontSize: sw(16),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  fontFamily: 'Public Sans',
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildFixedCard(
                                    "Acceptance Rate",
                                    "${data.acceptanceRate.toStringAsFixed(0)}%",
                                    color: Colors.green,
                                    sw: sw,
                                    sh: sh,
                                  ),
                                ),
                                SizedBox(width: sw(12)),
                                Expanded(
                                  child: _buildFixedCard(
                                    "Cancellation Rate",
                                    "${data.cancellationRate.toStringAsFixed(0)}%",
                                    color: Colors.red,
                                    sw: sw,
                                    sh: sh,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: sh(20)),

                        /// Earnings Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: sw(1)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        "Earnings",
                                        style: TextStyle(
                                          fontSize: sw(16),
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        "Wallet Balance",
                                        style: TextStyle(
                                          fontSize: sw(16),
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        "Earned Bonus",
                                        style: TextStyle(
                                          fontSize: sw(16),
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: sh(8)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: _buildSquareCard(
                                      "Earnings",
                                      "PKR ${data.earnings}",
                                      sw: sw,
                                      sh: sh,
                                    ),
                                  ),
                                ),
                                SizedBox(width: sw(8)),
                                Expanded(
                                  child: Center(
                                    child: _buildSquareCard(
                                      "Wallet Balance",
                                      "PKR ${data.walletBalance}",
                                      sw: sw,
                                      sh: sh,
                                    ),
                                  ),
                                ),
                                SizedBox(width: sw(8)),
                                Expanded(
                                  child: Center(
                                    child: _buildSquareCard(
                                      "Earned Bonus",
                                      "PKR ${data.bonus}",
                                      sw: sw,
                                      sh: sh,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: sh(20)),

                        /// Achievements
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Achievements",
                              style: TextStyle(
                                fontFamily: 'Public Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: sw(16),
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: sh(8)),
                            _buildRow(
                              "",
                              data.achievement,
                              svgIconPath: "assets/icons/achivement.svg",
                              sw: sw,
                              sh: sh,
                            ),
                          ],
                        ),

                        SizedBox(height: sh(12)),

                        /// Account Health
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Account Health",
                              style: TextStyle(
                                fontFamily: 'Public Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: sw(16),
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: sh(8)),
                            _buildRow(
                              "",
                              data.accountHealth,
                              svgIconPath: "assets/icons/heart.svg",
                              sw: sw,
                              sh: sh,
                            ),
                          ],
                        ),

                        SizedBox(height: sh(80)), // Space for bottom navigation
                      ],
                    );
                  }),
                ],
              ),
            ),

            /// Custom Bottom Navigation Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DriverBottomNav(
                currentIndex: 2, // Performance is active
                isRequestsListActive: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedCard(String title, String value, {
    required Color color,
    required double Function(double) sw,
    required double Function(double) sh,
  }) {
    return Container(
      width: sw(179),
      height: sh(85),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(sw(14)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: sw(14),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sh(4)),
          Text(
            value,
            style: TextStyle(
              fontSize: sw(26),
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String title, String value, {
    String? svgIconPath,
    required double Function(double) sw,
    required double Function(double) sh,
  }) {
    return Container(
      width: double.infinity,
      height: sh(52),
      padding: EdgeInsets.symmetric(horizontal: sw(16)),
      margin: EdgeInsets.symmetric(vertical: sh(6)),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(sw(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: sw(15),
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          if (svgIconPath != null)
            SvgPicture.asset(
              svgIconPath,
              width: sw(22),
              height: sh(22),
            ),
        ],
      ),
    );
  }

  Widget _buildSquareCard(String title, String value, {
    Color? color,
    required double Function(double) sw,
    required double Function(double) sh,
  }) {
    return Container(
      width: sw(125),
      height: sh(125),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(sw(14)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: sw(14),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sh(8)),
          Text(
            value,
            style: TextStyle(
              fontSize: sw(16),
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}