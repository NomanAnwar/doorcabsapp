import 'package:doorcab/feautures/rides/passenger/screens/ride_detail_screen.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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

    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: FColors.primaryColor,
      body: Stack(
        children: [
          Positioned(
            top: sh(11),
            left: 0,
            right: 0,
            child: SizedBox(
              width: screenWidth,
              height: sh(111),
              child: Image.asset("assets/images/header.png", fit: BoxFit.cover),
            ),
          ),

          // Back Button
          Positioned(
            top: sh(19),
            left: sw(13),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: IconButton(
                icon: SvgPicture.asset(
                  "assets/images/Arrow.svg",
                  width: sw(28),
                  height: sh(20),
                ),
                onPressed: () => Get.back(),
              ),
            ),
          ),

          // MAIN WHITE CONTAINER
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
                padding: EdgeInsets.symmetric(
                  horizontal: sw(14),
                  vertical: sh(6),
                ),
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

                    Center(
                      child: Text(
                        "My Ride & Delivery",
                        style: FTextTheme.lightTextTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize:
                              FTextTheme.lightTextTheme.titleLarge!.fontSize! *
                              screenWidth /
                              baseWidth,
                        ),
                      ),
                    ),

                    SizedBox(height: sh(6)),

                    // Filters
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: sw(7)),
                        _filterButton(
                          "All",
                          width: sw(46),
                          sw: sw,
                          sh: sh,
                          screenWidth: screenWidth,
                          baseWidth: baseWidth,
                        ),
                        SizedBox(width: sw(12)),
                        _filterButton(
                          "Rides",
                          icon: "assets/images/car.png",
                          width: sw(70),
                          sw: sw,
                          sh: sh,
                          screenWidth: screenWidth,
                          baseWidth: baseWidth,
                        ),
                        SizedBox(width: sw(12)),
                        _filterButton(
                          "Delivery",
                          icon: "assets/images/package.png",
                          width: sw(90),
                          sw: sw,
                          sh: sh,
                          screenWidth: screenWidth,
                          baseWidth: baseWidth,
                        ),
                      ],
                    ),

                    SizedBox(height: sh(6)),

                    // LIST VIEW
                    Expanded(
                      child:
                          Obx(() {
                                if (controller.isLoading.value) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: FColors.primaryColor,
                                    ),
                                  );
                                }

                                // APPLY FILTER
                                var filteredRides =
                                    controller.selectedFilter.value == "All"
                                        ? controller.rides
                                        : controller.rides.where((r) {
                                          if (controller.selectedFilter.value ==
                                              "Rides") {
                                            return r.rideType.contains("Door");
                                          } else if (controller
                                                  .selectedFilter
                                                  .value ==
                                              "Delivery") {
                                            return r.rideType == "Delivery";
                                          }
                                          return true;
                                        }).toList();


                                // ---- CHECK IF EMPTY ----
                                if (filteredRides.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(height: sh(20)),
                                        Text(
                                          "No Rides Found",
                                          style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                                                screenWidth /
                                                baseWidth,
                                          ),
                                        ),
                                        SizedBox(height: sh(8)),
                                        Text(
                                          "You don't have any rides in ${controller.selectedFilter.value.toLowerCase()} yet",
                                          style: FTextTheme.lightTextTheme.labelMedium!.copyWith(
                                            color: FColors.chipBg,
                                            fontSize: FTextTheme.lightTextTheme.labelMedium!.fontSize! *
                                                screenWidth /
                                                baseWidth,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // ---- REVERSE ORDER (newest on top) ----
                                // filteredRides = filteredRides.reversed.toList();

                                // ---- GROUP BY DATE ----
                                Map<String, List<RideModel>> grouped = {};

                                for (var ride in filteredRides) {
                                  if (!grouped.containsKey(ride.date)) {
                                    grouped[ride.date] = [];
                                  }
                                  grouped[ride.date]!.add(ride);
                                }

                                // ---- BUILD UI ----
                                List<Widget> rideWidgets = [];

                                grouped.forEach((date, rides) {
                                  rideWidgets.add(
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // DATE TEXT
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: sh(6),
                                            horizontal: sw(5),
                                          ),
                                          child: Text(
                                            date,
                                            style: FTextTheme
                                                .lightTextTheme
                                                .labelSmall!
                                                .copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize:
                                                      FTextTheme
                                                          .lightTextTheme
                                                          .labelSmall!
                                                          .fontSize! *
                                                      screenWidth /
                                                      baseWidth,
                                                ),
                                          ),
                                        ),

                                        // ALL RIDES UNDER SAME DATE
                                        ...rides.map((ride) {
                                          return _rideCard(
                                            ride,
                                            showSupport: false,
                                            sw: sw,
                                            sh: sh,
                                            screenWidth: screenWidth,
                                            baseWidth: baseWidth,
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  );
                                });

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

  // FILTER BUTTON
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
            color:
                selected
                    ? const Color.fromRGBO(255, 195, 0, 1)
                    : FColors.grey200,
            borderRadius: BorderRadius.circular(sw(20)),
            border: Border.all(
              color:
                  selected
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
                  fontSize:
                      FTextTheme.lightTextTheme.labelMedium!.fontSize! *
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

  // RIDE CARD
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
          children: [
            Image.asset(
              ride.iconPath,
              height: sh(27),
              width: sw(27),
              errorBuilder:
                  (_, __, ___) => Icon(Icons.directions_car, size: sw(27)),
            ),
            SizedBox(width: sw(8)),

            // TEXT CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${ride.rideType}, ${ride.time}",
                    style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize:
                          FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                          screenWidth /
                          baseWidth,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  Text(
                    ride.location,
                    style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                      color: FColors.chipBg,
                      fontSize:
                          FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                          screenWidth /
                          baseWidth,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (ride.status == "Canceled")
                    Text(
                      "Canceled",
                      style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                        color: FColors.error,
                        fontSize:
                            FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                            screenWidth /
                            baseWidth,
                      ),
                    ),
                  // else
                  // Text(
                  //   ride.location,
                  //   style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                  //     color: FColors.chipBg,
                  //     fontSize: FTextTheme.lightTextTheme.labelSmall!
                  //         .fontSize! *
                  //         screenWidth /
                  //         baseWidth,
                  //   ),
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                ],
              ),
            ),

            SizedBox(width: sw(8)),

            Text(
              "${(ride.displayFare)}",
              // "PKR ${(ride.fare.toInt())}",
              style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w500,
                fontSize:
                    FTextTheme.lightTextTheme.titleSmall!.fontSize! *
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
