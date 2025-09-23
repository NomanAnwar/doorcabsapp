import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final driverArg = Get.arguments as Map<String, dynamic>? ?? {};
    final c = Get.put(DriversWaitingController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    if (driverArg.containsKey('fare')) {
      c.fareController.text = driverArg['fare'].toString();
    }

    final driverPhone = driverArg['phone']?.toString() ?? '03244227502';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              /// Map background (full)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: sh(500),
                child: Obx(() {
                  if (c.currentPosition.value == null) {
                    return Center(child: CircularProgressIndicator(strokeWidth: sw(2)));
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

              /// Back button (top 39 left 33)
              Positioned(
                top: sh(39),
                left: sw(33),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: sw(24)),
                  onPressed: () => Get.back(),
                ),
              ),

              /// Grey driver card at top 510
              Positioned(
                top: sh(510),
                left: sw(10),
                right: sw(10),
                child: Container(
                  height: sh(165),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E3E3),
                    borderRadius: BorderRadius.circular(sw(14)),
                  ),
                  child: Stack(
                    children: [
                      /// Driver avatar
                      Positioned(
                        top: sh(23),
                        left: sw(18),
                        child: CircleAvatar(
                          radius: sw(32),
                          backgroundImage: AssetImage(driverArg['avatar'] ?? "assets/images/profile_img_sample.png"),
                        ),
                      ),

                      /// Small badge near avatar
                      Positioned(
                        top: sh(87),
                        left: sw(74),
                        child: Icon(Icons.verified, color: Colors.green, size: sw(12)),
                      ),

                      /// Star icon, rating and total ratings
                      Positioned(
                        top: sh(115),
                        left: sw(18),
                        child: Icon(Icons.star, color: Colors.amber, size: sw(14)),
                      ),
                      Positioned(
                        top: sh(119),
                        left: sw(38),
                        child: Text(
                            driverArg['rating']?.toString() ?? "4.9",
                            style: TextStyle(fontSize: sw(12), fontWeight: FontWeight.bold)
                        ),
                      ),
                      Positioned(
                        top: sh(119),
                        left: sw(58),
                        child: Text(
                            "(${driverArg['totalRatings'] ?? 120})",
                            style: TextStyle(fontSize: sw(12), color: Colors.grey)
                        ),
                      ),
                      Positioned(
                        top: sh(131),
                        left: sw(18),
                        child: Text(
                            driverArg['category'] ?? "Platinum driver",
                            style: TextStyle(fontSize: sw(12), color: Colors.grey)
                        ),
                      ),

                      /// Name, car, eta, fare
                      Positioned(
                        top: sh(30),
                        left: sw(104),
                        child: Text(
                            driverArg['name'] ?? "Malik Shahid",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: sw(16))
                        ),
                      ),
                      Positioned(
                        top: sh(55),
                        left: sw(104),
                        child: Text(
                            driverArg['car'] ?? "Suzuki Alto",
                            style: TextStyle(fontSize: sw(14), color: Colors.grey)
                        ),
                      ),
                      Positioned(
                        top: sh(78),
                        left: sw(104),
                        child: Text(
                            "Estimated Arrival Time: ${driverArg['etaText'] ?? '11:05 PM'}",
                            style: TextStyle(fontSize: sw(12), color: Colors.black54)
                        ),
                      ),
                      Positioned(
                        top: sh(110),
                        left: sw(104),
                        child: Text(
                            "PKR ${driverArg['fare'] ?? '250'}",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: sw(16))
                        ),
                      ),

                      /// Time & distance
                      Positioned(
                        top: sh(12),
                        right: sw(80),
                        child: Text(
                            "${driverArg['eta'] ?? 2} min",
                            style: TextStyle(fontSize: sw(14))
                        ),
                      ),
                      Positioned(
                        top: sh(12),
                        right: sw(25),
                        child: Text(
                            "${driverArg['distance'] ?? '0.65'} km",
                            style: TextStyle(fontSize: sw(14))
                        ),
                      ),

                      /// Call button
                      Positioned(
                        top: sh(58),
                        right: sw(54),
                        child: SizedBox(
                          width: sw(30),
                          height: sh(30),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.call, size: sw(22), color: Colors.blue),
                            onPressed: () => _call(driverPhone),
                          ),
                        ),
                      ),

                      /// Message button
                      Positioned(
                        top: sh(100),
                        right: sw(52),
                        child: SizedBox(
                          width: sw(30),
                          height: sh(30),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.message, size: sw(22), color: Colors.blue),
                            onPressed: () => Get.toNamed("/chat-with_driver", arguments: driverArg),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// Pickup field (top 708 left 19)
              Positioned(
                top: sh(708),
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
                      Icon(Icons.my_location, size: sw(20)),
                      SizedBox(width: sw(12)),
                      Expanded(
                        child: Text(
                            driverArg['pickup']?['address']?.toString() ?? "Model Town Link Rd Zainab Tower",
                            style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(fontSize: sw(14))
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// Dropoff field (top 780 left 18)
              Positioned(
                top: sh(780),
                left: sw(18),
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
                            driverArg['dropoffs']?[0]?['address']?.toString() ?? "Township",
                            style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(fontSize: sw(14))
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// Cancel Ride button (top 866 left 41)
              Positioned(
                top: sh(866),
                left: sw(41),
                child: SizedBox(
                  width: sw(358),
                  height: sh(48),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw(12)))
                    ),
                    onPressed: () => _showCancelDialog(context, c),
                    child: Text(
                      "Cancel Ride",
                      style: FTextTheme.darkTextTheme.labelLarge,
                    ),
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