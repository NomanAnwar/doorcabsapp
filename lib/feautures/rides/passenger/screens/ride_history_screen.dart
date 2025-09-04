import 'package:doorcab/utils/constants/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/ride_history_controller.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RideHistoryController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // back row
            Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
                const Spacer(),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Text("My Ride & Delivery", style: FTextTheme.lightTextTheme.titleLarge),
            ),

            const SizedBox(height: 12),
            Expanded(
              child: Obx(() => ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                itemCount: c.rides.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final ride = c.rides[i];
                  return GestureDetector(
                    onTap: () => c.openDetail(ride),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.yellow.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Image.asset(FImages.city_to_city),),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(ride['title'], style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(ride['date'] ?? '', style: const TextStyle(color: Colors.black54)),
                            ]),
                          ),
                          Text("PKR ${ride['fare']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }
}
