import 'package:get/get.dart';
import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/storage_service.dart';
import '../models/referral_model.dart';

class ReferralController extends GetxController {
  var referralCode = ''.obs;
  var isLoading = false.obs;

  Future<bool> submitReferralCode() async {
    if (referralCode.value.isEmpty) {
      FSnackbar.show(title: "Error", message: "Please enter a referral code", isError: true);
      return false;
    }

    isLoading.value = true;
    try {
      final body = {"referralCode": referralCode.value};

      final token = StorageService.getAuthToken();
      if (token == null) {
        Get.snackbar("Error", "User token not found. Please login again.");
      }

      FHttpHelper.setAuthToken(token!, useBearer: true);


      final response = await FHttpHelper.post("service/referral", body);

      // print("Referral API Response : "+response.toString());

      final data = ReferralModel.fromJson(response);

      //  mark referral step complete
      StorageService.setDriverStep("referral", true);

      FSnackbar.show(
        title: "Success",
        message: data.message,
        isError: false,
      );

      return true; // return true so ProfileCompletionScreen updates
    } catch (e) {
      FSnackbar.show(title: "Error", message: e.toString(), isError: true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
