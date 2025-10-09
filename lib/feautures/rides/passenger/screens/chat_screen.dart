// lib/feautures/rides/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../controllers/chat_controller.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  String _formatTs(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final suf = dt.hour >= 12 ? "PM" : "AM";
    final min = dt.minute.toString().padLeft(2, '0');
    return "$hour:$min $suf";
  }

  @override
  Widget build(BuildContext context) {
    final args = Map<String, dynamic>.from(Get.arguments ?? {});
    final c = Get.put(ChatController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Back button
          PositionedScaled(
            top: 39,
            left: 33,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
            ),
          ),

          // Header card with driver info
          PositionedScaled(
            top: 98,
            left: 10,
            right: 10,
            child: Container(
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E3E3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: AssetImage(
                      // args['avatar'] ??
                          "assets/images/profile_img_sample.png",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(args['name'] ?? "Driver",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(args['car'] ?? "Car",
                            style: const TextStyle(color: Colors.grey)),
                        Text("ETA: ${args['etaText'] ?? '--'}",
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.blue),
                    onPressed: () {
                      final phone = args['phone']?.toString() ?? "";
                      if (phone.isNotEmpty) {
                        launchUrl(Uri(scheme: 'tel', path: phone));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Messages list
          PositionedScaled(
            top: 230,
            left: 0,
            right: 0,
            bottom: 80,
            child: Obx(
                  () => ListView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: c.messages.length,
                itemBuilder: (_, i) {
                  final m = c.messages[i];
                  final isDriver = m['from'] == 'driver';
                  return Align(
                    alignment:
                    isDriver ? Alignment.centerLeft : Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: isDriver
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDriver
                                ? const Color(0xFFEFEFEF)
                                : const Color(0xFFDDE6FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(m['text'] ?? ""),
                        ),
                        Text(
                          _formatTs(m['ts']),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Input bar
          PositionedScaled(
            bottom: 12,
            left: 12,
            right: 12,
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
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: c.sendMessage,
                        ),
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
