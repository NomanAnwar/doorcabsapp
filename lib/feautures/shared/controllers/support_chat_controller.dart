import 'package:get/get.dart';
import '../models/support_chat_model.dart';

class SupportChatController extends GetxController {
  var messages = <Message>[].obs;

  @override
  void onInit() {
    super.onInit();

    // First agent message
    messages.add(
      Message(
        text: "Hi there! how can i help you today?",
        isUser: false,
        avatar: "assets/images/profile_chat.png", // Sophia’s profile picture
        name: "Sophia",
      ),
    );

    // Example: Pre-load user’s first message (optional)
    messages.add(
      Message(
        text: "I have a question about my recent ride.",
        isUser: true,
        avatar: "assets/images/you.png", // User’s profile picture
        name: "You",
      ),
    );
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    messages.add(
      Message(
        text: text,
        isUser: true,
        avatar: "assets/images/you.png", // User profile pic
        name: "You",
      ),
    );
  }

  void receiveMessage(String text) {
    messages.add(
      Message(
        text: text,
        isUser: false,
        avatar: "assets/images/profile_chat.png", // Agent profile pic
        name: "Sophia",
      ),
    );
  }
}
