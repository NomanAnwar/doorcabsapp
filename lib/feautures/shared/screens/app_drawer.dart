import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:doorcab/feautures/rides/driver/screens/go_online_screen.dart';
import 'package:doorcab/feautures/shared/screens/privacy_policy.dart';
import 'package:doorcab/feautures/shared/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../rides/passenger/screens/ride_history_screen.dart';
import '../../shared/services/storage_service.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/theme/custom_theme/text_theme.dart';
import 'change_city_screen.dart';
import 'invite_screen.dart';
import 'notification_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base reference (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    // ✅ FIX: Safe data extraction with null checks
    Map<String, dynamic>? profileData = StorageService.getProfile();

    String firstName = '';
    String lastName = '';
    String fullName = 'User';
    String profileImage = '';
    String userRole = 'Passenger';

    if (profileData != null) {
      try {
        firstName = profileData['name']?['firstName']?.toString() ?? '';
        lastName = profileData['name']?['lastName']?.toString() ?? '';
        fullName = '$firstName $lastName'.trim();
        profileImage = profileData['Profile_Image']?.toString() ?? '';
        userRole = profileData['role']?.toString() ?? 'Passenger';
      } catch (e) {
        print('❌ Error parsing profile data: $e');
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      width: screenWidth,
      child: Drawer(
        elevation: 8,
        width: screenWidth,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: sh(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  name: fullName.toUpperCase(),
                  profilePath: profileImage,
                  sw: sw,
                  sh: sh,
                  screenWidth: screenWidth,
                  baseWidth: baseWidth,
                ),
                SizedBox(height: sh(20)),
                ...(
                    userRole == 'Driver'
                        ? _driverMenu(sw, sh, screenWidth, baseWidth)
                        : _passengerMenu(sw, sh, screenWidth, baseWidth)
                ),
                SizedBox(height: sh(20)),
                _bottomButton(
                  text: userRole == 'Driver'
                      ? 'Invite a Friend & Get 20% Bonus'
                      : 'Partner as a Driver',
                  sw: sw,
                  sh: sh,
                  screenWidth: screenWidth,
                  baseWidth: baseWidth,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Drawer Header
  Widget _buildHeader({
    required String name,
    required String profilePath,
    required double Function(double) sw,
    required double Function(double) sh,
    required double screenWidth,
    required double baseWidth,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sw(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟢 Top menu icon
          Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Get.back();
              },
              child: SvgPicture.asset(
                'assets/drawer/menu.svg',
                width: sw(28),
                height: sh(28),
              ),
            ),
          ),
          SizedBox(height: sh(20)),
          Row(
            children: [
              // ✅ FIX: Handle both network and asset images
              CircleAvatar(
                radius: sw(40),
                backgroundColor: Colors.grey[300],
                backgroundImage: profilePath.isNotEmpty && profilePath.startsWith('http')
                    ? NetworkImage(profilePath) as ImageProvider
                    : AssetImage(profilePath.isEmpty
                    ? 'assets/drawer/passenger.png'
                    : profilePath),
              ),
              SizedBox(width: sw(12)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                          screenWidth /
                          baseWidth,
                    ),
                  ),
                  SizedBox(height: sh(4)),
                  Text(
                    "View profile",
                    style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                      color: Colors.grey[600],
                      fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                          screenWidth /
                          baseWidth,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Drawer Item
  Widget _drawerItem(
      String svgPath,
      String title,
      VoidCallback onTap,
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sw(15), vertical: sh(1)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(sw(10)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: sw(8), vertical: sh(6)),
          child: Row(
            children: [
              Container(
                width: sw(52),
                height: sh(52),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(sw(12)),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    svgPath,
                    width: sw(50),
                    height: sh(40),
                  ),
                ),
              ),
              SizedBox(width: sw(12)),
              Expanded(
                child: Text(
                  title,
                  style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                    fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Driver Drawer Menu
  List<Widget> _driverMenu(
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return [
      _drawerItem('assets/drawer/car.svg', 'Home', () {
        Get.back();
        Get.to(() => GoOnlineScreen());
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/courier.svg', 'Couriers', () {
        FSnackbar.show(title: "Not Added", message: 'Courier Service Will be Added Soon.');
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/freight.svg', 'Freight', () {
        FSnackbar.show(title: "Not Added", message: 'Freight Service Will be Added Soon.');
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/bonus.svg', 'Bonuses', () {
        FSnackbar.show(title: "Not Added", message: 'Bonuses Will be Added Soon.');
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/changecity.svg', 'Change City', () {
        Get.to(() => ChangeCityScreen());
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/notifications.svg', 'Notifications', () {
        Get.to(() => NotificationScreen());
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/privacy.svg', 'Privacy Policy', () {
        Get.to(() => PrivacyPolicyScreen());
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/settings.svg', 'Settings', () {
        Get.to(() => SettingsScreen());
      }, sw, sh, screenWidth, baseWidth),
    ];
  }

  // Passenger Drawer Menu
  List<Widget> _passengerMenu(
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return [
      _drawerItem('assets/drawer/car.svg', 'My Rides History', () {
        Get.to(() => RideHistoryScreen());
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/courier.svg', 'Couriers', () {
        FSnackbar.show(title: "Not Added", message: 'Courier Service Will be Added Soon.');
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/freight.svg', 'Freight', () {
        FSnackbar.show(title: "Not Added", message: 'Freight Service Will be Added Soon.');
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/citytocity.svg', 'City to City', () {
        // Get.to(() => RideSelectionView());
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/notifications.svg', 'Notifications', () {
        // Get.back();
        Get.to(() => NotificationScreen());
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/privacy.svg', 'Privacy Policy', () {
        Get.to(() => PrivacyPolicyScreen());
      }, sw, sh, screenWidth, baseWidth),
      _drawerItem('assets/drawer/settings.svg', 'Settings', () {
        Get.to(() => SettingsScreen(),);
      }, sw, sh, screenWidth, baseWidth),
    ];
  }

  // Bottom Button — right below Settings
  Widget _bottomButton({
    required String text,
    required double Function(double) sw,
    required double Function(double) sh,
    required double screenWidth,
    required double baseWidth,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: sw(29),
        right: sw(39),
        top: sh(5),
      ),
      child: InkWell(
        onTap: () {
          Get.to(() => InviteScreen());
        },
        borderRadius: BorderRadius.circular(sw(10)),
        child: Container(
          width: sw(361),
          height: sh(48),
          decoration: BoxDecoration(
            color: const Color(0xFF002B5B),
            borderRadius: BorderRadius.circular(sw(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: sw(16)),
              SvgPicture.asset(
                'assets/drawer/partner.svg',
                width: sw(28),
                height: sh(28),
              ),
              SizedBox(width: sw(12)),
              Expanded(
                child: Text(
                  text,
                  style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                    color: Colors.white,
                    fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}