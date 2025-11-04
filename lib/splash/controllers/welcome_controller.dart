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
      // Get user country
      final String country = await _getUserCountry();

      // Construct URL with country parameter
      final String url = "site/get-languages/$country";
      final response = await FHttpHelper.get(url);
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

  Future<String> _getUserCountry() async {
    try {
      // Method 1: Get full country name from device locale
      final locale = Get.deviceLocale;
      if (locale != null && locale.countryCode != null) {
        return _getCountryNameFromCode(locale.countryCode!);
      }

      return 'Pakistan'; // Default fallback country name
    } catch (e) {
      print("Error getting user country: $e");
      return 'United States'; // Default fallback country name
    }
  }

  String _getCountryNameFromCode(String countryCode) {
    // Map of country codes to full country names
    final countryMap = {
      'US': 'United States',
      'PK': 'Pakistan',
      'IN': 'India',
      'GB': 'United Kingdom',
      'CA': 'Canada',
      'AU': 'Australia',
      'DE': 'Germany',
      'FR': 'France',
      'IT': 'Italy',
      'ES': 'Spain',
      'BR': 'Brazil',
      'CN': 'China',
      'JP': 'Japan',
      'KR': 'South Korea',
      'MX': 'Mexico',
      'RU': 'Russia',
      'SA': 'Saudi Arabia',
      'AE': 'United Arab Emirates',
      'ZA': 'South Africa',
      'NG': 'Nigeria',
      'EG': 'Egypt',
      'TR': 'Turkey',
      'NL': 'Netherlands',
      'SE': 'Sweden',
      'NO': 'Norway',
      'DK': 'Denmark',
      'FI': 'Finland',
      'PL': 'Poland',
      'PT': 'Portugal',
      'GR': 'Greece',
      'BE': 'Belgium',
      'CH': 'Switzerland',
      'AT': 'Austria',
      'IE': 'Ireland',
      'SG': 'Singapore',
      'MY': 'Malaysia',
      'TH': 'Thailand',
      'ID': 'Indonesia',
      'VN': 'Vietnam',
      'PH': 'Philippines',
      'BD': 'Bangladesh',
      'LK': 'Sri Lanka',
      'NP': 'Nepal',
      'MM': 'Myanmar',
      'KH': 'Cambodia',
      'LA': 'Laos',
      'BT': 'Bhutan',
      'MV': 'Maldives',
      'AF': 'Afghanistan',
      'IR': 'Iran',
      'IQ': 'Iraq',
      'SY': 'Syria',
      'LB': 'Lebanon',
      'JO': 'Jordan',
      'IL': 'Israel',
      'KW': 'Kuwait',
      'QA': 'Qatar',
      'OM': 'Oman',
      'BH': 'Bahrain',
      'YE': 'Yemen',
    };

    return countryMap[countryCode] ?? 'United States';
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