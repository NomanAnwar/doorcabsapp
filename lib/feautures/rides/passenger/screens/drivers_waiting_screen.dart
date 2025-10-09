import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/drivers_waiting_controller.dart';

class DriversWaitingScreen extends StatelessWidget {
  const DriversWaitingScreen({super.key});

  Future<void> _call(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Could not launch dialer");
    }
  }



  @override
  Widget build(BuildContext context) {
    final driverArg = Get.arguments as Map<String, dynamic>? ?? {};
    final c = Get.put(DriversWaitingController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    final driverPhone = driverArg['phone']?.toString() ?? '03244227502';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          height: screenHeight,
          width: screenWidth,
          child: Stack(
            children: [
              /// Map background (from top to 510)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: c.updateView.value ? sh(450) : sh(510),
                child: Obx(() {
                  if (c.currentPosition.value == null) {
                    return Center(child: CircularProgressIndicator(strokeWidth: sw(2)));
                  }
                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: c.currentPosition.value!,
                      zoom: 14,
                    ),
                    // myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: c.onMapCreated,
                    markers: c.driverMarkers.values.toSet(),
                    polylines: c.polylines.value, // --- FIX: added to show polyline
                  );
                }),
              ),

              /// Back button (top 39 left 33)
              Positioned(
                top: sh(39),
                left: sw(33),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: sw(24)),
                  onPressed: () => Get.back(),
                ),
              ),

              /// Driver card container (top 510 → height 145, width 420, bg e3e3e3, radius 14)
              Positioned(
                top: sh(524),
                left: sw(10),
                child: Container(
                  width: sw(420),
                  height: c.updateView.value ? sh(195) : sh(145),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E3E3),
                    borderRadius: BorderRadius.circular(sw(14)),
                  ),
                ),
              ),

              /// Driver Image (top 533 left 28, w=68.25 h=65)
              Positioned(
                top: sh(547),
                left: sw(28),
                child: Container(
                  width: sw(68.25),
                  height: sh(65),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image:
                      // (driverArg['avatar'] != null &&
                      //     driverArg['avatar'].toString().isNotEmpty &&
                      //     driverArg['avatar'].toString() != "https://via.placeholder.com/150")
                      //     ? NetworkImage(driverArg['avatar'].toString())
                      //     : const
                      AssetImage("assets/images/profile_img_sample.png") as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              /// Badge near driver image (top 597.42 left 84.33, w=11.92 h=11.92)
              Positioned(
                top: sh(591.42),
                left: sw(84.33),
                child: Icon(Icons.verified, color: Colors.green, size: sw(11.92)),
              ),

              /// Star icon + rating + total ratings
              Positioned(
                top: sh(623),
                left: sw(23),
                child: Icon(Icons.star, color: Colors.amber, size: sw(14)),
              ),
              Positioned(
                top: sh(623),
                left: sw(42),
                child: Text(driverArg['rating']?.toString() ?? "0.0",
                    style: TextStyle(fontSize: sw(12), fontWeight: FontWeight.bold)),
              ),
              Positioned(
                top: sh(623),
                left: sw(62),
                child: Text("(${driverArg['totalRatings'] ?? 0})",
                    style: TextStyle(fontSize: sw(12), color: Colors.grey)),
              ),

              /// Driver category (top 641 left 23)
              Positioned(
                top: sh(640),
                left: sw(23),
                child: Text(driverArg['category'] ?? "Platinum",
                    style: TextStyle(fontSize: sw(12), color: Colors.grey)),
              ),

              /// Driver name (top 553 left 113)
              Positioned(
                top: sh(547),
                left: sw(113),
                child: Text(c.rideInfo.value?.driver?['name']?['firstName'] ?? "N/A",
                    style: TextStyle(fontSize: sw(16), fontWeight: FontWeight.bold)),
              ),

              /// Car model (top 576 left 113)
              Positioned(
                top: sh(570),
                left: sw(113),
                child: Text(c.rideInfo.value?.driver?['vehicle'] ?? "N/A",
                    style: TextStyle(fontSize: sw(14), color: Colors.black54)),
              ),

              /// Estimated arrival time (top 598 left 113)
              Positioned(
                top: sh(592),
                left: sw(113),
                child: Text("Estimated Arrival: ${c.rideInfo.value?.eta ?? ''}",
                    style: TextStyle(fontSize: sw(12), color: Colors.black87)),
              ),

              /// Fare (top 628 left 113)
              Positioned(
                top: sh(622),
                left: sw(113),
                child: Text("PKR ${c.rideInfo.value?.fareOffered ?? 0}",
                    style: FTextTheme.lightTextTheme.displaySmall!.copyWith(fontWeight: FontWeight.w600)),
              ),

              /// Driver time (top 542 left 327)
              Positioned(
                top: sh(536),
                left: sw(300),
                child: Text("${c.rideInfo.value?.distance ?? ''} ",
                    style: TextStyle(fontSize: sw(14))),
              ),

              /// Driver distance (top 542 left 373)
              Positioned(
                top: sh(536),
                left: sw(363),
                child: Text("${driverArg['distance'] ?? '20.6'} km",
                    style: TextStyle(fontSize: sw(14))),
              ),

              /// Call icon button (top 568 left 374, w=30 h=30)
              Positioned(
                top: sh(562),
                left: sw(374),
                child: SizedBox(
                  width: sw(30),
                  height: sh(30),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Image.asset("assets/images/call.png"),
                    // onPressed: () => c.onInit(),
                    onPressed: () => _call(driverPhone),
                  ),
                ),
              ),

              /// Message icon button (top 612 left 375, w=30 h=30)
              Positioned(
                top: sh(606),
                left: sw(375),
                child: SizedBox(
                  width: sw(30),
                  height: sh(30),
                  child:
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: Image.asset("assets/images/chat.png"),
                    onPressed: () => Get.toNamed("/chat-with_driver", arguments: {"rideId": c.rideId, "driverId": c.driverId,},),
                  ),
                ),
              ),

              /// Pickup location field (top 708 left 19, w=393 h=52)
              Positioned(
                top: sh(683),
                left: sw(19),
                child: Container(
                  width: sw(393),
                  height: sh(52),
                  padding: EdgeInsets.symmetric(horizontal: sw(14)),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(sw(14)),
                  ),
                  child: Row(
                    children: [
                      Image.asset("assets/images/place.png"),
                      SizedBox(width: sw(12)),
                      Expanded(
                        child: Text(
                          c.rideInfo.value?.pickup?['address'] ??
                              "Plot 701, Township Block 2 Sector D1 Lahore",
                          style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(fontSize: sw(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// Dropoff location field (top 780 left 18, w=393 h=52)
              Positioned(
                top: sh(751),
                left: sw(19),
                child: Container(
                  width: sw(393),
                  height: sh(52),
                  padding: EdgeInsets.symmetric(horizontal: sw(14)),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(sw(14)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: sw(20)),
                      SizedBox(width: sw(12)),
                      Expanded(
                        child: Text(
                          c.rideInfo.value?.dropoffs.isNotEmpty == true ? c.rideInfo.value!.dropoffs[0]['address'] : "",
                          style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(fontSize: sw(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Cancel Ride
              Positioned(
                top: sh(825),
                left: sw(27),
                right: sw(30),
                child: GestureDetector(
                  onTap: ()=> c.showCancelReasons(context),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/vector_icon.png",
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Cancel Ride",
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold)
                            ?.copyWith(color: Colors.red),
                      ),
                      const Spacer(),
                      Transform.rotate(
                        angle: 0,
                        child: Image.asset(
                          "assets/images/vector_icon.png",
                          width: 18,
                          height: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              /// Cancel Ride button (top 866 left 41, w=358 h=48)
              Positioned(
                top: sh(866),
                left: sw(41),
                child: SizedBox(
                  width: sw(358),
                  height: sh(48),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(sw(12)),
                      ),
                    ),
                    onPressed: () => {},
                    child: Text("+ New Request", style: FTextTheme.darkTextTheme.labelLarge),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
