import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/services/storage_service.dart';

class ProfileController extends GetxController {
  final formKey = GlobalKey<FormState>();

  /// Text Controllers
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final emergencyCtrl = TextEditingController();
  final countryCtrl = TextEditingController(text: "Pakistan"); // Default
  final cityCtrl = TextEditingController();

  /// Save
  void saveAndContinue() {
    if (!formKey.currentState!.validate()) return;

    final profileData = {
      "firstName": firstNameCtrl.text.trim(),
      "lastName": lastNameCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "contact": contactCtrl.text.trim(),
      "emergency": emergencyCtrl.text.trim(),
      "country": countryCtrl.text.trim(),
      "city": cityCtrl.text.trim(),
    };

    StorageService.saveProfile(profileData);
    Get.offAllNamed('/ride-home');
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    contactCtrl.dispose();
    emergencyCtrl.dispose();
    countryCtrl.dispose();
    cityCtrl.dispose();
    super.onClose();
  }
}
