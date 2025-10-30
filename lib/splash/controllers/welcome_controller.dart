import 'package:doorcab/feautures/start/views/getting_started_screen.dart';
import 'package:get/get.dart';
import '../../feautures/shared/controllers/base_controller.dart';
import '../../utils/http/http_client.dart';
import '../../feautures/shared/services/storage_service.dart';
import '../models/languagemodel.dart';

class WelcomeController extends BaseController {
  final languages = <LanguageModel>[].obs;
  final selectedLanguage = Rxn<LanguageModel>();
  final selectedRole = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    await executeWithRetry(() async {
      final response = await FHttpHelper.get("site/get-languages");
      print("Languages API Response : "+ response.toString());

      if (response["success"] == true && response["supported_languages"] != null) {
        languages.value = (response["supported_languages"] as List)
            .map((e) => LanguageModel.fromJson(e))
            .toList();

        if (languages.isNotEmpty) {
          selectedLanguage.value = languages.first;
        }
      }
    });
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
      Get.to(() => const GettingStartedScreen());
    } else {
      showError('Please select both language and role');
    }
  }
}
