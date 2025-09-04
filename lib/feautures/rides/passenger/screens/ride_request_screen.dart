import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/ride_request_controller.dart';

class RideRequestScreen extends StatelessWidget {
  const RideRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RideRequestController());

    // Reference design (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Map (top→380)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: sh(380),
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
            child: Icon(Icons.menu, size: sw(28), color: FColors.black),
          ),

          /// Ride type selector (top: 390, left: 24)
          Positioned(
            top: sh(390),
            left: sw(24),
            child: SizedBox(
              width: sw(390),
              height: sh(90),
              child: Obx(() {
                if (c.rideTypes.isEmpty && c.isLoadingRideTypes.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (c.rideTypes.isEmpty) return const SizedBox.shrink();

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
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              c.rideTypes[i].isBase64
                                  ? Image.memory(
                                base64Decode(
                                  c.rideTypes[i].image.split(',').last,
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
                                overflow: TextOverflow.ellipsis,
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

          /// Pickup field (top: 498, left: 24)
          Positioned(
            top: sh(498),
            left: sw(24),
            right: sw(24),
            child: Obx(
                  () => _locationField(
                context,
                label: "Pickup",
                text: c.pickupText.value.isEmpty
                    ? "Pickup Location"
                    : c.pickupText.value,
                onTap: c.onTapPickup,
                sw: sw,
              ),
            ),
          ),

          /// Dropoff field (top: 570, left: 24)
          Positioned(
            top: sh(570),
            left: sw(24),
            right: sw(24),
            child: Obx(
                  () => _locationField(
                context,
                label: "Dropoff",
                text: c.dropoffText.value.isEmpty
                    ? "Dropoff Location"
                    : c.dropoffText.value,
                onTap: c.openDropoff,
                sw: sw,
              ),
            ),
          ),

          /// ADD STOP button inside dropoff field (absolute: top 581, left 301)
          Positioned(
            top: sh(581),
            left: sw(301),
            child: SizedBox(
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
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                icon: Icon(Icons.add, size: sw(16), color: Colors.black),
                iconAlignment: IconAlignment.end,
              ),
            ),
          ),

          /// Date text (top: 626, left: 49)
          Positioned(
            top: sh(626),
            left: sw(49),
            child: GestureDetector(
              onTap: c.openDateTimePopup,
              child: Obx(() => Text(
                c.dateLabel.value,
                style: FTextTheme.lightTextTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              )),
            ),
          ),

          /// Time text (top: 626, left: 318)
          Positioned(
            top: sh(626),
            left: sw(318),
            child: GestureDetector(
              onTap: c.openDateTimePopup,
              child: Obx(() => Text(
                c.timeLabel.value,
                style: FTextTheme.lightTextTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              )),
            ),
          ),

          /// Fare & passenger container (top 671, left 24, w 343, h 143)
          Positioned(
            top: sh(671),
            left: sw(24),
            child: Container(
              width: sw(400),
              height: sh(143),
              decoration: BoxDecoration(
                color: FColors.white,
                borderRadius: BorderRadius.circular(sw(14)),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
          ),

          /// Passenger chips row inside the container (top 682, left 48)
          Positioned(
            top: sh(682),
            left: sw(48),
            child: SizedBox(
              width: sw(360),
              child: Obx(
                    () => Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (final p in c.passengerOptions)
                      Padding(
                        padding: EdgeInsets.only(right: sw(8)),
                        child: ChoiceChip(
                          label: Text(p),
                          selected: c.selectedPassengers.value == p,
                          onSelected: (_) => c.selectedPassengers.value = p,
                          selectedColor: FColors.secondaryColor.withOpacity(.15),
                          labelStyle: TextStyle(
                            color: c.selectedPassengers.value == p
                                ? FColors.secondaryColor
                                : FColors.black,
                            fontSize: sw(12),
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(sw(8)),
                            side: BorderSide(
                              color: c.selectedPassengers.value == p
                                  ? FColors.secondaryColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          /// Minus button (top 746.4, left 94)
          Positioned(
            top: sh(746.4),
            left: sw(94),
            child: IconButton(
              onPressed: c.decrementFare,
              icon: Icon(Icons.remove_circle_outline, size: sw(28)),
              color: FColors.black,
            ),
          ),

          /// Fare input field (top 739, left 151, h 37, min w 138)
          Positioned(
            top: sh(739),
            left: sw(151),
            child: SizedBox(
              width: sw(150).clamp(sw(138), double.infinity),
              height: sh(37),
              child: TextField(
                controller: c.fareController,
                keyboardType: TextInputType.number,
                inputFormatters: c.digitsOnly,
                textAlign: TextAlign.center,
                style: FTextTheme.lightTextTheme.titleSmall,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: sw(10),
                    vertical: sh(8),
                  ),
                  prefixText: "PKR ",
                  prefixStyle: FTextTheme.lightTextTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sw(10)),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sw(10)),
                    borderSide: BorderSide(color: FColors.secondaryColor),
                  ),
                ),
              ),
            ),
          ),

          /// Plus button (top 746.4, left 324.63)
          Positioned(
            top: sh(746.4),
            left: sw(324.63),
            child: IconButton(
              onPressed: c.incrementFare,
              icon: Icon(Icons.add_circle_outline, size: sw(28)),
              color: FColors.black,
            ),
          ),

          /// Little note label with leading "*" (top 785, left 87)
          Positioned(
            top: sh(785),
            left: sw(87),
            child: Row(
              children: [
                Text(
                  "* ",
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: sw(12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Enter your offer in PKR",
                  style: TextStyle(
                    fontSize: sw(12),
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          /// Row: text + toggle (text at top 819/left 105, toggle at top 814/left 322)
          Positioned(
            top: sh(819),
            left: sw(105),
            child: Text(
              "Auto accept offers",
              style: FTextTheme.lightTextTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            top: sh(814),
            left: sw(322),
            child: Obx(
                  () => Switch(
                value: c.autoAccept.value,
                onChanged: (val) => c.autoAccept.value = val,
              ),
            ),
          ),

          /// Bottom: Cash icon button with text under it (top 865, left 31)
          Positioned(
            top: sh(865),
            left: sw(31),
            child: InkWell(
              onTap: c.openPaymentMethods,
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet, size: sw(28)),
                  SizedBox(height: sh(6)),
                  Obx(() => Text(
                    c.selectedPaymentLabel.value,
                    style: FTextTheme.lightTextTheme.labelSmall,
                  )),
                ],
              ),
            ),
          ),

          /// Bottom: main action button (w 287, h 48, top 865, left 77)
          Positioned(
            top: sh(865),
            left: sw(77),
            child: SizedBox(
              width: sw(287),
              height: sh(48),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FColors.secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(sw(12)),
                  ),
                ),
                onPressed: c.onRequestRide,
                child: Text(
                  "Request Ride",
                  style: FTextTheme.lightTextTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          /// Bottom: comment icon button (top 872, left 379)
          Positioned(
            top: sh(872),
            left: sw(379),
            child: IconButton(
              onPressed: c.openComments,
              icon: const Icon(Icons.comment),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationField(
      BuildContext ctx, {
        required String label,
        required String text,
        required VoidCallback onTap,
        required double Function(double) sw,
      }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: sw(12)),
        decoration: BoxDecoration(
          color: const Color(0xFFE3E3E3),
          borderRadius: BorderRadius.circular(sw(14)),
        ),
        child: Row(
          children: [
            Container(
              width: sw(34),
              height: sw(34),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FColors.phoneInputField,
                borderRadius: BorderRadius.circular(sw(6)),
              ),
              child: Icon(
                label == "Pickup" ? Icons.my_location : Icons.location_on,
                size: sw(18),
                color: FColors.black,
              ),
            ),
            SizedBox(width: sw(10)),
            Expanded(
              child: Text(
                text,
                style: FTextTheme.lightTextTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
