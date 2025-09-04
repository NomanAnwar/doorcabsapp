import 'dart:convert';

import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/ride_home_controller.dart';

class RideHomeScreen extends StatelessWidget {
  const RideHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RideHomeController());

    // Reference screen size (iPhone 16 Pro Max)
    final baseWidth = 440.0;
    final baseHeight = 956.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Scale helpers
    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      body: Stack(
        children: [
          /// Map
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: sh(500),
            child: Obx(() {
              if (c.currentPosition.value == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return GoogleMap(
                key: const ValueKey("map"),
                initialCameraPosition: CameraPosition(
                  target: c.currentPosition.value!,
                  zoom: 15,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: c.onMapCreated,
                markers: c.markers.toSet(),
              );
            }),
          ),

          /// Drawer/Menu Icon
          Positioned(
            top: sh(39),
            left: sw(33),
            child: Icon(Icons.menu, size: sw(28)),
          ),

          /// Ride type selector
          Positioned(
            top: sh(524),
            left: sw(25),
            child: SizedBox(
              width: sw(390),
              height: sh(90),
              child: Obx(() {
                // ✅ Show loader if fetching and nothing cached yet
                if (c.rideTypes.isEmpty && c.isLoadingRideTypes.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If no data (API failed & no cache) → show nothing
                if (c.rideTypes.isEmpty) {
                  return const SizedBox.shrink();
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: c.rideTypes.length,
                  separatorBuilder: (_, __) => SizedBox(width: sw(8)),
                  itemBuilder: (_, i) {
                    return Obx(() {
                      final isSelected = c.selectedRideIndex.value == i;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => c.onSelectRide(i),
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: sh(3)),
                          constraints: BoxConstraints(minWidth: sw(75)),
                          height: sh(85),
                          padding: EdgeInsets.symmetric(horizontal: sw(5)),
                          decoration: BoxDecoration(
                            color: FColors.white,
                            borderRadius: BorderRadius.circular(sw(10)),
                            border: Border.all(
                              width: isSelected ? 2 : 1,
                              color: isSelected
                                  ? FColors.secondaryColor
                                  : Colors.grey.shade300,
                            ),
                            // (kept your boxShadow commented lines untouched)
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              c.rideTypes[i].isBase64
                                  ? Image.memory(
                                base64Decode(
                                  c.rideTypes[i].image
                                      .split(',')
                                      .last, // strip any data URL prefix
                                ),
                                height: sh(36),
                              )
                                  : Image.asset(
                                c.rideTypes[i].image,
                                height: sh(36),
                              ),
                              SizedBox(height: sh(6)),
                              Text(
                                c.rideTypes[i].title,
                                style: FTextTheme.lightTextTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                );
              }),
            ),
          ),

          /// Where to? field
          Positioned(
            top: sh(633),
            left: sw(23),
            right: sw(23),
            child: Obx(
                  () => GestureDetector(
                onTap: c.openDropoff,
                child: Container(
                  height: sh(52),
                  padding: EdgeInsets.symmetric(horizontal: sw(12)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E3E3),
                    borderRadius: BorderRadius.circular(sw(14)),
                  ),
                  child: Row(
                    children: [
                      /// Dropoff text
                      Expanded(
                        child: Text(
                          c.dropoffText.value.isEmpty
                              ? "Where to?"
                              : c.dropoffText.value,
                          style: FTextTheme.lightTextTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      /// ADD STOP button
                      SizedBox(
                        width: sw(116),
                        height: sh(30),
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            padding: EdgeInsets.symmetric(horizontal: sw(8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(sw(9)),
                            ),
                          ),
                          onPressed: c.openDropoff,
                          label: const Text(
                            "ADD STOP",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w500, // medium
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                          icon:
                          Icon(Icons.add, size: sw(16), color: Colors.black),
                          iconAlignment:
                          IconAlignment.end, // text first then icon
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// Recent Searches
          Positioned(
            top: sh(720),
            left: sw(23),
            right: sw(23),
            child: Obx(() {
              if (c.recent.isEmpty) {
                return const Text("No recent searches yet",
                    style: TextStyle(color: Colors.grey));
              }
              return Column(
                children: [
                  for (int i = 0; i < c.recent.length && i < 3; i++)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => c.selectRecent(c.recent[i]),
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: sh(12), left: sw(10), right: sw(10)),
                        child: Container(
                          padding: EdgeInsets.only(bottom: sh(5)),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 2,
                                color: FColors.buttonDisabled,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(sw(6)),
                                  color: FColors.phoneInputField,
                                ),
                                height: sh(34),
                                width: sw(34),
                                padding: EdgeInsets.all(sw(2)),
                                child: Icon(
                                  Icons.near_me_sharp,
                                  color: FColors.black,
                                ),
                              ),
                              SizedBox(width: sw(12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(c.recent[i].description,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: sw(14))),
                                    SizedBox(height: sh(2)),
                                    Text(
                                      "Pakistan",
                                      style: TextStyle(
                                          fontSize: sw(12),
                                          color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: sw(8)),
                              Text("25 min",
                                  style: TextStyle(
                                      fontSize: sw(12),
                                      color: Colors.black54)),
                              SizedBox(width: sw(8)),
                              Icon(Icons.refresh_sharp,
                                  color: FColors.black, size: sw(22)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
