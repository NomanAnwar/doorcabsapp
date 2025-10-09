// api_retry_helper.dart
class ApiRetryHelper {
  static Future<T> executeWithRetry<T>(
      Future<T> Function() apiCall, {
        int maxRetries = 3,
        Duration initialDelay = const Duration(seconds: 1),
        bool throwLastError = true,
      }) async {
    Exception? lastError;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await apiCall();
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        print('🔄 API call attempt ${attempt + 1}/$maxRetries failed: $e');

        if (attempt == maxRetries - 1) {
          if (throwLastError) throw lastError;
          break;
        }

        // Exponential backoff
        final delay = Duration(
            milliseconds: initialDelay.inMilliseconds * (attempt + 1)
        );
        print('⏳ Retrying in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
      }
    }

    throw lastError ?? Exception('All retry attempts failed');
  }

  static Future<T> executeWithRetryAndFallback<T>(
      Future<T> Function() apiCall,
      T fallbackValue, {
        int maxRetries = 2,
      }) async {
    try {
      return await executeWithRetry(
        apiCall,
        maxRetries: maxRetries,
        throwLastError: false,
      );
    } catch (e) {
      print('⚠️ Using fallback value after all retries failed');
      return fallbackValue;
    }
  }
}