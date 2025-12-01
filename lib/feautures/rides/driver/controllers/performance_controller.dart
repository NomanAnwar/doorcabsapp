import 'package:get/get.dart';
import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/storage_service.dart';
import '../models/performance_model.dart';

class PerformanceController extends GetxController {
  var isLoading = true.obs;
  var isOnline = false.obs;
  var isLoadingToggle = false.obs; // For toggle loading state

  var performance = PerformanceModel(
    driverId: '',
    isOnline: false,
    accountStatus: '',
    averageRating: 0.0,
    totalRatings: 0,
    totalRides: 0,
    acceptanceRate: 0.0,
    cancellationRate: 0.0,
    totalEarnings: 0,
    totalBonus: 0,
    walletBalance: 0,
    unsettledBalance: 0,
  ).obs;

  @override
  void onInit() {
    super.onInit();
    _restoreOnlineStatus();
    fetchPerformanceData();
  }

  void _restoreOnlineStatus() {
    final wasOnline = StorageService.getDriverOnlineStatus();
    print('🔄 Restoring previous online status from storage: $wasOnline');
    isOnline.value = wasOnline;
  }

  Future<void> fetchPerformanceData() async {
    try {
      isLoading.value = true;


      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      final response = await FHttpHelper.get('driver/performance');

      if (response['data'] != null) {
        performance.value = PerformanceModel.fromJson(response['data']);
        // Update online status from API response
        isOnline.value = performance.value.isOnline;
        // Sync with storage
        await StorageService.setDriverOnlineStatus(performance.value.isOnline);
      }
    } catch (e) {
      print('Error fetching performance data: $e');
      FSnackbar.show(title: "Error", message: "Failed to load performance data", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleOnline(bool val) async {
    if (isOnline.value == val) {
      print('ℹ️ Driver already ${val ? 'online' : 'offline'}, skipping');
      return;
    }

    // Show loading immediately
    isLoadingToggle(true);

    try {
      final body = {"is_online": val};
      final token = StorageService.getAuthToken();

      if (token == null) {
        FSnackbar.show(title: "Error", message: "User token not found. Please login again.", isError: true);
        isLoadingToggle(false);
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response = await FHttpHelper.post("driver/online", body);
      print("Driver online API response: $response");

      final serverStatus = response['is_online'] ?? false;

      // Update local state based on server response
      isOnline.value = serverStatus;
      await StorageService.setDriverOnlineStatus(serverStatus);

      // Update performance data with new online status
      performance.value = PerformanceModel(
        driverId: performance.value.driverId,
        isOnline: serverStatus,
        accountStatus: performance.value.accountStatus,
        averageRating: performance.value.averageRating,
        totalRatings: performance.value.totalRatings,
        totalRides: performance.value.totalRides,
        acceptanceRate: performance.value.acceptanceRate,
        cancellationRate: performance.value.cancellationRate,
        totalEarnings: performance.value.totalEarnings,
        totalBonus: performance.value.totalBonus,
        walletBalance: performance.value.walletBalance,
        unsettledBalance: performance.value.unsettledBalance,
      );

      if (serverStatus) {
        FSnackbar.show(title: "Online", message: response['message'] ?? "You are now online");
      } else {
        FSnackbar.show(title: "Offline", message: response['message'] ?? "You are now offline", isError: true);
      }

    } catch (e, s) {
      print("❌ toggleOnline error: $e\n$s");
      FSnackbar.show(title: "Error", message: "Failed to toggle online status", isError: true);
      // Revert the toggle if API call fails
      isOnline.value = !val;
    } finally {
      isLoadingToggle(false);
    }
  }

  // Helper method to format account status for display
  String getFormattedAccountStatus(String status) {
    switch (status) {
      case 'approved':
        return 'Active (no warnings)';
      case 'pending':
        return 'Pending Approval';
      case 'suspended':
        return 'Suspended';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  // Helper method to format account health based on metrics
  String getAccountHealth() {
    if (performance.value.cancellationRate < 5 &&
        performance.value.averageRating >= 4.0 &&
        performance.value.acceptanceRate >= 80) {
      return 'Excellent';
    } else if (performance.value.cancellationRate < 10 &&
        performance.value.averageRating >= 3.5) {
      return 'Good';
    } else {
      return 'Needs Improvement';
    }
  }

  // Helper method for achievements
  String getAchievement() {
    final rides = performance.value.totalRides;
    if (rides != null) return 'Completed ${performance.value.totalRides.toInt()} rides';
    // if (rides >= 1000) return 'Completed 1000 rides';
    // if (rides >= 500) return 'Completed 500 rides';
    // if (rides >= 100) return 'Completed 100 rides';
    // if (rides >= 50) return 'Completed 50 rides';
    return 'Getting started';
  }
}