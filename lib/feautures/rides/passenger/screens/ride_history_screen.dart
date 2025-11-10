import 'package:doorcab/feautures/rides/passenger/screens/ride_detail_screen.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/ride_history_controller.dart';
import '../models/ride_model.dart';

class RideHistoryScreen extends StatelessWidget {
  final RideHistoryController controller = Get.put(RideHistoryController());

  RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base reference (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor:  FColors.primaryColor,
      body: Stack(
        children: [
          Positioned(
            top: sh(11),
            left: 0,
            right: 0,
            child: SizedBox(
              width: screenWidth,
              height: sh(111),
              child: Image.asset(
                "assets/images/header.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: sh(122),
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: FColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(31),
                  topRight: Radius.circular(31),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: sw(14), vertical: sh(6)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: sw(28),
                        height: sh(6),
                        margin: EdgeInsets.only(bottom: sh(8)),
                        decoration: BoxDecoration(
                          color: FColors.phoneInputField,
                          borderRadius: BorderRadius.circular(sw(4)),
                        ),
                      ),
                    ),

                    SizedBox(height: sh(2)),

                    // My Ride & Delivery
                    Center(
                      child: Text(
                        "My Ride & Delivery",
                        style: FTextTheme.lightTextTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: FTextTheme.lightTextTheme.titleLarge!.fontSize! *
                              screenWidth /
                              baseWidth,
                        ),
                      ),
                    ),
                    SizedBox(height: sh(6)), // Reduced from 10

                    // Filter buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: sw(7)),
                        _filterButton("All", width: sw(46), sw: sw, sh: sh, screenWidth: screenWidth, baseWidth: baseWidth),
                        SizedBox(width: sw(12)), // Reduced spacing
                        _filterButton("Rides", icon: "assets/images/car.png", width: sw(60), sw: sw, sh: sh, screenWidth: screenWidth, baseWidth: baseWidth),
                        SizedBox(width: sw(12)),
                        _filterButton("Delivery", icon: "assets/images/package.png", width: sw(79), sw: sw, sh: sh, screenWidth: screenWidth, baseWidth: baseWidth),
                      ],
                    ),
                    SizedBox(height: sh(6)), // Space between buttons and ride list

                    Expanded(
                      child: Obx(() {
                        var filteredRides =
                        controller.selectedFilter.value == "All"
                            ? controller.rides
                            : controller.rides.where((r) =>
                        (controller.selectedFilter.value == "Rides" &&
                            r.rideType.contains("Door")) ||
                            (controller.selectedFilter.value == "Delivery" &&
                                r.rideType == "Delivery")).toList();

                        List<Widget> rideWidgets = [];

                        //  Iterate with grouping of 2 rides per date
                        for (int i = 0; i < filteredRides.length; i += 2) {
                          // Take 2 rides chunk
                          var chunk = filteredRides.skip(i).take(2).toList();
                          String date = chunk.first.date;

                          rideWidgets.add(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: sh(6), horizontal: sw(5)),
                                  child: Text(
                                    date,
                                    style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                                          screenWidth /
                                          baseWidth,
                                    ),
                                  ),
                                ),
                                // Show both rides
                                ...chunk.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final ride = entry.value;
                                  bool showSupport =
                                      ride.date == "Sunday, August 10" && idx == 0;
                                  return _rideCard(ride, showSupport: showSupport, sw: sw, sh: sh, screenWidth: screenWidth, baseWidth: baseWidth);
                                }).toList(),
                              ],
                            ),
                          );
                        }

                        return ListView(
                          padding: EdgeInsets.zero,
                          children: rideWidgets,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(
      String label, {
        String? icon,
        required double width,
        required double Function(double) sw,
        required double Function(double) sh,
        required double screenWidth,
        required double baseWidth,
      }) {
    return Obx(() {
      bool selected = controller.selectedFilter.value == label;
      return GestureDetector(
        onTap: () => controller.setFilter(label),
        child: Container(
          width: width,
          height: sh(30),
          decoration: BoxDecoration(
            color: selected
                ? const Color.fromRGBO(255, 195, 0, 1)
                :  FColors.grey200,
            borderRadius: BorderRadius.circular(sw(20)),
            border: Border.all(
              color: selected
                  ? const Color.fromRGBO(255, 195, 0, 1)
                  : FColors.transparent,
              width: sw(1.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Image.asset(
                  icon,
                  height: sh(15),
                  width: sw(15),
                  fit: BoxFit.contain,
                ),
                SizedBox(width: sw(3)),
              ],
              Text(
                label,
                style: FTextTheme.lightTextTheme.labelMedium!.copyWith(
                  color: FColors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: FTextTheme.lightTextTheme.labelMedium!.fontSize! *
                      screenWidth /
                      baseWidth,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _rideCard(
      RideModel ride, {
        bool showSupport = false,
        required double Function(double) sw,
        required double Function(double) sh,
        required double screenWidth,
        required double baseWidth,
      }) {
    return GestureDetector(
      onTap: () {
        // Navigate to the RideDetailView when the card is tapped
        Get.to(() => RideDetailScreen(), arguments: ride);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: sh(3), horizontal: sw(2)),
        padding: EdgeInsets.symmetric(horizontal: sw(8), vertical: sh(8)),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 195, 0, 0.42),
          borderRadius: BorderRadius.circular(sw(18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              ride.iconPath,
              height: sh(27),
              width: sw(27),
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.directions_car, size: sw(27), color: Colors.black);
              },
            ),
            SizedBox(width: sw(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${ride.rideType}, ${ride.time}",
                    style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                          screenWidth /
                          baseWidth,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!(ride.date == "Sunday, August 10" && ride.status == "Canceled"))
                    Text(
                      ride.location,
                      style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                        color: FColors.chipBg,
                        fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                            screenWidth /
                            baseWidth,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (ride.status == "Canceled")
                    Container(
                      // margin: EdgeInsets.only(top: sh(4)),
                      // padding: EdgeInsets.symmetric(horizontal: sw(12), vertical: sh(1)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(sw(12)),
                      ),
                      child: Text(
                        "Canceled",
                        style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                          color: FColors.error,
                          fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                              screenWidth /
                              baseWidth,
                        ),
                      ),
                    )
                  else if (showSupport)
                    Container(
                      margin: EdgeInsets.only(top: sh(4)),
                      padding: EdgeInsets.symmetric(horizontal: sw(12), vertical: sh(3)),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 195, 0, 1),
                        borderRadius: BorderRadius.circular(sw(12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/images/contact.png",
                            height: sh(14),
                            width: sw(14),
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.support_agent, size: sw(14), color: Colors.black);
                            },
                          ),
                          SizedBox(width: sw(5)),
                          Text(
                            "Contact Support",
                            style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                              color: Colors.black,
                              fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: sw(8)),
            Text(
              "PKR ${ride.fare.toInt()}",
              style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                    screenWidth /
                    baseWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}