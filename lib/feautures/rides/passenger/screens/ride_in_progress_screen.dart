import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../../utils/constants/colors.dart';
import '../controllers/ride_in_progress_controller.dart';
import '../models/driver_model.dart';
import 'package:url_launcher/url_launcher.dart';

class RideInProgressScreen extends StatelessWidget {
  const RideInProgressScreen({super.key});

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      Get.snackbar("Cannot call", "Your device doesn't support calling.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map? incoming = Get.arguments as Map?;
    final c = Get.put(RideInProgressController());
    if (incoming != null) {
      c.setDriverFromArgs(incoming);
    }

    // start auto-navigation to RateDriver screen after 30s
    // c.startAutoNavigateToRating(delaySeconds: 30);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PositionedScaled(
            top: 0,
            left: 0,
            right: 0,
            height: 510, // design: map until 510
            child: Obx(() {
              if (c.currentPosition.value == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return GoogleMap(
                initialCameraPosition: CameraPosition(target: c.currentPosition.value!, zoom: 14),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: c.onMapCreated,
              );
            }),
          ),

          // Back
          PositionedScaled(
            top: 39,
            left: 33,
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: Get.back),
          ),

          // Grey driver box overlapping map (same placement as DriversWaiting)
          PositionedScaled(
            top: 510,
            left: 10,
            right: 10,
            child: Obx(() {
              final driver = c.driver.value;
              return Container(
                height: 145,
                decoration: BoxDecoration(color: const Color(0xFFE3E3E3), borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: AssetImage(driver?.avatar ?? 'assets/images/profile_img_sample.png'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driver?.name ?? 'Driver', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(driver?.car ?? '', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 6),
                            Text('Estimated Distance: ${driver?.distance.toStringAsFixed(2) ?? '0.65'} km', style: const TextStyle(fontSize: 12)),
                            Text('Estimated Arrival Time: ${driver?.eta ?? 0} min', style: const TextStyle(fontSize: 12)),
                            // more details if needed:
                            // Text('Estimated Drop Time: 11:25 PM', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${driver?.eta ?? 2} min'),
                          Text('${driver?.distance.toStringAsFixed(2) ?? '0.65'} km'),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.call, size: 22, color: Colors.blue),
                              onPressed: () {
                                if (driver?.phone != null && driver!.phone.isNotEmpty) _call(driver.phone);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.message, size: 22, color: Colors.blue),
                              onPressed: () => Get.toNamed('/chat-with_driver', arguments: driver?.toMap() ?? {}),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            }),
          ),

          // pickup field
          PositionedScaled(
            top: 708,
            left: 19,
            child: Obx(() {
              final p = c.driver.value?.pickup ?? "Model Town Link Rd Zainab Tower";
              return Container(
                width: 393,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [const Icon(Icons.my_location), const SizedBox(width: 12), Expanded(child: Text(p))]),
              );
            }),
          ),

          // dropoff
          PositionedScaled(
            top: 780,
            left: 18,
            child: Obx(() {
              final d = c.driver.value?.dropoff ?? "Township";
              return Container(
                width: 393,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [const Icon(Icons.location_on), const SizedBox(width: 12), Expanded(child: Text(d))]),
              );
            }),
          ),

          // Cancel Ride button
          PositionedScaled(
            top: 866,
            left: 41,
            child: SizedBox(
              width: 358,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => c.cancelRide(),
                child: const Text("Cancel Ride"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
