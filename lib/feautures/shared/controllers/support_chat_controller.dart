// support_chat_controller.dart
import 'package:get/get.dart';
import '../models/support_chat_model.dart';
import '../../../utils/http/http_client.dart';
import '../services/enhanced_pusher_manager.dart';
import '../services/storage_service.dart';

class SupportChatController extends GetxController {
  var messages = <Message>[].obs;
  var isLoading = false.obs;
  var isSending = false.obs;
  var chatId = ''.obs;
  var chatStatus = 'open'.obs;

  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
  final String _userId = StorageService.getSignUpResponse()?.userId ?? '';

  @override
  void onInit() {
    super.onInit();
    _loadExistingChat();
    _initializePusher();
  }

  @override
  void onClose() {
    _pusherManager.unsubscribeSafely('support-$_userId');
    super.onClose();
  }

  void _loadExistingChat() {
    try {
      // Load existing chat from storage
      final storedMessages = StorageService.getSupportChatMessages();
      final storedChatId = StorageService.getSupportChatId();
      final storedStatus = StorageService.getSupportChatStatus();

      if (storedMessages.isNotEmpty) {
        messages.assignAll(storedMessages);
      } else {
        // Only show initial message if no existing chat
        messages.add(
          Message(
            text: "Hi there! How can I help you today?",
            isUser: false,
            avatar: "assets/images/profile_chat.png",
            name: "Sophia",
            timestamp: DateTime.now(),
          ),
        );
      }

      if (storedChatId != null) {
        chatId.value = storedChatId;
      }

      chatStatus.value = storedStatus;

    } catch (e) {
      print('❌ Error loading support chat: $e');
      // Fallback to initial message
      _showInitialMessage();
    }
  }

  void _showInitialMessage() {
    messages.add(
      Message(
        text: "Hi there! How can I help you today?",
        isUser: false,
        avatar: "assets/images/profile_chat.png",
        name: "Sophia",
        timestamp: DateTime.now(),
      ),
    );
  }

  // Helper method to get user avatar
  String _getUserAvatar() {
    try {
      final profileData = StorageService.getProfile();
      if (profileData != null) {
        final profileImage = profileData['Profile_Image']?.toString() ?? '';
        if (profileImage.isNotEmpty && profileImage.startsWith('http')) {
          return profileImage;
        }
      }
    } catch (e) {
      print('❌ Error getting user avatar: $e');
    }
    return "assets/images/you.png";
  }

  void _initializePusher() async {
    try {
      await _pusherManager.initialize();

      // Subscribe to support channel
      await _pusherManager.subscribeOnce(
        'support-$_userId',
        events: {
          'new-support-message': _handleIncomingMessage,
          // 'support-chat-ended': _handleChatEnded,
        },
      );

      print('✅ Subscribed to support channel: support-$_userId');
    } catch (e) {
      print('❌ Error initializing Pusher for support chat: $e');
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      print('📨 Received support message event:');
      print('📦 Full data: $data');
      print('🔍 Keys: ${data.keys}');

      // Log the structure to understand what we're receiving
      if (data['latest_message'] != null) {
        print('📝 Latest message data: ${data['latest_message']}');
        print('👤 Sender in latest_message: ${data['latest_message']['sender']}');
      }
      if (data['sender'] != null) {
        print('👤 Direct sender: ${data['sender']}');
      }

      // Extract sender information
      String? sender;
      String? text;

      if (data['latest_message'] != null && data['latest_message'] is Map) {
        final latestMessage = data['latest_message'] as Map<String, dynamic>;
        sender = latestMessage['sender']?.toString();
        text = latestMessage['text']?.toString();
      } else {
        sender = data['sender']?.toString();
        text = data['text']?.toString();
      }

      print('🎯 Extracted sender: $sender, text: $text');

      // Skip if this is our own message
      if (sender == 'user') {
        print('🔄 Skipping own message from Pusher');
        return;
      }

      // Skip if no text
      if (text == null || text.isEmpty) {
        print('🚫 Skipping empty message');
        return;
      }

      // Create and add message
      final message = Message(
        text: text,
        isUser: false,
        avatar: "assets/images/profile_chat.png",
        name: data['agentName']?.toString() ?? 'Support Agent',
        messageId: data['_id']?.toString(),
        timestamp: DateTime.now(),
        status: 'delivered',
        sender: sender,
      );

      messages.add(message);
      _saveMessagesToStorage();

      // Update chat ID
      if (data['chatId'] != null) {
        chatId.value = data['chatId'].toString();
        StorageService.saveSupportChatId(chatId.value);
      }

      print('✅ Successfully added agent message');

    } catch (e) {
      print('❌ Error handling incoming message: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || isSending.value || chatStatus.value == 'ended') {
      return;
    }

    isSending.value = true;

    try {
      // Get user avatar for the message
      final userAvatar = _getUserAvatar();

      // Create temporary message (optimistic UI update)
      final tempMessage = Message(
        text: text.trim(),
        isUser: true,
        avatar: userAvatar, // Use profile image or default
        name: "You",
        timestamp: DateTime.now(),
        status: 'sending',
      );

      messages.add(tempMessage);
      _saveMessagesToStorage();

      // Send to backend
      final response = await FHttpHelper.post(
        'support/user/send',
        {
          "text": text.trim(),
          // if (chatId.value.isNotEmpty) "chatId": chatId.value,
        },
      );

      // Update message status and chat ID
      if (response['data'] != null) {
        final chatData = response['data'];

        // Update chat ID
        if (chatData['_id'] != null) {
          chatId.value = chatData['_id'].toString();
          StorageService.saveSupportChatId(chatId.value);
        }

        // Update last message status
        if (messages.isNotEmpty) {
          final lastIndex = messages.length - 1;
          messages[lastIndex] = Message(
            text: messages[lastIndex].text,
            isUser: true,
            avatar: userAvatar, // Keep the same avatar
            name: messages[lastIndex].name,
            messageId: chatData['_id']?.toString(),
            timestamp: DateTime.now(),
            status: 'sent',
          );
        }

        _saveMessagesToStorage();

        print('✅ Message sent successfully. Chat ID: ${chatId.value}');
      }

    } catch (e) {
      print('❌ Error sending message: $e');

      // Update message status to failed
      if (messages.isNotEmpty) {
        final userAvatar = _getUserAvatar();
        final lastIndex = messages.length - 1;
        messages[lastIndex] = Message(
          text: messages[lastIndex].text,
          isUser: true,
          avatar: userAvatar, // Keep the same avatar
          name: messages[lastIndex].name,
          timestamp: messages[lastIndex].timestamp,
          status: 'failed',
        );
      }

      _saveMessagesToStorage();

      Get.snackbar(
        'Error',
        'Failed to send message. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  void _saveMessagesToStorage() {
    try {
      StorageService.saveSupportChatMessages(messages);
    } catch (e) {
      print('❌ Error saving messages to storage: $e');
    }
  }

  void receiveMessage(String text, {String? agentName}) {
    final message = Message(
      text: text,
      isUser: false,
      avatar: "assets/images/profile_chat.png",
      name: agentName ?? "Sophia",
      timestamp: DateTime.now(),
      status: 'delivered',
    );

    messages.add(message);
    _saveMessagesToStorage();
  }

  // Check if user can send messages
  bool get canSendMessage => !isSending.value && chatStatus.value == 'open';

  // Clear chat history
  void clearChat() {
    messages.clear();
    StorageService.clearSupportChat();
    _showInitialMessage();
  }
}