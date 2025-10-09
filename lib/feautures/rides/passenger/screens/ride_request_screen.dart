import 'dart:convert';
import 'package:doorcab/feautures/rides/driver/screens/reuseable_widgets/drawer.dart';
import 'package:doorcab/feautures/rides/passenger/screens/reusable_widgets/passengers_chips.dart';
import 'package:doorcab/feautures/rides/passenger/screens/reusable_widgets/ride_request_location_field.dart';
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
      drawer: PassengerDrawer(),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Map (top→380) - Show route with polyline
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
                initialCameraPosition: CameraPosition(
                  target: c.pickupCoords ?? LatLng(
                    c.currentPosition.value?.latitude ?? 0,
                    c.currentPosition.value?.longitude ?? 0,
                  ),
                  zoom: 15,
                ),
                myLocationEnabled: false,
                onMapCreated: c.onMapCreated,
                markers: c.markers,
                polylines: c.routePolyline.value != null
                    ? {c.routePolyline.value!}
                    : {},
              );
            }),
          ),

          /// Drawer/Menu Icon
          Positioned(
            top: sh(39),
            left: sw(33),
            child: Builder(
              builder:
                  (context) => GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openDrawer(); // ✅ works now
                    },
                    child: Image.asset(
                      "assets/images/drawer_icon.png",
                      fit: BoxFit.cover,
                      width: sw(39),
                      height: sh(39),
                    ),
                  ),
            ),
          ),

          /// Ride type selector (top: 390, left: 24) - Show fare instead of title
          Positioned(
            top: sh(390),
            left: sw(24),
            child: SizedBox(
              width: sw(390),
              height: sh(90),
              child: Obx(() {
                // ✅ New: show spinner while calculating fare / building polyline
                if (c.isCalculatingFare.value) {
                  return const Center(child: CircularProgressIndicator());
                }
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
                              color:
                                  isSelected
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
                              // Show fare instead of title
                              Text(
                                c.fareForCard(i),
                                style: FTextTheme.lightTextTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
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

          /// Pickup field (top: 498, left: 24) - Use pickupLocation instead of pickupText
          Positioned(
            top: sh(498),
            left: sw(24),
            right: sw(24),
            child: Obx(
              () => LocationField(
                label: "Pickup",
                hasIcon: true,
                text:
                    c.pickupLocation.value.isEmpty
                        ? "Pickup Location"
                        : c.pickupLocation.value,
                onTap: () => Get.back(),
                // onTap: c.onTapPickup,
                sw: sw,
              ),
            ),
          ),

          /// Dropoff field (top: 570, left: 24) - Use dropoffLocation instead of dropoffText
          Positioned(
            top: sh(570),
            left: sw(24),
            right: sw(24),
            child: Obx(
              () => LocationField(
                label: "Dropoff",
                hasIcon: false,
                text:
                    c.dropoffLocation.value.isEmpty
                        ? "Dropoff Location"
                        : c.dropoffLocation.value,
                onTap: () => Get.back(),
                // onTap: c.openDropoff,
                sw: sw,
                showAddStop: true,
                onAddStop: c.openDropoff,
              ),
            ),
          ),

          /// Date text (top: 626, left: 49)
          Positioned(
            top: sh(635),
            left: sw(49),
            child: GestureDetector(
              onTap: c.openDateTimePopup,
              child: Obx(
                () => Text(
                  c.dateLabel.value,
                  style: FTextTheme.lightTextTheme.labelSmall,
                ),
              ),
            ),
          ),

          /// Time text (top: 626, left: 318)
          Positioned(
            top: sh(635),
            left: sw(318),
            child: GestureDetector(
              onTap: c.openDateTimePopup,
              child: Obx(
                () => Text(
                  c.timeLabel.value,
                  style: FTextTheme.lightTextTheme.labelSmall,
                ),
              ),
            ),
          ),

          /// Fare & passenger container (top 671, left 24, w 343, h 143)
          Positioned(
            top: sh(671),
            left: sw(24),
            child: Container(
              width: sw(400),
              height: sh(150),
              decoration: BoxDecoration(
                color: FColors.phoneInputField,
                borderRadius: BorderRadius.circular(sw(14)),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
          ),

          /// Passenger chips row inside the container (top 682, left 48)
          Positioned(
            top: sh(675),
            left: sw(78),
            child: SizedBox(
              width: sw(360),
              child: Row(
                children: [
                  for (final p in c.passengerOptions)
                    Padding(
                      padding: EdgeInsets.only(right: sw(4)),
                      child: Obx(() {
                        if (p == "More") {
                          return MorePassengersChip(
                            selectedPassengers: c.selectedPassengers.value,
                            onSelected:
                                (val) => c.selectedPassengers.value = val,
                          );
                        }
                        return RawChip(
                          showCheckmark: false,
                          label: Text(
                            p,
                            style: TextStyle(
                              color:
                                  c.selectedPassengers.value == p
                                      ? FColors.black
                                      : FColors.white,
                              fontSize: sw(15),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          avatar:
                              c.selectedPassengers.value == p
                                  ? Icon(
                                    Icons.person,
                                    size: sw(20),
                                    color: FColors.secondaryColor,
                                  )
                                  : null,
                          // ✅ only shows when selected
                          selected: c.selectedPassengers.value == p,
                          onSelected: (_) => c.selectedPassengers.value = p,
                          selectedColor: FColors.primaryColor,
                          backgroundColor: FColors.chipBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(sw(8)),
                          ),
                          pressElevation: 0,
                        );
                      }),
                    ),
                ],
              ),
            ),
          ),

          /// Minus button (top 746.4, left 94)
          Positioned(
            top: sh(730.4),
            left: sw(94),
            child: IconButton(
              onPressed: c.decrementFare,
              icon: Image.asset("assets/images/minus_btn.png"),
              // Icon(Icons.remove_circle_outline, size: sw(28)),
              color: FColors.black,
            ),
          ),

          /// Fare input field (top 739, left 151, h 37, min w 138)
          Positioned(
            top: sh(739),
            left: sw(160),
            child: SizedBox(
              width: sw(150).clamp(sw(138), double.infinity),
              height: sh(37),
              child: TextField(
                controller: c.fareController,
                keyboardType: TextInputType.number,
                // inputFormatters: c.digitsOnly,
                textAlign: TextAlign.center,
                style: FTextTheme.lightTextTheme.titleSmall,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: FColors.primaryColor,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: sw(25),
                    vertical: sh(5),
                  ),
                  prefix: Text("PKR "),
                  prefixStyle: FTextTheme.lightTextTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sw(10)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sw(10)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sw(10)),
                    borderSide: BorderSide.none,
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sw(10)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          /// Plus button (top 746.4, left 324.63)
          Positioned(
            top: sh(730.4),
            left: sw(324.63),
            child: IconButton(
              onPressed: c.incrementFare,
              icon: Image.asset("assets/images/plus_btn.png"),
              color: FColors.black,
            ),
          ),

          /// Little note label with leading "*" (top 785, left 87)
          Positioned(
            top: sh(785),
            left: sw(87),
            child: Row(
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 10,
                  color: FColors.primaryColor,
                ),
                Text(
                  " If no rider accepts your offer raise your fare",
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
            top: sh(835),
            left: sw(85),
            child: Text(
              "Auto accept offers",
              style: FTextTheme.lightTextTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            top: sh(816),
            left: sw(282),
            child: Obx(
              () => Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: c.autoAccept.value,
                  activeColor: FColors.primaryColor,
                  inactiveThumbColor: FColors.white,
                  inactiveTrackColor: FColors.secondaryColor,
                  onChanged: (val) => c.autoAccept.value = val,
                ),
              ),
            ),
          ),

          /// Bottom: Cash icon button with text under it (top 885, left 31)
          Positioned(
            top: sh(885),
            left: sw(11),
            child: InkWell(
              onTap: c.openPaymentMethods,
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/cash.png",
                    width: sw(30),
                    height: sh(30),
                  ),
                  // Icon(Icons.account_balance_wallet, size: sw(28)),
                  SizedBox(height: sh(1)),
                  Obx(
                    () => Text(
                      _getPaymentText(c.selectedPaymentLabel.value),
                      style: FTextTheme.lightTextTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Bottom: main action button (w 287, h 48, top 885, left 77)
          Positioned(
            top: sh(888),
            left: sw(85),
            child: SizedBox(
              width: sw(287),
              height: sh(48),
              child: Obx(
                () => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FColors.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sw(12)),
                    ),
                  ),
                  // ✅ Disabled until mapReady AND fares/calculation done and not isLoading
                  onPressed:
                      (c.isLoading.value ||
                              c.isCalculatingFare.value ||
                              !c.mapReady.value)
                          ? null
                          : c.onRequestRide,
                  child:
                      c.isLoading.value
                          ? SizedBox(
                            width: sw(20),
                            height: sw(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            "Request Ride",
                            style: FTextTheme.lightTextTheme.titleSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                ),
              ),
            ),
          ),

          /// Bottom: comment icon button (top 872, left 379)
          Positioned(
            top: sh(882),
            left: sw(379),
            child: IconButton(
              onPressed: c.openComments,
              icon: Image.asset(
                "assets/images/comment.png",
                width: sw(28),
                height: sh(27),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
String _getPaymentText(String method) {
  switch (method) {
    case "Cash Payment":
      return "Pay Cash";
    case "Easypaisa":
      return "EasyPaisa";
    case "JazzCash":
      return "JazzCash";
    case "Debit/Credit Card":
      return "Pay Card";
    case "DoorCabs Wallet":
      return "Pay Wallet";
    default:
      return "Pay Cash";
  }
}

