// lib/feautures/rides/controllers/chat_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ChatController extends GetxController {
  final messages = <Map<String, dynamic>>[].obs; // {from: 'driver'|'user', text, ts}
  final inputCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Seed a few messages if desired
    messages.addAll([
      {'from': 'driver', 'text': 'I am near Zainab Tower', 'ts': DateTime.now().subtract(const Duration(minutes: 3))},
      {'from': 'user', 'text': 'Okay, come ahead', 'ts': DateTime.now().subtract(const Duration(minutes: 2))},
    ]);
  }

  void sendMessage() {
    final t = inputCtrl.text.trim();
    if (t.isEmpty) return;
    messages.add({'from': 'user', 'text': t, 'ts': DateTime.now()});
    inputCtrl.clear();

    // Optionally simulate driver reply
    Future.delayed(const Duration(seconds: 2), () {
      messages.add({'from': 'driver', 'text': 'On my way', 'ts': DateTime.now()});
    });
  }

  @override
  void onClose() {
    inputCtrl.dispose();
    super.onClose();
  }
}
