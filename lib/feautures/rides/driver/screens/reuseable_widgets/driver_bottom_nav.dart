import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:doorcab/feautures/rides/driver/screens/go_online_screen.dart';
import 'package:doorcab/feautures/rides/driver/screens/ride_request_list_screen.dart';
import 'package:doorcab/feautures/rides/driver/screens/performance_screen.dart';
import 'package:doorcab/feautures/shared/screens/wallet_screen.dart';

class DriverBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isRequestsListActive;

  const DriverBottomNav({
    Key? key,
    required this.currentIndex,
    this.isRequestsListActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Container(
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
            label: "Home",
            isActive: currentIndex == 0,
            index: 0,
            sw: sw,
            sh: sh,
          ),
          _buildBottomNavItem(
            icon: "assets/images/bottom_sh.svg",
            label: "Schedule Ride",
            isActive: currentIndex == 1,
            index: 1,
            sw: sw,
            sh: sh,
          ),
          _buildBottomNavItem(
            icon: "assets/images/bottom_perf.svg",
            label: "Performance",
            isActive: currentIndex == 2,
            index: 2,
            sw: sw,
            sh: sh,
          ),
          _buildBottomNavItem(
            icon: "assets/images/bottom_wallet.svg",
            label: "Wallet",
            isActive: currentIndex == 3,
            index: 3,
            sw: sw,
            sh: sh,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required String icon,
    required String label,
    required bool isActive,
    required int index,
    required double Function(double) sw,
    required double Function(double) sh,
  }) {
    return GestureDetector(
      onTap: () => _handleNavigation(index),
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
              style: TextStyle(
                fontFamily: "Poppins",
                fontWeight: FontWeight.w500,
                fontSize: sw(12),
                color: isActive ? const Color(0xFF003566) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0: // Home (GoOnlineScreen or RideRequestListScreen)
      // If we're already on a home screen, do nothing
        if (Get.currentRoute != '/go-online' && Get.currentRoute != '/ride-request-list') {
          Get.offAll(() => GoOnlineScreen());
        }
        break;
      case 1: // Schedule Ride
      // Get.offAll(() => ScheduleRideScreen());
        break;
      case 2: // Performance
        if (Get.currentRoute != '/performance') {
          Get.offAll(() => PerformanceScreen());
        }
        break;
      case 3: // Wallet
        if (Get.currentRoute != '/wallet') {
          Get.offAll(() => WalletScreen());
        }
        break;
    }
  }
}