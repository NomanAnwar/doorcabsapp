import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/local_storage/storage_utility.dart';

class OtpController extends GetxController {
  var otp = ''.obs;
  var secondsRemaining = 60.obs;
  var resendAttempts = 0.obs;
  final int maxResends = 2;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  void startTimer() {
    secondsRemaining.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value == 0) {
        timer.cancel();
      } else {
        secondsRemaining.value--;
      }
    });
  }

  void resendOtp() {
    if (resendAttempts.value >= maxResends) {
      Get.snackbar("Try Later", "Try after an hour if you did not receive the OTP",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black);
      return;
    }
    resendAttempts.value++;
    startTimer();
    // TODO: Call your resend OTP API here
  }

  void verifyOtp(String pin) {
    otp.value = pin;
    if (pin.length == 4) {
      // TODO: Call verify API here
      FLocalStorage.writeData('isLoggedIn', true);
      Get.offAllNamed('/profile');
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}