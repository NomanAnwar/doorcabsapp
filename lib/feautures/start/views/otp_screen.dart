import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/local_storage/storage_utility.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = Get.arguments ?? '';

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            FLocalStorage.writeData('isLoggedIn', true);
            Get.offAllNamed('/home');
          },
          child: Text('Verify OTP for $phone'),
        ),
      ),
    );
  }
}
