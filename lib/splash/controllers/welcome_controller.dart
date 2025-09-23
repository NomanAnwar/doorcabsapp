import 'package:doorcab/feautures/start/views/getting_started_screen.dart';
import 'package:get/get.dart';
import '../../utils/http/http_client.dart';
import '../../feautures/shared/services/storage_service.dart';
import '../models/languagemodel.dart';
import '../views/home_screen.dart';

class WelcomeController extends GetxController {
  var languages = <LanguageModel>[].obs;
  var selectedLanguage = Rxn<LanguageModel>();
  var selectedRole = ''.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLanguages();
  }

  /// Fetch languages from API
  Future<void> fetchLanguages() async {
    try {
      isLoading.value = true;
      final response = await FHttpHelper.get("site/get-languages");

      print("Lang API Response : "+response.toString());

      if (response["success"] == true &&
          response["supported_languages"] != null) {
        languages.value = (response["supported_languages"] as List)
            .map((e) => LanguageModel.fromJson(e))
            .toList();

        if (languages.isNotEmpty) {
          selectedLanguage.value = languages.first; // default
        }
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void selectLanguage(LanguageModel lang) {
    selectedLanguage.value = lang;
  }

  void selectRole(String role) {
    selectedRole.value = role;
  }

  void saveAndContinue() {
    if (selectedLanguage.value != null && selectedRole.isNotEmpty) {
      StorageService.saveLanguage(selectedLanguage.value!.language);
      StorageService.saveRole(selectedRole.value);
      Get.to(() =>  GettingStartedScreen());
    } else {
      Get.snackbar('Error', 'Please select both language and role');
    }
  }
}
