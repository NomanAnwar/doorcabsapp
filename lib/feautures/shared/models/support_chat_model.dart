// models/support_chat_model.dart
import 'package:doorcab/feautures/shared/services/storage_service.dart';

class Message {
  final String text;
  final bool isUser;
  final String avatar;
  final String? name;
  final String? messageId;
  final DateTime? timestamp;
  final String? status;
  final String? sender;

  Message({
    required this.text,
    required this.isUser,
    required this.avatar,
    this.name,
    this.messageId,
    this.timestamp,
    this.status = 'sent',
    this.sender,
  });

  // Factory constructor from API data
  factory Message.fromApiData(Map<String, dynamic> messageData) {
    final sender = messageData['sender']?.toString() ?? 'user';
    final isUser = sender == 'user';

    // Parse timestamp
    DateTime? timestamp;
    try {
      if (messageData['timestamp'] != null) {
        timestamp = DateTime.parse(messageData['timestamp'].toString());
      }
    } catch (e) {
      timestamp = DateTime.now();
    }

    // Get user profile image from storage
    String userAvatar = _getUserProfileImage();

    return Message(
      text: messageData['text']?.toString() ?? '',
      isUser: isUser,
      avatar: isUser
          ? userAvatar // Use profile image for user
          : "assets/images/profile_chat.png", // Default for agent
      name: isUser ? "You" : "Support Agent",
      messageId: messageData['_id']?.toString(),
      timestamp: timestamp ?? DateTime.now(),
      status: messageData['message_status']?.toString() ?? 'sent',
      sender: sender,
    );
  }

  // Helper method to get user profile image
  static String _getUserProfileImage() {
    try {
      final profileData = StorageService.getProfile();
      if (profileData != null) {
        final profileImage = profileData['Profile_Image']?.toString() ?? '';
        if (profileImage.isNotEmpty && profileImage.startsWith('http')) {
          return profileImage; // Return network image URL
        }
      }
    } catch (e) {
      print('❌ Error getting profile image: $e');
    }

    // Fallback to default image
    return "assets/images/you.png";
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'avatar': avatar,
      'name': name,
      'messageId': messageId,
      'timestamp': timestamp?.toIso8601String(),
      'status': status,
      'sender': sender,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    DateTime? timestamp;
    try {
      if (json['timestamp'] != null) {
        timestamp = DateTime.parse(json['timestamp']);
      }
    } catch (e) {
      timestamp = DateTime.now();
    }

    return Message(
      text: json['text']?.toString() ?? '',
      isUser: json['isUser'] ?? false,
      avatar: json['avatar']?.toString() ?? '',
      name: json['name']?.toString(),
      messageId: json['messageId']?.toString(),
      timestamp: timestamp,
      status: json['status']?.toString() ?? 'sent',
      sender: json['sender']?.toString(),
    );
  }
}