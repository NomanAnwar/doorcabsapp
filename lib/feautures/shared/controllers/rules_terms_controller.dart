import 'package:get/get.dart';

import '../../../utils/http/http_client.dart';
import '../services/storage_service.dart';

class RulesTermsController extends GetxController {
  var isLoading = true.obs;
  var rulesTerms = <Map<String, String>>[].obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRulesTerms();
  }

  Future<void> fetchRulesTerms() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      final response = await FHttpHelper.get('rules/all');

      if (response['message'] == "Rules fetched successfully") {
        // Assuming the API response structure has a list of rules/terms
        final List<dynamic> rulesData = response['rules'] ?? response['data'] ?? [];

        rulesTerms.value = rulesData.map((item) {
          return {
            'title': item['title']?.toString() ?? 'Untitled',
            'content': item['description']?.toString() ?? 'No content available',
          };
        }).toList();

        // If no data from API, use default data
        if (rulesTerms.isEmpty) {
          rulesTerms.value = _getDefaultRules();
        }
      } else {
        errorMessage.value = response['message'] ?? 'Failed to load rules & terms';
        rulesTerms.value = _getDefaultRules();
      }
    } catch (e) {
      errorMessage.value = 'Failed to load rules & terms: ${e.toString()}';
      rulesTerms.value = _getDefaultRules();
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, String>> _getDefaultRules() {
    return [
      {
        'title': "Service Agreement",
        'content': "This section outlines the terms of service agreement between the app and the user.",
      },
      {
        'title': "Privacy Policy",
        'content': "This section describes how your data is collected, stored, and used.",
      },
      {
        'title': "Community Guidelines",
        'content': "This section provides behavioral rules and expectations for all users.",
      },
    ];
  }
}