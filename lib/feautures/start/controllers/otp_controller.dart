import 'dart:async';
import 'dart:convert';
import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:doorcab/feautures/shared/services/driver_location_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../utils/http/http_client.dart';
import '../../shared/services/storage_service.dart';
import '../models/driver_verification_helper.dart';
import '../models/sign_up_response.dart';
import '../../../utils/http/api_retry_helper.dart'; // ✅ ADDED

class OtpController extends GetxController {
  var otp = ''.obs;
  var secondsRemaining = 60.obs;
  var resendAttempts = 0.obs;
  final int maxResends = 2;
  Timer? _timer;
  var isLoading = false.obs;

  late final String phone;

  final Rxn<SignUpResponse> signUpResponse = Rxn<SignUpResponse>();

  DriverLocationService _driverLocationService = DriverLocationService();

  @override
  void onInit() {
    super.onInit();

    // prefer passed arg, then stored signup response
    phone =
        Get.arguments?['phone'] ??
            StorageService.getSignUpResponse()?.phoneNo ??
            '';

    if (phone.isEmpty) {
      Get.snackbar("Error", "Phone number is missing.");
      FSnackbar.show(title: 'Error', message: 'Phone Number is missing.', isError: true);
      Get.back();
      return;
    }

    getOtp();
    startTimer();
  }

