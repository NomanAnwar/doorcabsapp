// lib/feautures/rides/controllers/chat_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/pusher_channels.dart';
import '../../../shared/services/storage_service.dart';

class ChatController extends GetxController {
  final messages = <Map<String, dynamic>>[].obs;
  final inputCtrl = TextEditingController();
  final scrollController = ScrollController();

  String? _rideId;
  String? _receiverId;
  String? _driverId;
  String? _passengerId;

  // --- GETTERS
  String? get rideId => _rideId;
  String? get receiverId => _receiverId;

  // Current logged-in user info
  late final String _myUserId;
  late final String _myRole; // 'Driver' or 'Passenger'

  @override
  void onInit() {
    super.onInit();

    final signUpResponse = StorageService.getSignUpResponse()!;
    _myUserId = signUpResponse.userId;
    _myRole = StorageService.getRole() ?? 'Passenger';

    final args = Get.arguments as Map<String, dynamic>? ?? {};

    // Extract data based on user role and argument structure
    _extractArguments(args);

    print("📨 ChatController init - Role: $_myRole, RideId: $_rideId, ReceiverId: $_receiverId, MyId: $_myUserId");

    if (rideId != null) {
      _loadChatHistory();
      _subscribeToChatChannel(rideId!);
    }
  }

  /// Load chat history using hybrid approach
  Future<void> _loadChatHistory() async {
    try {
      print("📖 Loading chat history for ride: $_rideId");

      // 1. First load from local storage for instant UI
      _loadLocalMessages();

      // 2. Then call API to sync and verify completeness
      await _syncWithServer();

      // Auto-scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

    } catch (e) {
      print("❌ Failed to load chat history: $e");
    }
  }

  /// Load messages from local storage
  void _loadLocalMessages() {
    if (_rideId == null) return;

    final localMessages = StorageService.getChatMessages(_rideId!);
    print("💾 Loaded ${localMessages.length} messages from local storage");

    // Convert local messages to UI format
    messages.clear();
    for (var message in localMessages) {
      final senderId = message['senderId']?.toString();
      final isMe = senderId == _myUserId;

      messages.add({
        'from': isMe ? 'me' : 'other',
        'text': message['text']?.toString() ?? '',
        'ts': DateTime.tryParse(message['sent_at']?.toString() ?? '') ?? DateTime.now(),
        '_id': message['_id']?.toString(), // Store _id for deduplication
      });
    }
  }

  /// Sync local messages with server API
  Future<void> _syncWithServer() async {
    try {
      final response = await FHttpHelper.get("chat/get-messages/$_rideId");
      final List<dynamic> serverMessages = response['messages'] ?? [];

      print("🔄 Syncing with server. Server messages: ${serverMessages.length}, Local messages: ${messages.length}");

      // Check if we need to update (server has more messages or different content)
      bool needsUpdate = serverMessages.length != messages.length;

      if (!needsUpdate) {
        // Check if any messages are different (compare by _id and content)
        final serverIds = serverMessages.map((m) => m['_id'].toString()).toSet();
        final localIds = messages.where((m) => m['_id'] != null && !m['_id'].toString().startsWith('temp_')).map((m) => m['_id'].toString()).toSet();
        needsUpdate = serverIds != localIds;
      }

      if (needsUpdate) {
        print("📡 Server has different messages, updating local storage...");

        // Convert server messages to storage format
        final messagesToStore = serverMessages.map((msg) {
          return Map<String, dynamic>.from(msg);
        }).toList();

        // Update local storage
        await StorageService.saveChatMessages(_rideId!, messagesToStore);

        // Update UI
        messages.clear();
        for (var message in serverMessages) {
          final senderId = message['senderId']?.toString();
          final isMe = senderId == _myUserId;

          messages.add({
            'from': isMe ? 'me' : 'other',
            'text': message['text']?.toString() ?? '',
            'ts': DateTime.tryParse(message['sent_at']?.toString() ?? '') ?? DateTime.now(),
            '_id': message['_id']?.toString(),
          });
        }

        print("✅ Sync completed. Now showing ${messages.length} messages");
      } else {
        print("✅ Local messages are up to date");
      }

    } catch (e) {
      print("❌ Failed to sync with server: $e");
      // Don't show error to user, continue with local messages
    }
  }

  /// Extract arguments based on user role and argument structure
  void _extractArguments(Map<String, dynamic> args) {
    if (_myRole == 'Driver') {
      // Driver side - args come from passenger's rideData
      _rideId = args['rideData']?['rideId']?.toString();
      _passengerId = args['rideData']?['passenger']?['id']?.toString();
      _receiverId = _passengerId;

      print("🚗 Driver context - PassengerId: $_passengerId");

    } else {
      // Passenger side - args come from bid data
      _rideId = args['rideId']?.toString();
      _driverId = args['bid']?['driver']?['id']?.toString();
      _receiverId = _driverId;

      print("👤 Passenger context - DriverId: $_driverId");
    }

    // Fallback: if rideId not found in nested structure, check root level
    _rideId ??= args['rideId']?.toString();

    if (_receiverId == null) {
      print("⚠️ No receiverId found in arguments: $args");
    }
  }

