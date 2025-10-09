// go_to_pickup_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../driver/screens/reuseable_widgets/drawer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/go_to_pickup_controller.dart';

class GoToPickupScreen extends StatelessWidget {
  const GoToPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace DriversWaitingController with GoToPickupController
    final c = Get.put(GoToPickupController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference (iPhone 16 Pro Max)
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
            /// Map (top → till 510)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: sh(520),
              child: Obx(() {
                if (c.currentPosition.value == null && c.pickupPosition.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Build initial camera position
                CameraPosition initial;
                if (c.currentPosition.value != null) {
                  initial = CameraPosition(target: c.currentPosition.value!, zoom: 17);
                } else {
                  initial = CameraPosition(target: c.pickupPosition.value!, zoom: 17);
                }

                final poly = c.routePolyline.value;
                final markers = c.markers.toSet();

                return GoogleMap(
                  initialCameraPosition: initial,
                  // myLocationEnabled: true,
                  // myLocationButtonEnabled: false,
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

            /// Driver Info Card
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
                      child: CircleAvatar(
                        radius: sw(30),
                        backgroundImage:
                        AssetImage('assets/images/profile_img_sample.png') as ImageProvider,
                      ),
                    ),

                    /// Passenger Name, Rating Star, and Rating Value in a single row
                    Positioned(
                      top: sh(13),
                      left: sw(90),
                      child: Row(
                        children: [
                          /// Passenger Name
                          Obx(() => Text(
                            c.passengerName.value.isNotEmpty ? c.passengerName.value : "name",
                            style: FTextTheme.lightTextTheme.titleMedium,
                          )),

                          SizedBox(width: sw(15)),
                          // Spacing between name and star

                          /// Passenger Rating Star
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFFFFC300),
                          ),

                          SizedBox(width: sw(5)),
                          // Spacing between star and rating value

                          /// Passenger Rating Value
                          Text(
                            "00",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Pickup
                    Positioned(
                      top: sh(43),
                      left: sw(90),
                      child: Obx(() => RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Pickup: ',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                            TextSpan(
                              text: c.pickupAddress.value.isNotEmpty ? c.pickupAddress.value : 'location',
                              style: const TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ],
                        ),
                      )),
                    ),

                    /// Dropoff
                    Positioned(
                      top: sh(66),
                      left: sw(90),
                      child: Obx(() => RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Dropoff: ',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                            TextSpan(
                              text: c.dropoffAddress.value.isNotEmpty ? c.dropoffAddress.value : 'location',
                              style: const TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ],
                        ),
                      )),
                    ),

                    /// Estimated arrival
                    Positioned(
                      top: sh(89),
                      left: sw(90),
                      child: Obx(() => RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Estimated Arrival time: ',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                            TextSpan(
                              text: c.estimatedArrivalTime.value.isNotEmpty ? c.estimatedArrivalTime.value : '0000',
                              style: const TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ],
                        ),
                      )),
                    ),

                    /// Estimated dropoff
                    Positioned(
                      top: sh(112),
                      left: sw(90),
                      child: Obx(() => RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Estimated Dropoff time: ',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                            TextSpan(
                              text: c.estimatedDropoffTime.value.isNotEmpty ? c.estimatedDropoffTime.value : '11:00 am',
                              style: const TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ],
                        ),
                      )),
                    ),

                    /// Estimated distance
                    Positioned(
                      top: sh(135),
                      left: sw(90),
                      child: Obx(() => RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Estimated Distance: ',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                            TextSpan(
                              text: c.estimatedDistance.value.isNotEmpty ? c.estimatedDistance.value : '0 km',
                              style: const TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ],
                        ),
                      )),
                    ),

                    /// Time (top-right)
                    Positioned(
                      top: sh(12),
                      right: sw(54),
                      child: Text("2 min", style: TextStyle(fontSize: sw(14))),
                    ),

                    /// Call
                    Positioned(
                      top: sh(50),
                      right: sw(54),
                      child: GestureDetector(
                        onTap: () => c.callPhone(),
                        child: Image.asset("assets/images/call.png", width: sw(30), height: sh(30)),
                      ),
                    ),

                    /// Message
                    Positioned(
                      top: sh(90),
                      right: sw(54),
                      child: GestureDetector(
                        onTap: () => Get.toNamed("/chat-with_driver", ),
                        child: Image.asset("assets/images/chat.png", width: sw(30), height: sh(30)),
                      ),
                    ),

                    /// Fare
                    Positioned(
                      top: sh(160),
                      left: sw(40),
                      child: Obx(() => Row(
                        children: [
                          Text("PKR ", style: TextStyle(fontWeight: FontWeight.w600, fontSize: sw(14))),
                          Text("${c.fare.value}", style: TextStyle(fontWeight: FontWeight.w800, fontSize: sw(20))),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
            ),

            /// "I am at pickup location"
            Obx(() => c.rideStarted.value
                ? const SizedBox.shrink() // ✅ hide when ride started
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
                      Text("I am at pick up Location",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: sw(14))),
                      SizedBox(width: sw(12)),
                      Icon(Icons.arrow_forward_ios, color: Colors.black, size: sw(18)),
                    ],
                  ),
                ),
              ),
            ),
            ),

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
                    Text("Cancel Ride", style: TextStyle(fontSize: sw(14), fontWeight: FontWeight.bold, color: Colors.red)),
                    const Spacer(),
                    Image.asset("assets/images/polygon_icon.png", width: sw(18), height: sh(18)),
                  ],
                ),
              ),
            ),

            /// Start Ride Button
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
                  onPressed: () {
                    if (!c.rideStarted.value) {
                      c.markDriverStarted();
                    } else {
                      c.markDriverEnded();
                    }
                  },
                  child: Text(
                    c.rideStarted.value ? "Mark Complete" : "Start a Ride",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: sw(16), color: Colors.white),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
