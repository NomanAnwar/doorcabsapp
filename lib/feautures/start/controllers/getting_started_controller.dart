// lib/feautures/splash/controllers/getting_started_controller.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../utils/http/http_client.dart';
import '../../shared/services/storage_service.dart';
import '../models/sign_up_response.dart';

class GettingStartedController extends GetxController {
  var phoneNumber = ''.obs;
  var acceptedPolicy = false.obs;
  var isLoading = false.obs;

  final Rxn<SignUpResponse> signUpResponse = Rxn<SignUpResponse>();

  Future<void> signUp(String method) async {
    if (!acceptedPolicy.value || phoneNumber.value.isEmpty) {
      Get.snackbar("Error", "Please accept Privacy Policy and enter phone number");
      return;
    }

    try {
      isLoading.value = true;

      var role = StorageService.getRole();
      // if(role == "driver" || role == "Driver") {
      //   role = "Driver";
      // } else if(role == "passenger" || role == "Passenger"){
      //   role = "Passenger";
      // }


      final language = StorageService.getLanguage();

      //  prepend country code
      String formattedPhone = phoneNumber.value;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+92${formattedPhone.replaceAll(RegExp(r'^0+'), '')}';
      }

      print("Now role after change is "+ role.toString());

      final body = {
        "phone_no": formattedPhone,
        "role": role,
        "preferred_language": language,
      };

      final response = await FHttpHelper.post("service/signUp", body);

      print("Sign Up API Response : $response");
      if (response["userId"] != null) {
        ///  inject phone number
        final signUpResponse = SignUpResponse.fromJson({
          ...response,
          "phone_no": formattedPhone,
        });

        await StorageService.saveSignUpResponse(signUpResponse);
        this.signUpResponse.value = signUpResponse;

        Get.toNamed(
          '/otp',
          arguments: {
            "phone": formattedPhone,
            "userId": response["userId"],
            "method": method,
          },
        );
      } else {
        Get.snackbar("Error", response["message"] ?? "Something went wrong");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
