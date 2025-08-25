import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../utils/local_storage/storage_utility.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _checkNavigation();
  }

  void _checkNavigation() async {
    await Future.delayed(const Duration(seconds: 2)); // splash delay

    bool hasLanguage = FLocalStorage.hasData('language');
    bool hasRole = FLocalStorage.hasData('role');
    bool isLoggedIn = FLocalStorage.readData('isLoggedIn') ?? false;
    // bool isProfileCompleted = FLocalStorage.readData('profile_data') ?? false;

    final profileData = FLocalStorage.readData('profile_data');
    bool isProfileCompleted = false;
    if (profileData != null) {
      isProfileCompleted = _validateProfile(profileData);
    }
    await GetStorage.init();

    if (!hasLanguage || !hasRole) {
      Get.offAllNamed('/welcome');
    } else if (!isLoggedIn) {
      Get.offAllNamed('/getting-started');
    } else if (!isProfileCompleted) {
      Get.offAllNamed('/profile'); // force user to complete profile
    } else {
      Get.offAllNamed('/ride-home');
    }
  }
  bool _validateProfile(Map<String, dynamic> data) {
    return data['firstName']?.toString().isNotEmpty == true &&
        data['lastName']?.toString().isNotEmpty == true &&
        data['email']?.toString().isNotEmpty == true &&
        data['contact']?.toString().isNotEmpty == true &&
        data['emergency']?.toString().isNotEmpty == true &&
        data['country']?.toString().isNotEmpty == true &&
        data['city']?.toString().isNotEmpty == true;
  }
}
