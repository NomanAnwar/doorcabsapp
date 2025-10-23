// go_to_pickup_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../driver/screens/reuseable_widgets/drawer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/go_to_pickup_controller.dart';

class GoToPickupScreen extends StatelessWidget {
  const GoToPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final raw = Get.arguments;
    final c = Get.put(GoToPickupController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const DriverDrawer(),
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            /// Map (top → till 520)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: sh(520),
              child: Obx(() {
                if (c.currentPosition.value == null && c.pickupPosition.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                CameraPosition initial;
                if (c.currentPosition.value != null) {
                  initial = CameraPosition(target: c.currentPosition.value!, zoom: 14);
                } else {
                  initial = CameraPosition(target: c.pickupPosition.value!, zoom: 14);
                }

                final poly = c.routePolyline.value;
                final markers = c.markers.toSet();

                return GoogleMap(
                  initialCameraPosition: initial,
                  onMapCreated: c.onMapCreated,
                  markers: markers,
                  polylines: poly != null ? {poly} : <Polyline>{},
                );
              }),
            ),

            /// Back Button
            Positioned(
              top: sh(39),
              left: sw(33),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black, size: sw(28)),
                onPressed: () => Get.back(),
              ),
            ),

            /// Drawer Menu
            Positioned(
              top: sh(25),
              left: sw(382),
              child: Container(
                width: sw(39),
                height: sh(39),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Builder(
                  builder: (context) {
                    return IconButton(
                      icon: Icon(Icons.menu, color: Colors.black, size: sw(24)),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  },
                ),
              ),
            ),

            /// Passenger Info Card
            Positioned(
              top: sh(535),
              left: sw(10),
              child: Container(
                width: sw(420),
                height: sh(198),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E3E3),
                  borderRadius: BorderRadius.circular(sw(20)),
                ),
                child: Stack(
                  children: [
                    /// Passenger Image
                    Positioned(
                      top: sh(12),
                      left: sw(18),
                      child: Obx(() => CircleAvatar(
                        radius: sw(30),
                        backgroundImage: c.passengerProfileUrl.value.isNotEmpty
                            ? NetworkImage(c.passengerProfileUrl.value)
                            : const AssetImage('assets/images/profile_img_sample.png') as ImageProvider,
                      )),
                    ),

                    /// Passenger Name + Rating
                    Positioned(
                      top: sh(10),
                      left: sw(90),
                      child: Row(
                        children: [
                          Obx(() => Text(
                            c.passengerName.value.isNotEmpty ? c.passengerName.value.toUpperCase() : "NAME",
                            style: FTextTheme.lightTextTheme.bodyLarge,
                          )),
                          SizedBox(width: sw(15)),
                          const Icon(Icons.star, size: 14, color: Color(0xFFFFC300)),
                          SizedBox(width: sw(5)),
                          Obx(() => Text(
                            c.passengerRating.value.isNotEmpty ? c.passengerRating.value : "0",
                            style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                              fontSize: 10,
                            ),
                          )),
                        ],
                      ),
                    ),

                    /// Pickup
                    Positioned(
                      top: sh(40),
                      left: sw(90),
                      child: Obx(() => SizedBox(
                        width: sw(260), // ✅ restrict width
                        child: RichText(
                          overflow: TextOverflow.ellipsis, // ✅ show ellipsis if too long
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Pickup: ',
                                style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold, // ✅ bold only this
                                ),
                              ),
                              TextSpan(
                                text: c.pickupAddress.value.isNotEmpty
                                    ? c.pickupAddress.value
                                    : 'location',
                                style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal, // ✅ normal text
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ),

                    /// Dropoff
                    Positioned(
                      top: sh(63),
                      left: sw(90),
                      child: Obx(() => SizedBox(
                        width: sw(260), // ✅ restrict width
                        child: RichText(
                          overflow: TextOverflow.ellipsis, // ✅ ellipsis overflow
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Dropoff: ',
                                style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold, // ✅ bold only this
                                ),
                              ),
                              TextSpan(
                                text: c.dropoffAddress.value.isNotEmpty
                                    ? c.dropoffAddress.value
                                    : 'location',
                                style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal, // ✅ normal text
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ),

                    /// Estimated arrival
                    Positioned(
                      top: sh(86),
                      left: sw(90),
                      child: Obx(() => Text(
                        "Estimated Arrival: ${c.estimatedArrivalTime.value.isNotEmpty ? c.estimatedArrivalTime.value : '0000'}",
                        style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(fontSize: 10),
                      )),
                    ),

                    /// Estimated dropoff
                    Positioned(
                      top: sh(109),
                      left: sw(90),
                      child: Obx(() => Text(
                        "Estimated Dropoff: ${c.estimatedDropoffTime.value.isNotEmpty ? c.estimatedDropoffTime.value : '11:00 am'}",
                        style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(fontSize: 10),
                      )),
                    ),

                    /// Estimated distance
                    Positioned(
                      top: sh(132),
                      left: sw(90),
                      child: Obx(() => Text(
                        "Estimated Distance: ${c.estimatedDistance.value.isNotEmpty ? c.estimatedDistance.value : '0 km'}",
                        style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(fontSize: 10),
                      )),
                    ),

                    /// Time (top-right)
                    Positioned(
                      top: sh(12),
                      right: sw(20),
                      child: Text(
                        "2 min",
                        style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    /// Call
                    Positioned(
                      top: sh(50),
                      right: sw(20),
                      child: GestureDetector(
                        onTap: () {
                          launchUrl(Uri(scheme: 'tel', path: c.phone.value));
                        },
                        // onTap: () => c.callPhone(),
                        child: Image.asset("assets/images/call.png", width: sw(30), height: sh(30)),
                      ),
                    ),

                    /// Message
                    Positioned(
                      top: sh(90),
                      right: sw(20),
                      child: GestureDetector(
                        onTap: () => Get.toNamed("/chat", arguments: raw),
                        child: Image.asset("assets/images/chat.png", width: sw(30), height: sh(30)),
                      ),
                    ),

                    /// Fare
                    Positioned(
                      top: sh(157),
                      left: sw(18),
                      child: Obx(() => Row(
                        children: [
                          Container(
                            width: sw(185),
                            height: sh(37),
                            padding: EdgeInsets.symmetric(
                              horizontal: sw(8),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003566),
                              borderRadius: BorderRadius.circular(sw(10)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: sw(48),
                                  height: sh(30),
                                  padding: EdgeInsets.symmetric(vertical: 1),
                                  decoration: BoxDecoration(
                                    color: FColors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Image.asset("assets/images/cash.png"),
                                ),
                                SizedBox(width: sw(8)),
                                Text(
                                  'PKR ${c.fare.value.toStringAsFixed(0)}',
                                  style: FTextTheme.lightTextTheme.headlineSmall!.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: FColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
            ),

            /// "I am at pickup location" Button
            Obx(() => c.rideStarted.value
                ? const SizedBox.shrink()
                : Positioned(
              top: sh(749),
              left: sw(30),
              child: GestureDetector(
                onTap: () => c.markDriverArrived(),
                child: Container(
                  width: sw(393),
                  height: sh(52),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 195, 0, 1),
                    borderRadius: BorderRadius.circular(sw(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "I am at pick up Location",
                        style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: sw(14),
                        ),
                      ),
                      SizedBox(width: sw(12)),
                      Icon(Icons.arrow_forward_ios, color: Colors.black, size: sw(18)),
                    ],
                  ),
                ),
              ),
            )),

            /// Cancel Ride
            Positioned(
              top: sh(821),
              left: sw(30),
              right: sw(30),
              child: GestureDetector(
                onTap: () => c.showCancelReasons(context),
                child: Row(
                  children: [
                    Image.asset("assets/images/vector_icon.png", width: sw(20), height: sh(20)),
                    SizedBox(width: sw(8)),
                    Text(
                      "Cancel Ride",
                      style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const Spacer(),
                    Image.asset("assets/images/polygon_icon.png", width: sw(18), height: sh(18)),
                  ],
                ),
              ),
            ),

            /// Start / Complete Ride Button
            Obx(() => Positioned(
              top: sh(870),
              left: sw(30),
              right: sw(30),
              child: SizedBox(
                height: sh(52),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw(12))),
                  ),
                  onPressed: (c.isStartingRide.value || c.isCompletingRide.value) ? null : () {
                    if (!c.rideStarted.value) {
                      c.markDriverStarted();
                    } else {
                      c.markDriverEnded();
                    }
                  },
                  child: (c.isStartingRide.value || c.isCompletingRide.value)
                      ? SizedBox(
                    width: sw(20),
                    height: sw(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    c.rideStarted.value ? "Mark Complete" : "Start a Ride",
                    style: FTextTheme.darkTextTheme.labelLarge,
                  ),
                ),
              ),
            )),

            /// ✅ ADDED: Fullscreen loader overlay for THREE SPECIFIC ACTIONS
            if (c.isStartingRide.value || c.isCompletingRide.value || c.isCancelingRide.value)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        _getLoadingText(c),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ ADDED: Helper method to get appropriate loading text
  String _getLoadingText(GoToPickupController c) {
    if (c.isStartingRide.value) return "Starting ride...";
    if (c.isCompletingRide.value) return "Completing ride...";
    if (c.isCancelingRide.value) return "Canceling ride...";
    return "Loading...";
  }
}