import 'dart:async';
import 'dart:convert';
import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../utils/http/http_client.dart';
import '../../shared/services/storage_service.dart';
import '../models/sign_up_response.dart';

class OtpController extends GetxController {
  var otp = ''.obs;
  var secondsRemaining = 60.obs;
  var resendAttempts = 0.obs;
  final int maxResends = 2;
  Timer? _timer;

  late final String phone;

  final Rxn<SignUpResponse> signUpResponse = Rxn<SignUpResponse>();

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
      Get.back();
      return;
    }

    getOtp();
    startTimer();
  }

  Future<void> getOtp() async {
    try {
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
        FSnackbar.show(title: "Error", message: message, isError: true);
      }
    } catch (e, st) {
      print('Exception in getOtp(): $e\n$st');
      FSnackbar.show(title: "Error", message: e.toString(), isError: true);
    }
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

  Future<void> resendOtp() async {
    if (resendAttempts.value >= maxResends) {
      Get.snackbar(
        "Try Later",
        "Try after an hour if you did not receive the OTP",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.black,
      );
      return;
    }

    try {
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
          // await StorageService.saveSignUpResponse(
          //     this.signUpResponse.value = updated;
          // );
          // Simpler: rebuild model directly
          await StorageService.saveSignUpResponse(
            SignUpResponse.fromJson(updated),
          );
        }
      }

      // Get.snackbar("Success", response["message"] ?? "OTP resent successfully");
      FSnackbar.show(
        title: "Success",
        message: response["message"] ?? "OTP resent successfully",
        isError: false,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> verifyOtp(String pin) async {
    otp.value = pin;

    if (pin.length != 4) {
      Get.snackbar("Error", "Please enter valid 4 digit OTP");
      return;
    }

    try {
      final role = StorageService.getRole(); // stored role from signup
      final body = {"phone_no": phone, "otp": pin, "role": role};

      final response = await FHttpHelper.post("service/verify-otp", body);

      print("Verify OTP API Response:" + response.toString());

      if (response["token"] != null) {
        final token = response["token"];

        // save & apply token
        await StorageService.saveAuthToken(token);
        FHttpHelper.setAuthToken(token, useBearer: true);

        //  mark as logged-in for your splash flow
        await StorageService.saveLoginStatus(true);
        if (response["isProfileUpdated"]) {
          if (role == "Driver") {
    //         Verify OTP API Response:{message: Phone number verified successfully., token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4YWRjN2ViOWNlMjJhNTNiM2YwZDMzZSIsInJvbGUiOiJEcml2ZXIiLCJpYXQiOjE3NTc5MzIyNjAsImV4cCI6MTc1ODUzNzA2MH0.fRPbSRxIF0d1EIMuDIysxPfX5Tu899xQg1txRTE_0rM,
    // role: Driver, isProfileUpdated: true, isCnicUploaded: true, isLicenseUploaded: true, isSelfieUploaded: true, isVehicleDocsUploaded: true, isRegistrationUploaded: true}

            StorageService.setDriverStep("basic", true);
            if(response["isCnicUploaded"]) {
              StorageService.setDriverStep("cnic", true);
            }
            if(response["isSelfieUploaded"]) {
              StorageService.setDriverStep("selfie", true);
            }
            if(response["isLicenseUploaded"]) {
              StorageService.setDriverStep("licence", true);
            }
            if(response["isVehicleDocsUploaded"]) {
              StorageService.setDriverStep("vehicle", true);
            }
            if(response["isRegistrationUploaded"]) {
              StorageService.setDriverStep("registration", true);
            }

            final response0 = await FHttpHelper.get(
              "driver/${StorageService.getSignUpResponse()?.userId.toString()}",
            );
            print("Get Profile Api Response : " + response0.toString());
            StorageService.saveProfile(response0["driver"]);
          } else {
            final response1 = await FHttpHelper.get(
              "passenger/get-profile-info",
            );
            print("Get Profile Api Response : " + response1.toString());
            StorageService.saveProfile(response1["passenger"]);
          }
        }

        Get.snackbar("Success", response["message"] ?? "Phone verified");

        // go to profile completion step next
        if (role == "Driver") {
          print("Navigating to Select Driver Type Screen...");
          Get.offAllNamed('/select_driver_type');
        } else {
          print("Navigating to Ride Home Screen...");
          if (response["isProfileUpdated"]) {
            Get.offAllNamed('/ride-home');
          } else {
            print("Navigating to Profile Screen...");
            Get.offAllNamed('/profile');
          }
        }
      } else {
        Get.snackbar("Error", response["message"] ?? "Invalid OTP");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
