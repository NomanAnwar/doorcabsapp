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

    return Scaffold(
      body: Stack(
        children: [
          /// Map covers top area until ~500
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 500,
            child: Obx(() => GoogleMap(
              key: const ValueKey("map"),
              initialCameraPosition: const CameraPosition(
                target: LatLng(24.8607, 67.0011),
                zoom: 12,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: c.onMapCreated,
              markers: c.markers.toSet(), // only this part reacts
            )),
          ),

          /// Drawer/Menu Icon
          const Positioned(
            top: 39,
            left: 33,
            child: Icon(Icons.menu, size: 28),
          ),

          /// Ride type selector
          Positioned(
            top: 524,
            left: 25,
            child: SizedBox(
              width: 390,
              height: 90,
              child: Obx(() => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: c.rideTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final isSelected = c.selectedRideIndex.value == i;
                  return GestureDetector(
                    onTap: () => c.onSelectRide(i),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 3),
                      // width: 75,
                      constraints: const BoxConstraints(
                        minWidth: 75, // 👈 minimum width
                      ),
                      height: 85,
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: FColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected ? Border.all(width: 2, color: FColors.secondaryColor) : Border.all(width: 1, color: FColors.white),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 1))
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(c.rideTypes[i].image),
                          const SizedBox(height: 6),
                          Text(
                            c.rideTypes[i].title,
                            style: FTextTheme
                                .lightTextTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )),
            ),
          ),

          /// Where to? field
          Positioned(
            top: 633,
            left: 23,
            right: 23,
            child: Obx(() => GestureDetector(
              onTap: c.openDropoff,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E3E3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.dropoffText.value.isEmpty
                            ? "Where to?"
                            : c.dropoffText.value,
                        style: FTextTheme.lightTextTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ),

          /// Recent Searches
          Positioned(
            top: 720,
            left: 23,
            right: 23,
            child: Obx(() {
              if (c.recent.isEmpty) {
                return const Text("No recent searches yet",
                    style: TextStyle(color: Colors.grey));
              }
              return Column(
                children: [
                  for (int i = 0; i < c.recent.length && i < 3; i++)
                    GestureDetector(
                      onTap: () => c.selectRecent(c.recent[i]),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12,left: 10, right: 10),
                        child: Container(
                          padding: EdgeInsets.only(bottom: 5),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(width: 2, color: FColors.buttonDisabled))
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: FColors.phoneInputField),
                                  height: 34,
                                  width: 34,
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.near_me_sharp, color: FColors.black,)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(c.recent[i].description,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    const Text(
                                      "Pakistan",
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text("25 min",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                              const SizedBox(width: 8),
                              const Icon(Icons.refresh_sharp,
                                  color: FColors.black, size: 35,),
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
