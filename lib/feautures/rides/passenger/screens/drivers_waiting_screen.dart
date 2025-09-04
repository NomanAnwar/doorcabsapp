// lib/feautures/rides/screens/drivers_waiting_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../../utils/constants/colors.dart';
import '../controllers/drivers_waiting_controller.dart';

class DriversWaitingScreen extends StatelessWidget {
  const DriversWaitingScreen({super.key});


  Future<void> _call(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Could not launch dialer");
    }
  }


  void _showCancelDialog(BuildContext ctx, DriversWaitingController c) {
    Get.defaultDialog(
      title: "Cancel Ride",
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("Driver took too long"),
            onTap: () { c.cancelRide(); },
          ),
          ListTile(
            title: const Text("Change of plans"),
            onTap: () { c.cancelRide(); },
          ),
          ListTile(
            title: const Text("Found another ride"),
            onTap: () { c.cancelRide(); },
          ),
          ListTile(
            title: const Text("Other reason"),
            onTap: () { c.cancelRide(); },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Expect Get.arguments to be driver map from bids screen
    final driverArg = Get.arguments as Map<String, dynamic>? ?? {};
    final c = Get.put(DriversWaitingController());

    // If fare in args populate
    if (driverArg.containsKey('fare')) {
      c.fareController.text = driverArg['fare'].toString();
    }

    // Example driver phone from args (fallback)
    final driverPhone = driverArg['phone']?.toString() ?? '03244227502';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map background (full)
          PositionedScaled(
            top: 0, left: 0, right: 0, bottom: 0,
            child: Obx(() {
              if (c.currentPosition.value == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: c.currentPosition.value!,
                  zoom: 14,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: c.onMapCreated,
                markers: c.driverMarkers.values.toSet(),
              );
            }),
          ),

          // Back button (top 39 left 33 in your design)
          PositionedScaled(
            top: 39, left: 33,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
            ),
          ),

          // Grey driver card at ~ top 510 area: using PositionedScaled to place container starting at top 510 design
          // We'll place the grey small card at top ~510 so bottom white container remains visible.
          PositionedScaled(
            top: 510, // design: map till 510 then card begins
            left: 10,
            right: 10,
            child: Container(
              height: 145,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E3E3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  // Driver avatar (top 533 from overall screen in your spec -> relative to this container top 23)
                  PositionedScaled(top: 23, left: 18, child: CircleAvatar(
                    radius: 32,
                    backgroundImage: AssetImage(driverArg['avatar'] ?? "assets/images/profile_img_sample.png"),
                  )),

                  // Small badge near avatar
                  PositionedScaled(top: 87, left: 74, child: const Icon(Icons.verified, color: Colors.green, size: 12)),

                  // Star icon, rating and total ratings (left column)
                  PositionedScaled(top: 115, left: 18, child: const Icon(Icons.star, color: Colors.amber, size: 14)),
                  PositionedScaled(top: 119, left: 38, child: Text(driverArg['rating']?.toString() ?? "4.9", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  PositionedScaled(top: 119, left: 58, child: Text("(${driverArg['totalRatings'] ?? 120})", style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  PositionedScaled(top: 131, left: 18, child: Text(driverArg['category'] ?? "Platinum driver", style: const TextStyle(fontSize: 12, color: Colors.grey))),

                  // Name, car, eta, fare (middle column)
                  PositionedScaled(top: 30, left: 104, child: Text(driverArg['name'] ?? "Malik Shahid", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  PositionedScaled(top: 55, left: 104, child: Text(driverArg['car'] ?? "Suzuki Alto", style: const TextStyle(fontSize: 14, color: Colors.grey))),
                  PositionedScaled(top: 78, left: 104, child: Text("Estimated Arrival Time: ${driverArg['etaText'] ?? '11:05 PM'}", style: const TextStyle(fontSize: 12, color: Colors.black54))),
                  PositionedScaled(top: 110, left: 104, child: Text("PKR ${driverArg['fare'] ?? '250'}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),

                  // Right column: time & distance
                  PositionedScaled(top: 12, left: null, right: 80, child: Text("${driverArg['eta'] ?? 2} min", style: const TextStyle(fontSize: 14))),
                  PositionedScaled(top: 12, left: null, right: 25, child: Text("${driverArg['distance'] ?? '0.65'} km", style: const TextStyle(fontSize: 14))),

                  // Call button at top 568 left 374 design => relative to this container right area
                  PositionedScaled(top: 58, left: null, right: 54, child: SizedBox(
                    width: 30, height: 30,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.call, size: 22, color: Colors.blue),
                      onPressed: () => _call(driverPhone),
                    ),
                  )),

                  // Message button (below call)
                  PositionedScaled(top: 100, left: null, right: 52, child: SizedBox(
                    width: 30, height: 30,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.message, size: 22, color: Colors.blue),
                      onPressed: () => Get.toNamed("/chat-with_driver", arguments: driverArg),
                    ),
                  )),
                ],
              ),
            ),
          ),

          // Pickup field (top 708 left 19 width 393 height 52)
          PositionedScaled(
            top: 708,
            left: 19,
            child: Container(
              width: 393,
              height: 52,
              padding: EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location),
                  const SizedBox(width: 12),
                  Expanded(child: Text(driverArg['pickup']?.toString() ?? "Model Town Link Rd Zainab Tower", style: FTextTheme.lightTextTheme.bodyLarge)),
                ],
              ),
            ),
          ),

          // Dropoff field (top 780 left 18)
          PositionedScaled(
            top: 780,
            left: 18,
            child: Container(
              width: 393,
              height: 52,
              padding: EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 12),
                  Expanded(child: Text(driverArg['dropoff']?.toString() ?? "Township", style: FTextTheme.lightTextTheme.bodyLarge)),
                ],
              ),
            ),
          ),

          // Cancel Ride button at top 866 left 41 width 358 height 48
          PositionedScaled(
            top: 866,
            left: 41,
            child: SizedBox(
              width: 358,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => _showCancelDialog(context, c),
                child: const Text("Cancel Ride"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