  // ✅ UPDATED: Get OTP with retry
  Future<void> getOtp() async {
    try {
      isLoading.value = true;

      await ApiRetryHelper.executeWithRetry(
            () async {
          final role = StorageService.getRole() ?? '';
          final phoneStr = phone.toString();

          final uri = Uri.parse('http://dc.tricasol.pk/service/get-otp');

          // Build low-level request so we can attach a body to GET
          final request =
          http.Request('GET', uri)
            ..headers['Content-Type'] = 'application/json'
            ..body = json.encode({'phone_no': phoneStr, 'role': role});

          print('Sending GET with body to $uri');
          print('Request body: ${request.body}');

          final streamedResp = await request.send();
          final response = await http.Response.fromStream(streamedResp);

          print('Response status: ${response.statusCode}');
          print('Response body: ${response.body}');

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            FSnackbar.show(
              title: "Success",
              message:
              responseData['message'] + "OTP IS : " + responseData['otp'] ??
                  "OTP fetched",
              isError: false,
            );
            print('OTP: ${responseData['otp']}');
          } else {
            // Try to decode body for server message, otherwise show status
            String message = 'Request failed: ${response.statusCode}';
            try {
              final data = json.decode(response.body);
              message = data['message'] ?? message;
            } catch (_) {}
            throw Exception(message);
          }
          return response;
        },
        maxRetries: 2,
      );
    } catch (e, st) {
      print('Exception in getOtp(): $e\n$st');
      FSnackbar.show(title: "Error", message: e.toString(), isError: true);
    } finally {
      isLoading.value = false;  // ✅ Hide loader
    }
  }

  // ✅ EXISTING: Your original timer method (unchanged)
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

  // ✅ UPDATED: Resend OTP with retry
  Future<void> resendOtp() async {
    if (resendAttempts.value >= maxResends) {

      FSnackbar.show(title: 'Try Later', message: 'Try after an hour if you did not receive the OTP', isError: true);
      return;
    }

    try {
      isLoading.value = true;

      await ApiRetryHelper.executeWithRetry(
            () async {
          final role = StorageService.getRole();

          final body = {
            "phone_no": phone,
            "role": role, // API expects 'Passenger'
          };

          final response = await FHttpHelper.post("service/resend-otp", body);

          // success → restart timer and (optionally) refresh stored signup response id
          resendAttempts.value++;
          startTimer();

          // If API returns userId instead of passengerId, keep storage in sync
          print("Resend OTP API Response:" + response.toString());
          if (response["userId"] != null) {
            final existing = StorageService.getSignUpResponse();
            if (existing != null) {
              final updated = {
                "message": response["message"] ?? existing.message,
                "passengerId": response["userId"], // normalize to our model
                "phone_no": existing.phoneNo,
              };
              await StorageService.saveSignUpResponse(
                SignUpResponse.fromJson(updated),
              );
            }
          }

          FSnackbar.show(
            title: "Success",
            message: response["message"] ?? "OTP resent successfully",
            isError: false,
          );
          return response;
        },
        maxRetries: 3,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;  // ✅ Hide loader
    }
  }

  // In your OTP Controller, update the verifyOtp method for driver case
  Future<void> verifyOtp(String pin) async {
    otp.value = pin;

    if (pin.length != 4) {
      FSnackbar.show(
        title: "Error",
        message: "Please Enter Valid 4 digit OTP",
        isError: true,
      );
      return;
    }

    try {
      isLoading.value = true;

      await ApiRetryHelper.executeWithRetry(
            () async {
          final role = StorageService.getRole();
          final body = {"phone_no": phone, "otp": pin, "role": role};

          final response = await FHttpHelper.post("service/verify-otp", body);

          print("Verify OTP API Response:" + response.toString());

          if (response["token"] != null) {
            final token = response["token"];

            // save & apply token
            await StorageService.saveAuthToken(token);
            FHttpHelper.setAuthToken(token, useBearer: true);

            // mark as logged-in for your splash flow
            await StorageService.saveLoginStatus(true);

            if (response["isProfileUpdated"]) {
              if (role == "Driver") {
                // Set basic driver steps
                StorageService.setDriverStep("basic", true);
                if(response["isCnicUploaded"]) StorageService.setDriverStep("cnic", true);
                if(response["isSelfieUploaded"]) StorageService.setDriverStep("selfie", true);
                if(response["isLicenseUploaded"]) StorageService.setDriverStep("licence", true);
                if(response["isVehicleDocsUploaded"]) StorageService.setDriverStep("vehicle", true);
                if(response["isRegistrationUploaded"]) StorageService.setDriverStep("registration", true);

                // Get detailed profile for comprehensive checks
                final profileResponse = await FHttpHelper.get(
                  "driver/${StorageService.getSignUpResponse()?.userId.toString()}",
                );
                print("Get Profile Api Response : " + profileResponse.toString());

                final driverProfile = profileResponse["driver"];
                StorageService.saveProfile(driverProfile);

                // Configure location service
                await _driverLocationService.configure();
                await _driverLocationService.start();

                // Navigate based on comprehensive verification status
                await _handleDriverNavigation(driverProfile);

              } else {
                // Passenger flow remains same
                final response1 = await FHttpHelper.get("passenger/get-profile-info");
                StorageService.saveProfile(response1["passenger"]);
                _handlePassengerNavigation(response1["passenger"]);
              }
            } else {
              // FIRST TIME USER - Profile not updated yet
              if (role == "Driver") {
                print("➡️ First time driver → Navigating to Select Driver Type");

                // Configure location service for driver
                await _driverLocationService.configure();
                await _driverLocationService.start();

                Get.offAllNamed('/select_driver_type');
              } else {
                print("➡️ First time passenger → Navigating to Profile Setup");
                Get.offAllNamed('/profile');
              }
            }

            FSnackbar.show(title: "Success", message: response["message"] ?? "Phone verified");
          } else {
            throw Exception(response["message"] ?? "Invalid OTP");
          }
          return response;
        },
        maxRetries: 2,
      );
    } catch (e) {
      FSnackbar.show(title: "Error", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

// New method for driver navigation
  Future<void> _handleDriverNavigation(Map<String, dynamic> driverProfile) async {
    final verificationStatus = DriverVerificationHelper.getVerificationStatus(driverProfile);
    final hasUploadedAll = DriverVerificationHelper.hasUploadedAllDocuments(driverProfile);
    final isFullyVerified = DriverVerificationHelper.isFullyVerified(driverProfile);
    final hasRejectedDocs = DriverVerificationHelper.hasRejectedDocuments(driverProfile); // ✅ NEW
    final blockingReason = DriverVerificationHelper.getBlockingReason(driverProfile);

    print("🚗 Driver Verification Status: $verificationStatus");
    print("📁 All Documents Uploaded: $hasUploadedAll");
    print("✅ Fully Verified: $isFullyVerified");
    print("❌ Has Rejected Documents: $hasRejectedDocs"); // ✅ NEW
    print("🚫 Blocking Reason: $blockingReason");

    if (hasRejectedDocs) {
      // ✅ NEW: Handle rejected documents - go to profile completion with clear message
      print("➡️ Navigating to: Profile Completion (documents rejected)");
      Get.offAllNamed('/profile-completion');

      // Show specific rejection message
      final rejectedReasons = DriverVerificationHelper.getRejectedReasons(driverProfile);
      FSnackbar.show(
        title: "Documents Rejected",
        message: "${rejectedReasons.join(', ')}. Please re-upload clear documents.",
        isError: true,
      );
    } else if (!hasUploadedAll) {
      // User hasn't uploaded all documents yet
      final driverSteps = StorageService.getDriverSteps();
      final hasStartedSteps = driverSteps.values.any((v) => v == true);

      if (!hasStartedSteps) {
        print("➡️ Navigating to: Select Driver Type (first time)");
        Get.offAllNamed('/select_driver_type');
      } else {
        print("➡️ Navigating to: Profile Completion (documents incomplete)");
        Get.offAllNamed('/profile-completion');
      }
    } else if (!isFullyVerified) {
      // Documents uploaded but pending approval
      print("➡️ Navigating to: Profile Completion (pending approval)");
      Get.offAllNamed('/profile-completion');

      // Show notification about pending verification
      FSnackbar.show(
        title: "Verification Pending",
        message: "Your documents are under review. $blockingReason",
        isError: false,
      );
    } else {
      // Fully verified and approved - go online!
      print("➡️ Navigating to: Go Online (fully verified)");
      Get.offAllNamed('/go-online');

      FSnackbar.show(
        title: "Welcome!",
        message: "You're all set to start driving!",
        isError: false,
      );
    }
  }

// Update passenger navigation
  void _handlePassengerNavigation(Map<String, dynamic>? profileData) {
    final isProfileCompleted = profileData != null && _validateProfile(profileData);
    if (!isProfileCompleted && StorageService.getProfile() == null) {
      Get.offAllNamed('/profile');
    } else {
      Get.offAllNamed('/ride-type');
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _handleDriverFlow(Map<String, dynamic> driverSteps) {

    final hasStartedSteps = driverSteps.values.any((v) => v == true);
    final isCompleted = hasStartedSteps ? _validateDriverSteps(driverSteps) : false;

    if (!hasStartedSteps) {
      print("Driver 1");
      Get.offAllNamed('/select_driver_type');
    } else if (!isCompleted) {
      print("Driver 11: $isCompleted");
      Get.offAllNamed('/profile-completion');
    } else if(isCompleted) {
      print("Driver 12: $isCompleted");
      Get.offAllNamed('/go-online');
    }else {
      Get.offAllNamed('/ride-type');
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
        && steps['policy'] == true
    ;
  }


}



// import 'dart:async';
// import 'dart:convert';
// import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import '../../../utils/http/http_client.dart';
// import '../../shared/services/storage_service.dart';
// import '../models/sign_up_response.dart';
//
// class OtpController extends GetxController {
//   var otp = ''.obs;
//   var secondsRemaining = 60.obs;
//   var resendAttempts = 0.obs;
//   final int maxResends = 2;
//   Timer? _timer;
//   var isLoading = false.obs;
//
//   late final String phone;
//
//   final Rxn<SignUpResponse> signUpResponse = Rxn<SignUpResponse>();
//
//   @override
//   void onInit() {
//     super.onInit();
//
//     // prefer passed arg, then stored signup response
//     phone =
//         Get.arguments?['phone'] ??
//         StorageService.getSignUpResponse()?.phoneNo ??
//         '';
//
//     if (phone.isEmpty) {
//       Get.snackbar("Error", "Phone number is missing.");
//       Get.back();
//       return;
//     }
//
//     getOtp();
//     startTimer();
//   }
//
//   Future<void> getOtp() async {
//     try {
//       isLoading.value = true;
//       final role = StorageService.getRole() ?? '';
//       final phoneStr = phone.toString();
//
//       final uri = Uri.parse('http://dc.tricasol.pk/service/get-otp');
//
//       // Build low-level request so we can attach a body to GET
//       final request =
//           http.Request('GET', uri)
//             ..headers['Content-Type'] = 'application/json'
//             ..body = json.encode({'phone_no': phoneStr, 'role': role});
//
//       print('Sending GET with body to $uri');
//       print('Request body: ${request.body}');
//
//       final streamedResp = await request.send();
//       final response = await http.Response.fromStream(streamedResp);
//
//       print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         FSnackbar.show(
//           title: "Success",
//           message:
//               responseData['message'] + "OTP IS : " + responseData['otp'] ??
//               "OTP fetched",
//           isError: false,
//         );
//         print('OTP: ${responseData['otp']}');
//       } else {
//         // Try to decode body for server message, otherwise show status
//         String message = 'Request failed: ${response.statusCode}';
//         try {
//           final data = json.decode(response.body);
//           message = data['message'] ?? message;
//         } catch (_) {}
//         FSnackbar.show(title: "Error", message: message, isError: true);
//       }
//     } catch (e, st) {
//       print('Exception in getOtp(): $e\n$st');
//       FSnackbar.show(title: "Error", message: e.toString(), isError: true);
//     } finally {
//       isLoading.value = false;  // ✅ Hide loader
//     }
//   }
//
//   void startTimer() {
//     secondsRemaining.value = 60;
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (secondsRemaining.value == 0) {
//         timer.cancel();
//       } else {
//         secondsRemaining.value--;
//       }
//     });
//   }
//
//   Future<void> resendOtp() async {
//     if (resendAttempts.value >= maxResends) {
//       Get.snackbar(
//         "Try Later",
//         "Try after an hour if you did not receive the OTP",
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red.shade100,
//         colorText: Colors.black,
//       );
//       return;
//     }
//
//     try {
//       isLoading.value = true;
//       final role = StorageService.getRole();
//
//       final body = {
//         "phone_no": phone,
//         "role": role, // API expects 'Passenger'
//       };
//
//       final response = await FHttpHelper.post("service/resend-otp", body);
//
//       // success → restart timer and (optionally) refresh stored signup response id
//       resendAttempts.value++;
//       startTimer();
//
//       // If API returns userId instead of passengerId, keep storage in sync
//       print("Resend OTP API Response:" + response.toString());
//       if (response["userId"] != null) {
//         final existing = StorageService.getSignUpResponse();
//         if (existing != null) {
//           final updated = {
//             "message": response["message"] ?? existing.message,
//             "passengerId": response["userId"], // normalize to our model
//             "phone_no": existing.phoneNo,
//           };
//           // await StorageService.saveSignUpResponse(
//           //     this.signUpResponse.value = updated;
//           // );
//           // Simpler: rebuild model directly
//           await StorageService.saveSignUpResponse(
//             SignUpResponse.fromJson(updated),
//           );
//         }
//       }
//
//       // Get.snackbar("Success", response["message"] ?? "OTP resent successfully");
//       FSnackbar.show(
//         title: "Success",
//         message: response["message"] ?? "OTP resent successfully",
//         isError: false,
//       );
//     } catch (e) {
//       Get.snackbar("Error", e.toString());
//     } finally {
//       isLoading.value = false;  // ✅ Hide loader
//     }
//   }
//
//   Future<void> verifyOtp(String pin) async {
//     otp.value = pin;
//
//     if (pin.length != 4) {
//       Get.snackbar("Error", "Please enter valid 4 digit OTP");
//       return;
//     }
//
//     try {
//       isLoading.value = true;
//       final role = StorageService.getRole(); // stored role from signup
//       final body = {"phone_no": phone, "otp": pin, "role": role};
//
//       final response = await FHttpHelper.post("service/verify-otp", body);
//
//       print("Verify OTP API Response:" + response.toString());
//
//       if (response["token"] != null) {
//         final token = response["token"];
//
//         // save & apply token
//         await StorageService.saveAuthToken(token);
//         FHttpHelper.setAuthToken(token, useBearer: true);
//
//         //  mark as logged-in for your splash flow
//         await StorageService.saveLoginStatus(true);
//         if (response["isProfileUpdated"]) {
//           if (role == "Driver") {
//     //         Verify OTP API Response:{message: Phone number verified successfully., token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4YWRjN2ViOWNlMjJhNTNiM2YwZDMzZSIsInJvbGUiOiJEcml2ZXIiLCJpYXQiOjE3NTc5MzIyNjAsImV4cCI6MTc1ODUzNzA2MH0.fRPbSRxIF0d1EIMuDIysxPfX5Tu899xQg1txRTE_0rM,
//     // role: Driver, isProfileUpdated: true, isCnicUploaded: true, isLicenseUploaded: true, isSelfieUploaded: true, isVehicleDocsUploaded: true, isRegistrationUploaded: true}
//
//             StorageService.setDriverStep("basic", true);
//             if(response["isCnicUploaded"]) {
//               StorageService.setDriverStep("cnic", true);
//             }
//             if(response["isSelfieUploaded"]) {
//               StorageService.setDriverStep("selfie", true);
//             }
//             if(response["isLicenseUploaded"]) {
//               StorageService.setDriverStep("licence", true);
//             }
//             if(response["isVehicleDocsUploaded"]) {
//               StorageService.setDriverStep("vehicle", true);
//             }
//             if(response["isRegistrationUploaded"]) {
//               StorageService.setDriverStep("registration", true);
//             }
//
//             final response0 = await FHttpHelper.get(
//               "driver/${StorageService.getSignUpResponse()?.userId.toString()}",
//             );
//             print("Get Profile Api Response : " + response0.toString());
//             StorageService.saveProfile(response0["driver"]);
//           } else {
//             final response1 = await FHttpHelper.get(
//               "passenger/get-profile-info",
//             );
//             print("Get Profile Api Response : " + response1.toString());
//             StorageService.saveProfile(response1["passenger"]);
//           }
//         }
//
//         Get.snackbar("Success", response["message"] ?? "Phone verified");
//
//         // go to profile completion step next
//         if (role == "Driver") {
//           print("Navigating to Select Driver Type Screen...");
//           Get.offAllNamed('/select_driver_type');
//         } else {
//           print("Navigating to Ride Home Screen...");
//           if (response["isProfileUpdated"]) {
//             Get.offAllNamed('/ride-type');
//             // Get.offAllNamed('/ride-home');
//           } else {
//             print("Navigating to Profile Screen...");
//             Get.offAllNamed('/profile');
//           }
//         }
//       } else {
//         Get.snackbar("Error", response["message"] ?? "Invalid OTP");
//       }
//     } catch (e) {
//       Get.snackbar("Error", e.toString());
//     } finally {
//       isLoading.value = false;  // ✅ Hide loader
//     }
//   }
//
//   @override
//   void onClose() {
//     _timer?.cancel();
//     super.onClose();
//   }
// }
