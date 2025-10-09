// lib/feautures/rides/controllers/chat_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/pusher_channels.dart';
import '../../../shared/services/storage_service.dart';

class ChatController extends GetxController {
  final messages = <Map<String, dynamic>>[].obs; // {from: 'me'|'other', text, ts}
  final inputCtrl = TextEditingController();

  String? _rideId;
  String? _receiverId; // driverId

  // --- GETTERS
  String? get rideId => _rideId;
  String? get receiverId => _receiverId;

  // --- SETTERS
  set rideId(String? id) => _rideId = id;
  set receiverId(String? id) => _receiverId = id;

  // Current logged-in user id
  late final String _myUserId;

  @override
  void onInit() {
    super.onInit();

    _myUserId = StorageService.getSignUpResponse()!.userId;

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    rideId = args['rideId']?.toString();
    receiverId = args['driverId']?.toString();

    print("📨 ChatController init rideId=$rideId receiverId=$receiverId myId=$_myUserId");

    if (rideId != null) {
      _subscribeToChatChannel(rideId!);
    }
  }

  /// Send message API call
  Future<void> sendMessage() async {
    final text = inputCtrl.text.trim();
    if (text.isEmpty) return;

    final msg = {
      'from': 'me',
      'text': text,
      'ts': DateTime.now(),
    };
    messages.add(msg);
    inputCtrl.clear();

    try {
      final body = {
        "receiverId": receiverId,
        "rideId": rideId,
        "text": text,
      };
      final res = await FHttpHelper.post("chat/send", body);
      print("✅ Message sent: $res");
    } catch (e) {
      print("❌ Failed to send message: $e");
      Get.snackbar("Error", "Failed to send message");
    }
  }

  /// Subscribe to pusher ride channel
  void _subscribeToChatChannel(String rideId) {
    PusherChannelsService().subscribe("ride-$rideId", events: {
      "new-message": (data) {
        print("💬 Incoming message: $data");

        final senderId = data['senderId']?.toString();
        final text = data['text']?.toString();
        final createdAt = data['createdAt']?.toString();

        if (text == null || senderId == null) return;

        // Check if this message is mine or from the other person
        final isMine = senderId == _myUserId;

        messages.add({
          'from': isMine ? 'me' : 'other',
          'text': text,
          'ts': DateTime.tryParse(createdAt!) ?? DateTime.now(),
        });
      },
    });
  }

  @override
  void onClose() {
    inputCtrl.dispose();
    super.onClose();
  }
}
