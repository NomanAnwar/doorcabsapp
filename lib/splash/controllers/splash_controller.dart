import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import '../../feautures/shared/controllers/base_controller.dart';
import '../../feautures/shared/services/driver_location_service.dart';
import '../../feautures/shared/services/enhanced_pusher_manager.dart';
import '../../feautures/shared/services/pusher_beams.dart';
import '../../feautures/shared/services/storage_service.dart';
import '../../feautures/start/models/driver_verification_helper.dart';
import '../../utils/http/http_client.dart';

final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
final PusherBeamsService _pusherBeams = PusherBeamsService();
final DriverLocationService _driverLocationService = DriverLocationService();


class SplashController extends BaseController {
  @override
  void onReady() {
    super.onReady();
    _initializeCoreServices();
    _checkNavigation();
  }



  Future<void> _initializeCoreServices() async {
    try {
      await Firebase.initializeApp();
      FHttpHelper.setBaseUrl("https://dc.tricasol.pk");
      await _pusherManager.initializeOnce();
      await _pusherBeams.initialize();
      await _pusherBeams.registerDevice();

      // Configure location service if driver
      if (StorageService.getRole() == "Driver" || StorageService.getRole() == "driver") {
        await _driverLocationService.configure();
        await _driverLocationService.start();
      }
    } catch (e) {
      print('⚠️ Service initialization error: $e');
    }
  }

  void initializeObservableProfile() {
    StorageService.getProfile(); // This will update the observable profile
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(seconds: 1));

    initializeObservableProfile();

    await executeWithRetry(() async {
      final lang = StorageService.getLanguage();
      final role = StorageService.getRole()?.toLowerCase();
      final loggedIn = StorageService.getLoginStatus();
      final profileData = StorageService.getProfile();
      final driverSteps = StorageService.getDriverSteps();

      // Your existing navigation logic
      if (lang == null || role == null) {
        Get.offAllNamed('/welcome');
      } else if (!loggedIn) {
        Get.offAllNamed('/getting-started');
      } else if (role == "passenger") {
        _handlePassengerFlow(profileData);
      } else if (role == "driver") {
        _handleDriverFlow(driverSteps);
      } else {
        Get.offAllNamed('/welcome');
      }
    });
  }

  void _handlePassengerFlow(Map<String, dynamic>? profileData) {
    final isProfileCompleted = profileData != null && _validateProfile(profileData);
    if (!isProfileCompleted && StorageService.getProfile() == null) {
      Get.offAllNamed('/profile');
    } else {
      Get.offAllNamed('/ride-type');
    }
  }

  // void _handleDriverFlow(Map<String, dynamic> driverSteps) {
  //   final hasStartedSteps = driverSteps.values.any((v) => v == true);
  //   final isCompleted = hasStartedSteps ? _validateDriverSteps(driverSteps) : false;
  //
  //   if (!hasStartedSteps) {
  //     print("Driver 1");
  //     Get.offAllNamed('/select_driver_type');
  //   } else if (!isCompleted) {
  //     print("Driver 11: $isCompleted");
  //     Get.offAllNamed('/profile-completion');
  //   } else if(isCompleted) {
  //     print("Driver 12: $isCompleted");
  //     Get.offAllNamed('/go-online');
  //   }else {
  //     Get.offAllNamed('/ride-type');
  //   }
  // }

  // Update the _handleDriverFlow method in SplashController

  void _handleDriverFlow(Map<String, dynamic> driverSteps) async {
    try {
      // Get fresh profile data for accurate verification status
      final profileResponse = await FHttpHelper.get(
        "driver/${StorageService.getSignUpResponse()?.userId.toString()}",
      );

      final driverProfile = profileResponse["driver"];
      StorageService.saveProfile(driverProfile);

      // ✅ ADDED: Check if this is a first-time user
      final isProfileUpdated = driverProfile['isProfileUpdated'] ?? false;

      if (!isProfileUpdated) {
        print("➡️ Splash → First time driver → Select Driver Type");
        Get.offAllNamed('/select_driver_type');
        return;
      }

      final hasUploadedAll = DriverVerificationHelper.hasUploadedAllDocuments(driverProfile);
      final isFullyVerified = DriverVerificationHelper.isFullyVerified(driverProfile);
      final blockingReason = DriverVerificationHelper.getBlockingReason(driverProfile);

      print("🚗 Splash - Driver Verification Status:");
      print("📁 All Documents Uploaded: $hasUploadedAll");
      print("✅ Fully Verified: $isFullyVerified");
      print("🚫 Blocking Reason: $blockingReason");

      if (!hasUploadedAll) {
        // User hasn't uploaded all documents yet
        final hasStartedSteps = driverSteps.values.any((v) => v == true);

        if (!hasStartedSteps) {
          print("➡️ Splash → Select Driver Type");
          Get.offAllNamed('/select_driver_type');
        } else {
          print("➡️ Splash → Profile Completion (documents incomplete)");
          Get.offAllNamed('/profile-completion');
        }
      } else if (!isFullyVerified) {
        // Documents uploaded but pending approval
        print("➡️ Splash → Profile Completion (pending approval)");
        Get.offAllNamed('/profile-completion');
      } else {
        // Fully verified and approved
        print("➡️ Splash → Go Online");
        Get.offAllNamed('/go-online');
      }
    } catch (e) {
      print('❌ Error fetching driver profile in splash: $e');
      // Fallback to basic step checking
      final hasStartedSteps = driverSteps.values.any((v) => v == true);
      final isCompleted = hasStartedSteps ? _validateDriverSteps(driverSteps) : false;

      if (!hasStartedSteps) {
        Get.offAllNamed('/select_driver_type');
      } else if (!isCompleted) {
        Get.offAllNamed('/profile-completion');
      } else {
        Get.offAllNamed('/go-online');
      }
    }
  }

  bool _validateProfile(Map<String, dynamic> data) {
    return data['firstName']?.toString().isNotEmpty == true &&
        data['lastName']?.toString().isNotEmpty == true &&
        data['email']?.toString().isNotEmpty == true &&
        data['emergency_no']?.toString().isNotEmpty == true &&
        data['country']?.toString().isNotEmpty == true &&
        data['city']?.toString().isNotEmpty == true;
  }

  bool _validateDriverSteps(Map<String, dynamic> steps) {
    return steps['basic'] == true &&
        steps['cnic'] == true &&
        steps['selfie'] == true &&
        steps['licence'] == true &&
        steps['vehicle'] == true
    // && steps['referral'] == true
    //     && steps['policy'] == true
    ;
  }
}



