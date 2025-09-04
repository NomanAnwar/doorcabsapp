import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'dart:async';

class RateDriverController extends GetxController {
  final rating = 4.0.obs;
  final selectedTags = <String>[].obs;
  final messageController = TextEditingController();

  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
  }

  void submitRating() {
    // TODO: call API
    // move to ride history
    Get.offNamed('/ride-history');
    Get.snackbar("Thanks", "Your rating has been submitted");
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
