import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';

import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import '../services/storage_service.dart';

class NotificationScreen extends StatelessWidget {
  final NotificationController controller = Get.put(NotificationController());

  NotificationScreen({super.key});

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
        child: Column(
          children: [
            /// -------------------- APP BAR SECTION --------------------
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: sw(20),
                vertical: sh(12),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: SvgPicture.asset(
                    "assets/images/Arrow.svg",
                    width: sw(22),
                    height: sh(22),
                  ),
                ),
              ),
            ),

            /// Title (separate line centered)
            Padding(
              padding: EdgeInsets.only(bottom: sh(25)),
              child: Text(
                "Notifications",
                textAlign: TextAlign.center,
                style: FTextTheme.lightTextTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: FTextTheme.lightTextTheme.titleLarge!.fontSize! *
                      screenWidth /
                      baseWidth,
                  color: Colors.black,
                ),
              ),
            ),

            /// -------------------- NOTIFICATION LIST + TOGGLE --------------------
            Expanded(
              child: Obx(() {
                // Get user role and load appropriate notifications
                final userRole = StorageService.getRole();
                controller.loadNotificationsForRole(userRole!);

                if (controller.notifications.isEmpty) {
                  return _buildEmptyState(sw, sh, screenWidth, baseWidth);
                }

                // Check if we should show grouped layout (for driver) or simple list (for passenger)
                if (userRole == 'Driver') {
                  return _buildDriverLayout(sw, sh, screenWidth, baseWidth);
                } else {
                  return _buildPassengerLayout(sw, sh, screenWidth, baseWidth);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------- DRIVER LAYOUT --------------------
  Widget _buildDriverLayout(
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: sw(20)),
      children: [
        // Today Section
        Padding(
          padding: EdgeInsets.only(
            top: sh(8),
            bottom: sh(16),
          ),
          child: Text(
            "Today",
            style: TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.w600,
              fontSize: sw(18),
              color: Colors.black,
            ),
          ),
        ),

        // Today's notifications (first 3 items)
        ...controller.notifications.take(3).map((notification) =>
            _buildDriverNotificationItem(
              notification: notification,
              sw: sw,
              sh: sh,
            ),
        ).toList(),

        // Yesterday Section
        Padding(
          padding: EdgeInsets.only(
            top: sh(24),
            bottom: sh(16),
          ),
          child: Text(
            "Yesterday",
            style: TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.w600,
              fontSize: sw(18),
              color: Colors.black,
            ),
          ),
        ),

        // Yesterday's notifications (next 2 items)
        ...controller.notifications.skip(3).take(2).map((notification) =>
            _buildDriverNotificationItem(
              notification: notification,
              sw: sw,
              sh: sh,
            ),
        ).toList(),

        /// -------------------- TOGGLE SWITCH SECTION --------------------
        _buildToggleSection(sw, sh, screenWidth, baseWidth),
      ],
    );
  }

  /// -------------------- PASSENGER LAYOUT --------------------
  Widget _buildPassengerLayout(
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Notification items (using your original ListView.builder approach)
        ...controller.notifications.map((notification) =>
            _buildNotificationItem(
              notification: notification,
              sw: sw,
              sh: sh,
              screenWidth: screenWidth,
              baseWidth: baseWidth,
            ),
        ).toList(),

        // Toggle section - added at the end of the list
        _buildToggleSection(sw, sh, screenWidth, baseWidth),
      ],
    );
  }

  /// -------------------- DRIVER NOTIFICATION ITEM --------------------
  Widget _buildDriverNotificationItem({
    required NotificationModel notification,
    required double Function(double) sw,
    required double Function(double) sh,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: sh(16)),
      child: Row(
        children: [
          /// Icon Container with light background
          Container(
            width: sw(56),
            height: sh(56),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _getNotificationIcon(
                notification.type,
                sw,
                sh,
              ),
            ),
          ),

          SizedBox(width: sw(16)),

          /// Title and Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w500,
                    fontSize: sw(16),
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: sh(4)),
                Text(
                  notification.time,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w400,
                    fontSize: sw(14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------- EMPTY STATE --------------------
  Widget _buildEmptyState(
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return Column(
      children: [
        // Empty state message (your original design)
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: sw(80),
                  color: Colors.grey[400],
                ),
                SizedBox(height: sh(10)),
                Text(
                  "No notifications yet",
                  style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                        screenWidth /
                        baseWidth,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Toggle section at bottom
        _buildToggleSection(sw, sh, screenWidth, baseWidth),
      ],
    );
  }

  /// -------------------- TOGGLE SECTION --------------------
  Widget _buildToggleSection(
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return Padding(
      padding: EdgeInsets.only(
        right: sw(10),
        left: sw(10),
        top: sh(20),
        bottom: sh(20),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Enable Notifications",
              style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! *
                    screenWidth /
                    baseWidth,
                color: Colors.black87,
              ),
            ),
            // SizedBox(width: sw(130)),
            Obx(
                  () => Switch(
                value: controller.notificationsEnabled.value,
                onChanged: controller.toggleNotifications,
                activeColor: Colors.black,
                inactiveThumbColor: FColors.white,
                inactiveTrackColor: FColors.radioField,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------- PASSENGER NOTIFICATION ITEM --------------------
  Widget _buildNotificationItem({
    required NotificationModel notification,
    required double Function(double) sw,
    required double Function(double) sh,
    required double screenWidth,
    required double baseWidth,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: sh(1)),
      padding: EdgeInsets.symmetric(
        horizontal: sw(16),
        vertical: sh(13),
      ),
      child: Row(
        children: [
          /// Icon Container
          Container(
            width: sw(48),
            height: sh(48),
            child: Center(
              child: _getNotificationIcon(
                notification.type,
                sw,
                sh,
              ),
            ),
          ),

          SizedBox(width: sw(16)),

          /// Title and Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: sh(2)),
                Text(
                  notification.time,
                  style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------- ICON HANDLER --------------------
  Widget _getNotificationIcon(
      notificationType,
      double Function(double) sw,
      double Function(double) sh,
      ) {
    String iconPath;
    final userRole = StorageService.getRole();

    // Use different icons based on user role
    if (userRole == 'Driver') {
      switch (notificationType) {
        case NotificationType.rideRequest:
          iconPath = 'assets/drawer/car.svg';
          break;
        case NotificationType.paymentReceived:
          iconPath = 'assets/drawer/earn.svg';
          break;
        case NotificationType.rideCompleted:
          iconPath = 'assets/drawer/star.svg';
          break;
        case NotificationType.newFeature:
          iconPath = 'assets/drawer/gift.svg';
          break;
        case NotificationType.accountUpdate:
          iconPath = 'assets/drawer/annoucs.svg';
          break;
        default:
          iconPath = 'assets/images/notification_bell.svg';
      }
    } else {
      // Passenger icons
      switch (notificationType) {
        case NotificationType.rideRequest:
          iconPath = 'assets/drawer/car.svg';
          break;
        case NotificationType.paymentReceived:
          iconPath = 'assets/drawer/payment.svg';
          break;
        case NotificationType.rideCompleted:
          iconPath = 'assets/drawer/complete.svg';
          break;
        case NotificationType.newFeature:
          iconPath = 'assets/drawer/gift.svg';
          break;
        case NotificationType.accountUpdate:
          iconPath = 'assets/drawer/account.svg';
          break;
        default:
          iconPath = 'assets/images/notification_bell.svg';
      }
    }

    return SvgPicture.asset(iconPath);
  }
}