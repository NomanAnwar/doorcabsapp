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




// import 'package:doorcab/feautures/start/views/getting_started_screen.dart';
// import 'package:get/get.dart';
// import '../../utils/http/http_client.dart';
// import '../../feautures/shared/services/storage_service.dart';
// import '../models/languagemodel.dart';
// import '../../../utils/http/api_retry_helper.dart'; // ✅ ADDED
//
// class WelcomeController extends GetxController {
//   var languages = <LanguageModel>[].obs;
//   var selectedLanguage = Rxn<LanguageModel>();
//   var selectedRole = ''.obs;
//   var isLoading = false.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     fetchLanguagesWithRetry(); // ✅ UPDATED
//   }
//
//   /// ✅ UPDATED: Fetch languages from API with retry
//   Future<void> fetchLanguagesWithRetry() async {
//     try {
//       isLoading.value = true;
//
//       await ApiRetryHelper.executeWithRetry(
//             () async {
//           final response = await FHttpHelper.get("site/get-languages");
//           print("Lang API Response : "+response.toString());
//
//           if (response["success"] == true &&
//               response["supported_languages"] != null) {
//             languages.value = (response["supported_languages"] as List)
//                 .map((e) => LanguageModel.fromJson(e))
//                 .toList();
//
//             if (languages.isNotEmpty) {
//               selectedLanguage.value = languages.first; // default
//               // Cache the languages for future use
//               _cacheLanguages(languages);
//             }
//           }
//           return response;
//         },
//         maxRetries: 2,
//       );
//     } catch (e) {
//       Get.snackbar("Error", "Failed to load languages: ${e.toString()}");
//       // Load cached languages as fallback
//       _loadCachedLanguages();
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   // ✅ NEW: Cache languages to local storage
//   void _cacheLanguages(List<LanguageModel> languages) {
//     try {
//       final cachedData = languages.map((lang) => lang.toJson()).toList();
//       // You can use StorageService or GetStorage directly
//       // For now, we'll just print since we don't have the cache method in StorageService
//       print('✅ Languages cached: ${cachedData.length} items');
//       // StorageService.saveCachedLanguages(cachedData); // Uncomment when you add this method
//     } catch (e) {
//       print('Error caching languages: $e');
//     }
//   }
//
//   // ✅ NEW: Load cached languages
//   void _loadCachedLanguages() {
//     try {
//       // Load from cache if API fails
//       // Uncomment when you add this method to StorageService
//       // final cached = StorageService.getCachedLanguages();
//       // if (cached.isNotEmpty) {
//       //   languages.value = cached.map((e) => LanguageModel.fromJson(e)).toList();
//       //   if (languages.isNotEmpty) {
//       //     selectedLanguage.value = languages.first;
//       //   }
//       //   print('✅ Loaded ${languages.length} languages from cache');
//       // }
//
//       // For now, use a simple fallback
//       if (languages.isEmpty) {
//         languages.value = [
//           LanguageModel(language: 'English', flag: 'assets/images/english_flag.png'),
//           LanguageModel(language: 'Urdu', flag: 'assets/images/urdu_flag.png'),
//         ];
//         if (languages.isNotEmpty) {
//           selectedLanguage.value = languages.first;
//         }
//         print('✅ Loaded fallback languages');
//       }
//     } catch (e) {
//       print('Error loading cached languages: $e');
//     }
//   }
//
//   // ✅ EXISTING: Your original methods (unchanged)
//   void selectLanguage(LanguageModel lang) {
//     selectedLanguage.value = lang;
//   }
//
//   void selectRole(String role) {
//     selectedRole.value = role;
//   }
//
//   void saveAndContinue() {
//     if (selectedLanguage.value != null && selectedRole.isNotEmpty) {
//       StorageService.saveLanguage(selectedLanguage.value!.language);
//       StorageService.saveRole(selectedRole.value);
//       Get.to(() =>  GettingStartedScreen());
//     } else {
//       Get.snackbar('Error', 'Please select both language and role');
//     }
//   }
// }


// import 'package:doorcab/feautures/start/views/getting_started_screen.dart';
// import 'package:get/get.dart';
// import '../../utils/http/http_client.dart';
// import '../../feautures/shared/services/storage_service.dart';
// import '../models/languagemodel.dart';
// import '../views/home_screen.dart';
//
// class WelcomeController extends GetxController {
//   var languages = <LanguageModel>[].obs;
//   var selectedLanguage = Rxn<LanguageModel>();
//   var selectedRole = ''.obs;
//   var isLoading = false.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     fetchLanguages();
//   }
//
//   /// Fetch languages from API
//   Future<void> fetchLanguages() async {
//     try {
//       isLoading.value = true;
//       final response = await FHttpHelper.get("site/get-languages");
//
//       print("Lang API Response : "+response.toString());
//
//       if (response["success"] == true &&
//           response["supported_languages"] != null) {
//         languages.value = (response["supported_languages"] as List)
//             .map((e) => LanguageModel.fromJson(e))
//             .toList();
//
//         if (languages.isNotEmpty) {
//           selectedLanguage.value = languages.first; // default
//         }
//       }
//     } catch (e) {
//       Get.snackbar("Error", e.toString());
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   void selectLanguage(LanguageModel lang) {
//     selectedLanguage.value = lang;
//   }
//
//   void selectRole(String role) {
//     selectedRole.value = role;
//   }
//
//   void saveAndContinue() {
//     if (selectedLanguage.value != null && selectedRole.isNotEmpty) {
//       StorageService.saveLanguage(selectedLanguage.value!.language);
//       StorageService.saveRole(selectedRole.value);
//       Get.to(() =>  GettingStartedScreen());
//     } else {
//       Get.snackbar('Error', 'Please select both language and role');
//     }
//   }
// }
