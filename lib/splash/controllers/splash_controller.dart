import 'package:get/get.dart';

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

    if (!hasLanguage || !hasRole) {
      Get.offAllNamed('/welcome');
    } else if (!isLoggedIn) {
      Get.offAllNamed('/getting-started');
    } else {
      Get.offAllNamed('/home');
    }
  }
}