  /// Send message API call with local storage
  Future<void> sendMessage() async {
    final text = inputCtrl.text.trim();
    if (text.isEmpty) return;

    if (_receiverId == null) {
      Get.snackbar("Error", "Cannot send message - receiver information missing");
      return;
    }

    if (_rideId == null) {
      Get.snackbar("Error", "Cannot send message - ride information missing");
      return;
    }

    // Create temporary message with proper structure
    final now = DateTime.now();
    final tempId = 'temp_${now.millisecondsSinceEpoch}';
    final tempMessage = {
      'from': 'me',
      'text': text,
      'ts': now,
      '_id': tempId,
    };

    // Add message to local list immediately
    messages.add(tempMessage);
    inputCtrl.clear();

    // Auto-scroll to bottom after sending
    _scrollToBottom();

    try {
      final body = {
        "receiverId": _receiverId,
        "rideId": _rideId,
        "text": text,
      };

      print("📤 Sending message to API: $body");
      final res = await FHttpHelper.post("chat/send", body);
      print("✅ Message sent successfully: $res");

      // Create a temporary local storage entry for the sent message
      // This will be replaced by the real message when Pusher event arrives
      final tempStorageMessage = {
        '_id': tempId,
        'senderId': _myUserId,
        'senderRole': _myRole,
        'receiverId': _receiverId,
        'receiverRole': _myRole == 'Driver' ? 'Passenger' : 'Driver',
        'rideId': _rideId,
        'text': text,
        'attachment_url': '',
        'message_status': 'sent',
        'sent_at': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
      };

      // Store temporarily until real message arrives
      StorageService.addChatMessage(_rideId!, tempStorageMessage);

    } catch (e) {
      print("❌ Failed to send message: $e");
      Get.snackbar("Error", "Failed to send message");

      // Remove temporary message if send failed
      messages.removeWhere((msg) => msg['_id'] == tempId);

      // Also remove from local storage if it was stored
      if (_rideId != null) {
        final localMessages = StorageService.getChatMessages(_rideId!);
        localMessages.removeWhere((msg) => msg['_id'] == tempId);
        StorageService.saveChatMessages(_rideId!, localMessages);
      }
    }
  }

  /// Subscribe to pusher ride channel with local storage
  void _subscribeToChatChannel(String rideId) {
    final channelName = "ride-$rideId";

    print("🔔 Subscribing to Pusher channel: $channelName");

    PusherChannelsService().subscribe(channelName, events: {
      "new-message": (data) {
        print("💬 Incoming Pusher message: $data");
        // FSnackbar.show(title: "New Message", message: data['text'].toString());

        final senderId = data['senderId']?.toString();
        final text = data['text']?.toString();
        final messageId = data['_id']?.toString();
        final createdAt = data['createdAt']?.toString();
        final sentAt = data['sent_at']?.toString();

        if (text == null || senderId == null || messageId == null) {
          print("⚠️ Invalid message data received");
          return;
        }

        // Check if this message is from me (sent by current user)
        final isMine = senderId == _myUserId;

        // Always save the message to local storage, regardless of sender
        if (_rideId != null) {
          // Convert to proper storage format
          final messageToStore = Map<String, dynamic>.from(data);
          StorageService.addChatMessage(_rideId!, messageToStore);
          print("💾 Saved message to local storage: $messageId");
        }

        if (isMine) {
          print("🔄 This is my own message, replacing temporary message if exists");

          // Find and remove any temporary message with same content
          messages.removeWhere((msg) =>
          msg['_id']?.toString().startsWith('temp_') == true &&
              msg['text'] == text
          );

          // Add the real message with proper ID
          messages.add({
            'from': 'me',
            'text': text,
            'ts': DateTime.tryParse(sentAt ?? createdAt!) ?? DateTime.now(),
            '_id': messageId,
          });
        } else {
          print("👥 Adding message from other user to chat");
          messages.add({
            'from': 'other',
            'text': text,
            'ts': DateTime.tryParse(sentAt ?? createdAt!) ?? DateTime.now(),
            '_id': messageId,
          });
        }

        // Auto-scroll when new message arrives
        _scrollToBottom();
      },
    });
  }

  /// Auto-scroll to bottom of chat
  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Get display data for UI
  Map<String, String?> getDisplayData() {
    final args = Get.arguments as Map<String, dynamic>? ?? {};

    if (_myRole == 'Driver') {
      final passenger = args['rideData']?['passenger'] ?? {};
      return {
        'name': passenger['name']?.toString() ?? 'Passenger',
        'phone': passenger['phone_no']?.toString() ?? '',
        'avatar': passenger['profileImage']?.toString() ?? 'assets/images/profile_img_sample.png',
        'car': 'Your Vehicle',
        'etaText': args['rideData']?['estimated_arrival_time']?.toString() ?? 'Calculating...',
        'avgRating': passenger['avgRating']?.toString(),
        'totalRatings': passenger['total_ratings']?.toString(),
        'category': null,
        'badge': null,
      };
    } else {
      final driver = args['bid']?['driver'] ?? {};
      final driverName = driver['name'] is Map
          ? '${driver['name']?['firstName'] ?? ''} ${driver['name']?['lastName'] ?? ''}'.trim()
          : driver['name']?.toString() ?? 'Driver';

      return {
        'name': driverName,
        'phone': driver['phone_no']?.toString() ?? '',
        'avatar': driver['profileImage']?.toString() ?? 'assets/images/profile_img_sample.png',
        'car': driver['vehicle']?.toString() ?? 'Vehicle',
        'etaText': args['estimated_arrival_time']?.toString() ?? 'Calculating...',
        'avgRating': driver['avgRating']?.toString(),
        'totalRatings': driver['total_ratings']?.toString(),
        'category': driver['category']?.toString(),
        'badge': driver['badge']?.toString(),
      };
    }
  }

  @override
  void onClose() {
    inputCtrl.dispose();
    scrollController.dispose();
    super.onClose();
  }
}