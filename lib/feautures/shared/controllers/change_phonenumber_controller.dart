import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/http/http_client.dart';
import '../services/storage_service.dart';

class ChangePhoneNumberController extends GetxController {
  final currentPhoneController = TextEditingController();
  final newPhoneController = TextEditingController();

  var isLoading = false.obs;
  var maxPhoneLength = 14.obs; // dynamic

  @override
  void onInit() {
    super.onInit();
    final data = StorageService.getProfile();

    if (data != null && data.isNotEmpty && data['phone_no'] != null && data['phone_no'].toString().isNotEmpty) {
      currentPhoneController.text = data['phone_no'];
    } else {
      currentPhoneController.text = "xxxxxxxxxxxx";
    }
  }

  /// Dynamically control phone format
  void handlePhoneInput(String value) {
    if (!value.startsWith('+')) return;

    if (value.startsWith('+1')) {
      maxPhoneLength.value = 12; // +1 + 10 digits
    } else if (value.startsWith('+92')) {
      maxPhoneLength.value = 13; // +92 + 10 digits
    } else {
      maxPhoneLength.value = 15; // standard international limit
    }

    if (value.length > maxPhoneLength.value) {
      newPhoneController.text = value.substring(0, maxPhoneLength.value);
      newPhoneController.selection = TextSelection.fromPosition(
        TextPosition(offset: newPhoneController.text.length),
      );
    }
  }

  Future<void> savePhoneNumber() async {
    final newPhone = newPhoneController.text.trim();

    if (newPhone.isEmpty) {
      _showSnackbar("Error", "Please enter phone number with country code.", Colors.redAccent);
      return;
    }

    if (!RegExp(r'^\+[0-9]{7,14}$').hasMatch(newPhone)) {
      _showSnackbar("Invalid Number", "Enter valid international format e.g +923001234567", Colors.redAccent);
      return;
    }

    try {
      isLoading.value = true;

      final response = await FHttpHelper.post(
        'service/update-phone',
        {"phone_no": newPhone},
      );

      if (response['message'] == "OTP sent. Please verify your phone number.") {
        currentPhoneController.text = newPhone;
        newPhoneController.clear();

        Get.off('/otp', arguments: {
          "phone": newPhone,
          "userId": response["userId"],
          "method": 'sms',
          "fornumberupdate": true,
        });
      } else {
        _showSnackbar("Error", "Failed to update phone number", Colors.redAccent);
      }
    } catch (e) {
      _showSnackbar("Error", e.toString(), Colors.redAccent);
    } finally {
      isLoading.value = false;
    }
  }

  void _showSnackbar(String title, String message, Color color) {
    Get.snackbar(
      title,
      message,
      backgroundColor: color,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    currentPhoneController.dispose();
    newPhoneController.dispose();
    super.onClose();
  }
}
