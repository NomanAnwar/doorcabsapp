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
      body: Obx(() {
        final userRole = StorageService.getRole();
        final notifications = controller.notifications;
        final isLoading = controller.isLoading.value;

        return SizedBox(
          height: screenHeight,
          width: screenWidth,
          child: Stack(
            children: [
              /// Back Button
              Positioned(
                top: sh(23),
                left: sw(23),
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
                top: sh(60),
                left: 0,
                right: 0,
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

              /// Main Content Area
              if (isLoading)
                Positioned(
                  top: sh(160),
                  left: 0,
                  right: 0,
                  bottom: sh(50),
                  child: _buildLoadingState(sw, sh, screenWidth, baseWidth),
                )
              else if (notifications.isEmpty)
                Positioned(
                  top: sh(160),
                  left: 0,
                  right: 0,
                  bottom: sh(50),
                  child: Container(
                    child: Center(
                      child: Text("No notification found"),
                    ),
                  ),
                )
              else
                Positioned(
                  top: sh(160),
                  left: 0,
                  right: 0,
                  bottom: sh(50),
                  child: userRole == 'Driver'
                      ? _buildDriverContent(sw, sh, screenWidth, baseWidth)
                      : _buildPassengerContent(sw, sh, screenWidth, baseWidth),
                ),

              /// Toggle Section at Bottom
              Positioned(
                top: sh(100),
                left: sw(20),
                right: sw(20),
                child: _buildToggleSection(sw, sh, screenWidth, baseWidth),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// -------------------- DRIVER CONTENT --------------------
  Widget _buildDriverContent(
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: sw(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Today Section
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

          /// Today's notifications (first 3 items)
          ...controller.notifications.take(3).map((notification) =>
              _buildDriverNotificationItem(
                notification: notification,
                sw: sw,
                sh: sh,
              ),
          ).toList(),

          /// Yesterday Section
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

          /// Yesterday's notifications (next 2 items)
          ...controller.notifications.skip(3).take(2).map((notification) =>
              _buildDriverNotificationItem(
                notification: notification,
                sw: sw,
                sh: sh,
              ),
          ).toList(),
        ],
      ),
    );
  }

  /// -------------------- PASSENGER CONTENT --------------------
  Widget _buildPassengerContent(
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.notifications.length,
      itemBuilder: (context, index) {
        final notification = controller.notifications[index];
        return _buildNotificationItem(
          notification: notification,
          sw: sw,
          sh: sh,
          screenWidth: screenWidth,
          baseWidth: baseWidth,
        );
      },
    );
  }

  /// -------------------- LOADING STATE --------------------
  Widget _buildLoadingState(
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: FColors.secondaryColor,
          ),
          SizedBox(height: sh(16)),
          Text(
            "Loading notifications...",
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w500,
                          fontSize: sw(16),
                          color: Colors.black,
                        ),
                      ),
                    ),
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
                SizedBox(height: sh(4)),
                Text(
                  notification.message,
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(sw(5)),
              color: FColors.radioField,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                              screenWidth /
                              baseWidth,
                          color: Colors.black,
                        ),
                      ),
                    ),
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
                SizedBox(height: sh(4)),
                Text(
                  notification.message,
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

  /// -------------------- TOGGLE SECTION --------------------
  Widget _buildToggleSection(
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sw(10)),
      child: Row(
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
          iconPath = 'assets/images/notification.svg';
          break;
        case NotificationType.promotions:
          iconPath = 'assets/drawer/gift.svg';
          break;
        case NotificationType.rides:
          iconPath = 'assets/drawer/car.svg';
          break;
        default:
          iconPath = 'assets/images/notification.svg';
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
          iconPath = 'assets/images/notification.svg';
          break;
        case NotificationType.promotions:
          iconPath = 'assets/drawer/gift.svg';
          break;
        case NotificationType.rides:
          iconPath = 'assets/drawer/car.svg';
          break;

        default:
          iconPath = 'assets/images/notification.svg';
      }
    }

    return SvgPicture.asset(iconPath);
  }
}