import 'package:get/get.dart';
import '../../feautures/shared/services/storage_service.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(seconds: 2)); // splash delay

    final lang = StorageService.getLanguage();
    final roleRaw = StorageService.getRole();
    final role = roleRaw?.toLowerCase(); // 🔥 normalize role
    final loggedIn = StorageService.getLoginStatus();
    final profileData = StorageService.getProfile();
    final driverSteps = StorageService.getDriverSteps();

    print("====== SPLASH DEBUG START ======");
    print("Language: $lang");
    print("Role: $roleRaw → normalized: $role");
    print("Is Logged In: $loggedIn");
    print("Profile Data: $profileData");
    print("Driver Steps: $driverSteps");
    print("================================");

    final hasLanguage = lang != null;
    final hasRole = role != null;

    if (!hasLanguage || !hasRole) {
      print("❌ Missing language or role → Navigating to /welcome");
      Get.offAllNamed('/welcome');
      return;
    }

    if (!loggedIn) {
      print("❌ Not logged in → Navigating to /getting-started");
      Get.offAllNamed('/getting-started');
      return;
    }


    /// 🚖 Passenger Flow
    if (role == "passenger") {
      bool isPassengerProfileCompleted = false;
      if (profileData != null) {
        isPassengerProfileCompleted = _validateProfile(profileData);
      }

      if (!isPassengerProfileCompleted) {
        print("❌ Passenger profile incomplete → Navigating to /profile");
        Get.offAllNamed('/profile');
      } else {
        print("✅ Passenger profile complete → Navigating to /ride-home");
        Get.offAllNamed('/ride-home');
      }
      return;
    }

    /// 🚕 Driver Flow
    if (role == "driver") {
      // final hasStartedSteps = driverSteps != null && driverSteps.isNotEmpty;
      final hasStartedSteps = driverSteps.values.any((v) => v == true); // ✅ FIX
      final isDriverStepsCompleted =
      hasStartedSteps ? _validateDriverSteps(driverSteps) : false;

      print(hasStartedSteps.toString());

      if (!hasStartedSteps) {
        print("❌ Driver has not started profile steps → Navigating to /select_driver_type");
        Get.offAllNamed('/select_driver_type');
      } else if (!isDriverStepsCompleted) {
        print("⚠️ Driver started but not finished → Navigating to /profile-completion");
        print(driverSteps.toString());
        Get.offAllNamed('/profile-completion');
      } else {
        print("✅ Driver profile completed → Navigating to /ride-home");
        Get.offAllNamed('/ride-home');
      }
      return;
    }

    /// Unknown role
    print("⚠️ Unknown role [$roleRaw] → Navigating to /welcome");
    Get.offAllNamed('/welcome');
  }

  bool _validateProfile(Map<String, dynamic> data) {
    final result = data['firstName']?.toString().isNotEmpty == true &&
        data['lastName']?.toString().isNotEmpty == true &&
        data['email']?.toString().isNotEmpty == true &&
        // data['contact']?.toString().isNotEmpty == true &&
        data['emergency_no']?.toString().isNotEmpty == true &&
        data['country']?.toString().isNotEmpty == true &&
        data['city']?.toString().isNotEmpty == true;

    print("Passenger Profile Validation Result: $result");
    return result;
  }

  bool _validateDriverSteps(Map<String, dynamic> steps) {
    final result = steps['basic'] == true &&
        steps['cnic'] == true &&
        steps['selfie'] == true &&
        steps['licence'] == true &&
        steps['vehicle'] == true &&
        steps['referral'] == true &&
        steps['policy'] == true; // 🔥 fixed key from policyAccepted → policy

    print("Driver Steps Validation Result: $result");
    return result;
  }
}
