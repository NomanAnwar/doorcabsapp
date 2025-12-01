import 'package:doorcab/feautures/shared/controllers/base_controller.dart';
import 'package:get/get.dart';
import 'package:doorcab/utils/http/http_client.dart';

import '../models/privacy_policy_model.dart';
import '../services/storage_service.dart';


class PrivacyPolicyController extends BaseController {
  final Rx<PrivacyPolicy?> privacyPolicy = Rx<PrivacyPolicy?>(null);
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPrivacyPolicy();
  }

  Future<void> fetchPrivacyPolicy() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      final response = await FHttpHelper.get('rules/all');

      if (response['message'] == "Rules fetched successfully" && response['data'] is List) {
        final rulesData = response['data'] as List;

        // Find the Privacy Policy from the response
        PrivacyPolicy? foundPolicy;
        for (var rule in rulesData) {
          if (rule is Map<String, dynamic> &&
              rule['title']?.toString().toLowerCase().contains('privacy') == true) {
            foundPolicy = PrivacyPolicy(
              id: rule['_id']?.toString() ?? '',
              title: rule['title']?.toString() ?? 'Privacy Policy',
              description: rule['description']?.toString() ?? '',
            );
            break;
          }
        }

        if (foundPolicy != null) {
          privacyPolicy.value = foundPolicy;
        } else {
          // Fallback if Privacy Policy not found in API
          _loadFallbackPrivacyPolicy();
        }
      } else {
        hasError.value = true;
        _loadFallbackPrivacyPolicy();
      }

    } catch (e) {
      print('Error fetching privacy policy: $e');
      hasError.value = true;
      _loadFallbackPrivacyPolicy();
    } finally {
      isLoading.value = false;
    }
  }

  void _loadFallbackPrivacyPolicy() {
    privacyPolicy.value = PrivacyPolicy(
      id: 'fallback',
      title: 'Privacy Policy',
      description: 'We collect and process user data solely to improve platform functionality, ensure safety, and deliver a better experience. Personal information is never shared with unauthorized third parties, and users can request the removal or correction of their data at any time.',
    );
  }
}