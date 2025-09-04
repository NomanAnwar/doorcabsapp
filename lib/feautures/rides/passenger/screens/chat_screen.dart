// lib/feautures/rides/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../../utils/constants/colors.dart';
import '../controllers/chat_controller.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  String _formatTs(DateTime dt) {
    final d = "${dt.day.toString().padLeft(2,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.year}";
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final suf = dt.hour >= 12 ? "PM" : "AM";
    final min = dt.minute.toString().padLeft(2,'0');
    return "$d $hour:$min $suf";
  }

  @override
  Widget build(BuildContext context) {
    final driverArg = Map<String, dynamic>.from(Get.arguments ?? {});

    final c = Get.put(ChatController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Back button top 39 left 33
          PositionedScaled(top: 39, left: 33, child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back())),

          // Top driver card (top 68 left 10 width 420 height 112)
          PositionedScaled(
            top: 68, left: 10, right: 10,
            child: Container(
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E3E3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  PositionedScaled(top: 23, left: 17, child: CircleAvatar(radius: 32, backgroundImage: AssetImage(driverArg['avatar'] ?? "assets/images/profile_img_sample.png"))),
                  PositionedScaled(top: 67, left: 78, child: const Icon(Icons.verified, color: Colors.green, size: 12)),
                  // Name / car / rating
                  PositionedScaled(top: 15, left: 113, child: Text(driverArg['name'] ?? "Malik shahid", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  PositionedScaled(top: 42, left: 113, child: Text(driverArg['car'] ?? "Suzuki Alto", style: const TextStyle(color: Colors.grey))),
                  PositionedScaled(top: 72, left: 113, child: Text("ETA: ${driverArg['etaText'] ?? '11:05 PM'}", style: const TextStyle(color: Colors.black54, fontSize: 12))),
                  // Rating block
                  PositionedScaled(top: 95, left: 113, child: Row(children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(driverArg['rating']?.toString() ?? "4.9", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text("(${driverArg['totalRatings'] ?? 120})", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ])),
                  // Call icon (top 109 left 382 design)
                  PositionedScaled(top: 41, left: null, right: 20, child: SizedBox(
                    width: 30, height: 30,
                    child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.call, color: Colors.blue), onPressed: () {
                      final phone = driverArg['phone']?.toString() ?? "1234567890";
                      final uri = Uri(scheme: 'tel', path: phone);
                      launchUrl(uri);
                    }),
                  )),
                ],
              ),
            ),
          ),

          // Messages list (below header) -> we keep it from top ~190 to bottom - input height
          PositionedScaled(
            top: 190, left: 0, right: 0, bottom: 80,
            child: Obx(() => ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: c.messages.length,
              itemBuilder: (_, i) {
                final m = c.messages[i];
                final from = m['from'] as String;
                final text = m['text'] as String;
                final ts = m['ts'] as DateTime;
                final isDriver = from == 'driver';
                // driver messages align left, passenger align right
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: isDriver ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDriver ? const Color(0xFFEFEFEF) : const Color(0xFFDDE6FF),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isDriver ? 14 : 4),
                            topRight: Radius.circular(isDriver ? 4 : 14),
                            bottomLeft: const Radius.circular(14),
                            bottomRight: const Radius.circular(14),
                          ),
                        ),
                        child: Text(text),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: EdgeInsets.only(left: isDriver ? 8 : 0, right: isDriver ? 0 : 8),
                        child: Text(_formatTs(ts), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                    ],
                  ),
                );
              },
            )),
          ),

          // Bottom input bar
          PositionedScaled(
            bottom: 12, left: 12, right: 12,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: c.inputCtrl,
                            decoration: const InputDecoration(
                              hintText: "Write Message",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.send), onPressed: c.sendMessage),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
