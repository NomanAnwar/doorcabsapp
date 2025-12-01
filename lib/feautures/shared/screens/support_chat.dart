// support_chat.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../controllers/support_chat_controller.dart';
import '../models/support_chat_model.dart';
import '../services/storage_service.dart';

class SupportChat extends StatelessWidget {
  final SupportChatController controller = Get.put(SupportChatController());
  final TextEditingController textController = TextEditingController();

  SupportChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Back Arrow
            Positioned(
              top: 23,
              left: 23,
              child: GestureDetector(
                onTap: () {
                  if (controller.chatStatus.value == 'ended') {
                    StorageService.clearSupportChat();
                  }
                  Get.back();
                },
                child: Container(
                  child: SvgPicture.asset(
                    "assets/images/Arrow.svg",
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
            ),

            // Title
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  "Support",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            // Chat area
            Positioned.fill(
              top: 40,
              bottom: 80,
              child: Obx(() {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  reverse: false,
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final msg = controller.messages[index];

                    return _buildMessageBubble(msg, index);
                  },
                );
              }),
            ),

            // Input Area
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildInputArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, int index) {
    // Helper function to create CircleAvatar with proper image handling
    Widget _buildUserAvatar(String avatarPath) {
      if (avatarPath.startsWith('http')) {
        // Network image for profile photo
        return CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(avatarPath),
        );
      } else {
        // Asset image for default images
        return CircleAvatar(
          radius: 16,
          backgroundImage: AssetImage(avatarPath),
        );
      }
    }

    return Column(
      crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (index == 0 && !msg.isUser && msg.name != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
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

        // Label above each message
        if (index > 0 || msg.isUser)
          Padding(
            padding: EdgeInsets.only(
              left: msg.isUser ? 0 : 50,
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

        // Message Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!msg.isUser) ...[
              _buildUserAvatar(msg.avatar),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: msg.isUser
                      ? const Color(0xFFFFD700)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: msg.isUser ? Colors.black : Colors.black87,
                        ),
                      ),
                    ),
                    if (msg.isUser) ...[
                      const SizedBox(width: 8),
                      _buildMessageStatus(msg.status),
                    ],
                  ],
                ),
              ),
            ),
            if (msg.isUser) ...[
              const SizedBox(width: 8),
              _buildUserAvatar(msg.avatar), // This will now use profile image
            ],
          ],
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMessageStatus(String? status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'sending':
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case 'sent':
        icon = Icons.check;
        color = Colors.green;
        break;
      case 'failed':
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      default:
        icon = Icons.check;
        color = Colors.grey;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
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
                      enabled: controller.canSendMessage,
                      decoration: const InputDecoration(
                        hintText: "Write Message",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.black87),
                      onSubmitted: (text) => _sendMessage(),
                    ),
                  ),
                  Obx(() {
                    if (controller.isSending.value) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: _sendMessage,
                      child: Icon(
                        Icons.send,
                        color: controller.canSendMessage
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (textController.text.trim().isNotEmpty && controller.canSendMessage) {
      controller.sendMessage(textController.text);
      textController.clear();
    }
  }
}