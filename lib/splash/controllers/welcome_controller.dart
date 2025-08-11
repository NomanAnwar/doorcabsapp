import 'package:get/get.dart';
import '../models/storage_service.dart';
import '../views/home_screen.dart';

class WelcomeController extends GetxController {
  var selectedLanguage = ''.obs;
  var selectedRole = ''.obs;

  void selectLanguage(String lang) {
    selectedLanguage.value = lang;
  }

  void selectRole(String role) {
    selectedRole.value = role;
  }

  void saveAndContinue() {
    if (selectedLanguage.isNotEmpty && selectedRole.isNotEmpty) {
      StorageService.saveLanguage(selectedLanguage.value);
      StorageService.saveRole(selectedRole.value);
      Get.off(() => const HomeScreen());
    } else {
      Get.snackbar('Error', 'Please select both language and role');
    }
  }
}