// import 'package:get/get.dart';
// import '../../feautures/shared/services/storage_service.dart';
// import '../../../utils/http/api_retry_helper.dart'; // ✅ ADDED
//
// class SplashController extends GetxController {
//   @override
//   void onReady() {
//     super.onReady();
//     _checkNavigationWithRetry(); // ✅ UPDATED
//   }
//
//   // ✅ UPDATED: Added retry mechanism
//   Future<void> _checkNavigationWithRetry() async {
//     await Future.delayed(const Duration(seconds: 2)); // splash delay
//
//     final maxRetries = 3;
//     for (int attempt = 1; attempt <= maxRetries; attempt++) {
//       try {
//         await _performNavigationCheck();
//         return; // Success, exit retry loop
//       } catch (e) {
//         print('❌ Navigation check attempt $attempt failed: $e');
//
//         if (attempt == maxRetries) {
//           // Final fallback after all retries
//           print('⚠️ All navigation check attempts failed, going to welcome screen');
//           Get.offAllNamed('/welcome');
//           return;
//         }
//
//         await Future.delayed(Duration(seconds: attempt * 1)); // Exponential backoff
//       }
//     }
//   }
//
//   // ✅ EXISTING: Your original navigation logic (unchanged)
//   Future<void> _performNavigationCheck() async {
//     final lang = StorageService.getLanguage();
//     final roleRaw = StorageService.getRole();
//     final role = roleRaw?.toLowerCase(); // 🔥 normalize role
//     final loggedIn = StorageService.getLoginStatus();
//     final profileData = StorageService.getProfile();
//     final driverSteps = StorageService.getDriverSteps();
//
//     print("====== SPLASH DEBUG START ======");
//     print("Language: $lang");
//     print("Role: $roleRaw → normalized: $role");
//     print("Is Logged In: $loggedIn");
//     print("Profile Data: $profileData");
//     print("Driver Steps: $driverSteps");
//     print("User Token: "+StorageService.getAuthToken().toString());
//     print("================================");
//
//     final hasLanguage = lang != null;
//     final hasRole = role != null;
//
//     if (!hasLanguage || !hasRole) {
//       print(" Missing language or role → Navigating to /welcome");
//       Get.offAllNamed('/welcome');
//       return;
//     }
//
//     if (!loggedIn) {
//       print(" Not logged in → Navigating to /getting-started");
//       Get.offAllNamed('/getting-started');
//       return;
//     }
//
//
//     /// 🚖 Passenger Flow
//     if (role == "passenger") {
//       bool isPassengerProfileCompleted = false;
//       if (profileData != null) {
//         isPassengerProfileCompleted = _validateProfile(profileData);
//       }
//
//       if (!isPassengerProfileCompleted && StorageService.getProfile() == null) {
//         print(" Passenger profile incomplete → Navigating to /profile");
//         Get.offAllNamed('/profile');
//       } else {
//         print(" Passenger profile complete → Navigating to /ride-home or type");
//         Get.offAllNamed('/ride-type');
//         // Get.offAllNamed('/ride-home');
//       }
//       return;
//     }
//
//     /// 🚕 Driver Flow
//     if (role == "driver") {
//       // final hasStartedSteps = driverSteps != null && driverSteps.isNotEmpty;
//       final hasStartedSteps = driverSteps.values.any((v) => v == true);
//       final isDriverStepsCompleted =
//       hasStartedSteps ? _validateDriverSteps(driverSteps) : false;
//
//       print(hasStartedSteps.toString());
//
//       if (!hasStartedSteps) {
//         print(" Driver has not started profile steps → Navigating to /select_driver_type");
//         Get.offAllNamed('/select_driver_type');
//       } else if (!isDriverStepsCompleted) {
//         print("⚠️ Driver started but not finished → Navigating to /profile-completion");
//         print(driverSteps.toString());
//         Get.offAllNamed('/profile-completion');
//       } else {
//         print(" Driver profile completed → Navigating to /ride-home");
//         Get.offAllNamed('/ride-type');
//         // Get.offAllNamed('/ride-home');
//       }
//       return;
//     }
//
//     /// Unknown role
//     print("⚠️ Unknown role [$roleRaw] → Navigating to /welcome");
//     Get.offAllNamed('/welcome');
//   }
//
//   // ✅ EXISTING: Your original validation methods (unchanged)
//   bool _validateProfile(Map<String, dynamic> data) {
//     final result = data['firstName']?.toString().isNotEmpty == true &&
//         data['lastName']?.toString().isNotEmpty == true &&
//         data['email']?.toString().isNotEmpty == true &&
//         // data['contact']?.toString().isNotEmpty == true &&
//         data['emergency_no']?.toString().isNotEmpty == true &&
//         data['country']?.toString().isNotEmpty == true &&
//         data['city']?.toString().isNotEmpty == true;
//
//     print("Passenger Profile Validation Result: $result");
//     return result;
//   }
//
//   bool _validateDriverSteps(Map<String, dynamic> steps) {
//     final result = steps['basic'] == true &&
//         steps['cnic'] == true &&
//         steps['selfie'] == true &&
//         steps['licence'] == true &&
//         steps['vehicle'] == true &&
//         steps['referral'] == true &&
//         steps['policy'] == true; // 🔥 fixed key from policyAccepted → policy
//
//     print("Driver Steps Validation Result: $result");
//     return result;
//   }
// }


