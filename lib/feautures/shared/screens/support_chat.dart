import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../controllers/support_chat_controller.dart';

class SupportChat extends StatelessWidget {
  final SupportChatController controller = Get.put(SupportChatController());
  final TextEditingController textController = TextEditingController();

  SupportChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Back Arrow
          Positioned(
            top: 39,
            left: 33,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: SvgPicture.asset(
                "assets/images/Arrow.svg", // external SVG
                width: 28.01,
              ),
            ),
          ),

          // Title
          Positioned(
            top: 62,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "Support",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
// Chat area
          Positioned.fill(
            top: 115,
            bottom: 80,
            child: Obx(() {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = controller.messages[index];

                  return Column(
                    crossAxisAlignment:
                    msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (index == 0 && !msg.isUser && msg.name != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: AssetImage(msg.avatar),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.name!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Text(
                                    "Support Agent",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // ✅ Label above each message ("Sophia" or "You")
                      Padding(
                        padding: EdgeInsets.only(
                          left: msg.isUser ? 0 : 50, // align with avatar
                          right: msg.isUser ? 50 : 0,
                          bottom: 4,
                        ),
                        child: Text(
                          msg.isUser ? "You" : msg.name ?? "Agent",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      // ✅ Message Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: msg.isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!msg.isUser) ...[
                            // small agent avatar
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: AssetImage(msg.avatar),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: msg.isUser
                                    ? const Color(0xFFFFD700) // yellow for user
                                    : Colors.grey.shade200, // light gray for agent
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                msg.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: msg.isUser ? Colors.black : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          if (msg.isUser) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: AssetImage(msg.avatar),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 12),
                    ],
                  );
                },
              );
            }),
          ),

          Positioned(
            left: 10,
            bottom: 19,
            child: Container(
              width: 420,
              height: 51,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(227, 227, 227, 1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: "Write Message",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      controller.sendMessage(textController.text);
                      textController.clear();
                    },
                    child: const Icon(Icons.send, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
