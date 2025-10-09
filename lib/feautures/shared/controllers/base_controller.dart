// lib/utils/controllers/base_controller.dart
import 'package:get/get.dart';
import '../../../utils/http/api_retry_helper.dart';

abstract class BaseController extends GetxController {
  final isLoading = false.obs;
  final error = ''.obs;

  Future<void> executeWithRetry(
      Future<void> Function() apiCall, {
        String? loadingMessage,
        int maxRetries = 2,
      }) async {
    try {
      isLoading.value = true;
      error.value = '';

      await ApiRetryHelper.executeWithRetry(
        apiCall,
        maxRetries: maxRetries,
      );
    } catch (e) {
      error.value = e.toString();
      print('❌ Controller error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ NEW: For methods that return values
  Future<T> executeWithRetryAndReturn<T>(
      Future<T> Function() apiCall, {
        String? loadingMessage,
        int maxRetries = 2,
      }) async {
    try {
      isLoading.value = true;
      error.value = '';

      return await ApiRetryHelper.executeWithRetry(
        apiCall,
        maxRetries: maxRetries,
      );
    } catch (e) {
      error.value = e.toString();
      print('❌ Controller error: $e');
      rethrow; // Re-throw so calling code can handle it
    } finally {
      isLoading.value = false;
    }
  }

  void showError(String message) {
    Get.snackbar('Error', message);
  }

  void showSuccess(String message) {
    Get.snackbar('Success', message);
  }
}