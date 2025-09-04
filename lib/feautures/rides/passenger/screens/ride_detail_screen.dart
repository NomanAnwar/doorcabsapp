import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../../utils/constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class RideDetailScreen extends StatelessWidget {
  const RideDetailScreen({super.key});

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
    final rawArgs = Get.arguments;
    final args = Map<String, dynamic>.from(rawArgs ?? {});
    final driverMap = Map<String, dynamic>.from(args['driver'] ?? {});
    final name = driverMap['name'] ?? 'Driver';
    final avatar = driverMap['avatar'] ?? 'assets/images/profile_img_sample.png';
    final fare = args['fare'] ?? 250;
    final promo = args['promo'] ?? 70;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Row(children: [IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back())]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 32, backgroundImage: AssetImage(avatar)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(driverMap['car'] ?? '', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 6),
                            Text('Arrival Time: ${args['arrival'] ?? '11:05 PM'}'),
                            Text('Drop Time: ${args['drop'] ?? '11:25 PM'}'),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text("PKR $fare", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.call, color: Colors.blue),
                              onPressed: () => _call(driverMap['phone'] ?? '03244227502'),
                            ),
                          )
                        ])
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price breakdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Ride Price"), Text("PKR ${args['ridePrice'] ?? (fare + promo)}")]),
                        const SizedBox(height: 6),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Promo Amount"), Text("PKR $promo")]),
                        const SizedBox(height: 6),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total"), Text("PKR $fare")]),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.yellow.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Row(children: const [
                            Icon(Icons.money, size: 20),
                            SizedBox(width: 8),
                            Text("Cash"),
                          ]),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text("Send report to email"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Get.snackbar("Not implemented", "This is a stub"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text("Delete Record", style: TextStyle(color: Colors.red)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Get.back(); // or implement deletion
                      Get.snackbar("Deleted", "Record removed");
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