// import 'package:get/get.dart';
// import '../../feautures/shared/services/storage_service.dart';
//
// class SplashController extends GetxController {
//   @override
//   void onReady() {
//     super.onReady();
//     _checkNavigation();
//   }
//
//   Future<void> _checkNavigation() async {
//     await Future.delayed(const Duration(seconds: 2)); // splash delay
//
//     final lang = StorageService.getLanguage();
//     final roleRaw = StorageService.getRole();
//     final role = roleRaw?.toLowerCase(); // 🔥 normalize role
//     final loggedIn = StorageService.getLoginStatus();
//     final profileData = StorageService.getProfile();
//     final driverSteps = StorageService.getDriverSteps();
//
//     print("====== SPLASH DEBUG START ======");
//     print("Language: $lang");
//     print("Role: $roleRaw → normalized: $role");
//     print("Is Logged In: $loggedIn");
//     print("Profile Data: $profileData");
//     print("Driver Steps: $driverSteps");
//     print("User Token: "+StorageService.getAuthToken().toString());
//     print("================================");
//
//     final hasLanguage = lang != null;
//     final hasRole = role != null;
//
//     if (!hasLanguage || !hasRole) {
//       print(" Missing language or role → Navigating to /welcome");
//       Get.offAllNamed('/welcome');
//       return;
//     }
//
//     if (!loggedIn) {
//       print(" Not logged in → Navigating to /getting-started");
//       Get.offAllNamed('/getting-started');
//       return;
//     }
//
//
//     /// 🚖 Passenger Flow
//     if (role == "passenger") {
//       bool isPassengerProfileCompleted = false;
//       if (profileData != null) {
//         isPassengerProfileCompleted = _validateProfile(profileData);
//       }
//
//       if (!isPassengerProfileCompleted && StorageService.getProfile() == null) {
//         print(" Passenger profile incomplete → Navigating to /profile");
//         Get.offAllNamed('/profile');
//       } else {
//         print(" Passenger profile complete → Navigating to /ride-home or type");
//         Get.offAllNamed('/ride-type');
//         // Get.offAllNamed('/ride-home');
//       }
//       return;
//     }
//
//     /// 🚕 Driver Flow
//     if (role == "driver") {
//       // final hasStartedSteps = driverSteps != null && driverSteps.isNotEmpty;
//       final hasStartedSteps = driverSteps.values.any((v) => v == true);
//       final isDriverStepsCompleted =
//       hasStartedSteps ? _validateDriverSteps(driverSteps) : false;
//
//       print(hasStartedSteps.toString());
//
//       if (!hasStartedSteps) {
//         print(" Driver has not started profile steps → Navigating to /select_driver_type");
//         Get.offAllNamed('/select_driver_type');
//       } else if (!isDriverStepsCompleted) {
//         print("⚠️ Driver started but not finished → Navigating to /profile-completion");
//         print(driverSteps.toString());
//         Get.offAllNamed('/profile-completion');
//       } else {
//         print(" Driver profile completed → Navigating to /ride-home");
//         Get.offAllNamed('/ride-type');
//         // Get.offAllNamed('/ride-home');
//       }
//       return;
//     }
//
//     /// Unknown role
//     print("⚠️ Unknown role [$roleRaw] → Navigating to /welcome");
//     Get.offAllNamed('/welcome');
//   }
//
//   bool _validateProfile(Map<String, dynamic> data) {
//     final result = data['firstName']?.toString().isNotEmpty == true &&
//         data['lastName']?.toString().isNotEmpty == true &&
//         data['email']?.toString().isNotEmpty == true &&
//         // data['contact']?.toString().isNotEmpty == true &&
//         data['emergency_no']?.toString().isNotEmpty == true &&
//         data['country']?.toString().isNotEmpty == true &&
//         data['city']?.toString().isNotEmpty == true;
//
//     print("Passenger Profile Validation Result: $result");
//     return result;
//   }
//
//   bool _validateDriverSteps(Map<String, dynamic> steps) {
//     final result = steps['basic'] == true &&
//         steps['cnic'] == true &&
//         steps['selfie'] == true &&
//         steps['licence'] == true &&
//         steps['vehicle'] == true &&
//         steps['referral'] == true &&
//         steps['policy'] == true; // 🔥 fixed key from policyAccepted → policy
//
//     print("Driver Steps Validation Result: $result");
//     return result;
//   }
// }
