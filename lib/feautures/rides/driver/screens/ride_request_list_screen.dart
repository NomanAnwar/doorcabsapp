import 'package:doorcab/feautures/rides/driver/screens/reuseable_widgets/drawer.dart';
import 'package:doorcab/feautures/rides/driver/screens/reuseable_widgets/request_card.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/ride_request_list_controller.dart';

class RideRequestListScreen extends StatelessWidget {
  const RideRequestListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RideRequestListController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      drawer: const DriverDrawer(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() => Stack(
          children: [
            /// Main UI
            SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: Stack(
                children: [
                  // Drawer icon
                  Positioned(
                    top: sh(37.1),
                    left: sw(33.85),
                    child: Builder(
                      builder: (ctx) => GestureDetector(
                        onTap: () => Scaffold.of(ctx).openDrawer(),
                        child: Container(
                          width: sw(45),
                          height: sh(45),
                          color: Colors.transparent,
                          child: Image.asset(
                            "assets/images/drawer_icon.png",
                            fit: BoxFit.cover,
                            width: sw(39),
                            height: sh(39),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Title
                  Positioned(
                    top: sh(37.1),
                    left: sw(25),
                    width: sw(390),
                    child: Text(
                      'Driver Dashboard',
                      textAlign: TextAlign.center,
                      style: FTextTheme.lightTextTheme.headlineSmall!.copyWith(
                        fontSize: FTextTheme.lightTextTheme.headlineSmall!.fontSize! *
                            screenWidth /
                            baseWidth,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Settings
                  Positioned(
                    top: sh(37.1),
                    left: sw(389),
                    child: Icon(
                      Icons.settings,
                      size: sw(24),
                      color: FColors.black,
                    ),
                  ),

                  // Online status
                  Positioned(
                    top: sh(100),
                    left: sw(33),
                    child: Text(
                      'Online',
                      style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                        fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                            screenWidth /
                            baseWidth,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Toggle
                  Positioned(
                    top: sh(80),
                    left: sw(362),
                    child: Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        padding: EdgeInsets.zero,
                        activeColor: FColors.primaryColor,
                        inactiveThumbColor: FColors.secondaryColor,
                        inactiveTrackColor: FColors.white,
                        value: c.isOnline.value,
                        onChanged: c.isLoadingToggle.value ? null : c.toggleOnline, // Disable when loading
                      ),
                    ),
                  ),

                  // Requests list
                  Positioned(
                    top: sh(157),
                    left: sw(10),
                    right: sw(10),
                    bottom: sh(64), // Adjusted for custom bottom nav bar
                    child: Obx(() {
                      if (c.requests.isEmpty) {
                        return Center(
                          child: Text(
                            'No requests at the moment',
                            style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                              fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: c.requests.length,
                        itemBuilder: (context, index) {
                          final r = c.requests[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: sh(10)),
                            child: RequestCard(
                              request: r,
                              onTapCard: () => c.acceptRequest(r),
                              onOfferPressed: () => c.acceptRequest(r),
                              sw: sw,
                              sh: sh,
                            ),
                          );
                        },
                      );
                    }),
                  ),

                  /// Custom Bottom Navigation Bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      height: sh(70),
                      padding: EdgeInsets.symmetric(horizontal: sw(10)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: sw(10),
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBottomNavItem(
                            icon: "assets/images/bottom_car.svg",
                            label: "Requests List",
                            isActive: true,
                            sw: sw,
                            sh: sh,
                            screenWidth: screenWidth,
                            baseWidth: baseWidth,
                          ),
                          _buildBottomNavItem(
                            icon: "assets/images/bottom_sh.svg",
                            label: "Schedule Ride",
                            isActive: false,
                            sw: sw,
                            sh: sh,
                            screenWidth: screenWidth,
                            baseWidth: baseWidth,
                          ),
                          _buildBottomNavItem(
                            icon: "assets/images/bottom_perf.svg",
                            label: "Performance",
                            isActive: false,
                            sw: sw,
                            sh: sh,
                            screenWidth: screenWidth,
                            baseWidth: baseWidth,
                          ),
                          _buildBottomNavItem(
                            icon: "assets/images/bottom_wallet.svg",
                            label: "Wallet",
                            isActive: false,
                            sw: sw,
                            sh: sh,
                            screenWidth: screenWidth,
                            baseWidth: baseWidth,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Loading Overlay
            if (c.isLoadingToggle.value)
              Container(
                height: screenHeight,
                width: screenWidth,
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: sw(2),
                  ),
                ),
              ),
          ],
        )),
      ),
    );
  }

  /// Bottom Navigation Item Widget
  Widget _buildBottomNavItem({
    required String icon,
    required String label,
    required bool isActive,
    required double Function(double) sw,
    required double Function(double) sh,
    required double screenWidth,
    required double baseWidth,
  }) {
    return GestureDetector(
      onTap: () {
        // Add navigation logic here
        if (label == "Requests List") {
          // Get.to(() => RequestsListScreen());
        } else if (label == "Schedule Ride") {
          // Get.to(() => ScheduleRideScreen());
        } else if (label == "Performance") {
          // Get.to(() => PerformanceScreen());
        } else if (label == "Wallet") {
          // Get.to(() => WalletScreen());
        }
      },
      child: Container(
        width: sw(100),
        height: sh(70),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: sw(24),
              height: sh(24),
              color: isActive ? const Color(0xFF003566) : Colors.grey,
            ),
            SizedBox(height: sh(4)),
            Text(
              label,
              style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                    screenWidth /
                    baseWidth,
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF003566) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}