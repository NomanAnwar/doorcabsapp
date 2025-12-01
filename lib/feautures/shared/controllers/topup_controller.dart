import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:doorcab/utils/http/http_client.dart';
import '../models/topup_model.dart';
import '../screens/wallet_screen.dart';

class TopUpController extends GetxController {
  // Observables
  final selectedAmount = 320.obs;
  final baseAmount = 320.obs;
  final amountController = TextEditingController();
  final selectedNavIndex = 3.obs;
  final isLoading = false.obs;
  final walletData = Rx<TopUpModel?>(null);
  final isEditing = false.obs;

  // Selected payment method (passed from previous screen)
  final selectedPaymentMethod = 'jazzcash'.obs;

  // Quick amounts calculated from baseAmount only
  RxList<Map<String, dynamic>> get quickAmounts {
    int amt = baseAmount.value > 0 ? baseAmount.value : 320;
    return RxList<Map<String, dynamic>>([
      {'amount': amt, 'rides': 7},
      {'amount': amt * 2, 'rides': 15},
      {'amount': amt * 3, 'rides': 22},
    ]);
  }

  @override
  void onInit() {
    super.onInit();

    // Get payment method from previous screen arguments
    if (Get.arguments != null && Get.arguments['type'] != null) {
      selectedPaymentMethod.value = Get.arguments['type'].toString().toLowerCase();
    }

    amountController.text = selectedAmount.value.toString();
    loadWalletData();
  }

  void toggleEditing() {
    isEditing.value = !isEditing.value;
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }

  // Load wallet data from backend
  Future<void> loadWalletData() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 500));

      walletData.value = TopUpModel(
        paymentMethod: _getPaymentMethodDisplayName(),
        paymentMethodIcon: '',
        currentBalance: 1500.0,
        quickAmounts: [320, 640, 960],
      );

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to load wallet data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Helper method to get display name
  String _getPaymentMethodDisplayName() {
    switch (selectedPaymentMethod.value.toLowerCase()) {
      case 'jazzcash':
        return 'Jazzcash';
      case 'easypaisa':
        return 'Easypaisa';
      case 'card':
        return 'Card';
      default:
        return 'Jazzcash';
    }
  }

  // Select amount from quick buttons
  void selectAmount(int amount) {
    selectedAmount.value = amount;
    amountController.text = amount.toString();
  }

  // Update amount from text field
  void updateAmount(String value) {
    int parsedAmount = int.tryParse(value) ?? 0;
    baseAmount.value = parsedAmount > 0 ? parsedAmount : 0;
    selectedAmount.value = baseAmount.value;
    update();
  }

  // Change bottom navigation
  void changeNavIndex(int index) {
    selectedNavIndex.value = index;

    switch (index) {
      case 0:
      // Get.toNamed('/requests-list');
        break;
      case 1:
      // Get.toNamed('/schedule-ride');
        break;
      case 2:
      // Get.toNamed('/performance');
        break;
      case 3:
      // Already on Wallet screen
        break;
    }
  }

  // Top up wallet via API
  Future<void> topUpWallet() async {
    if (selectedAmount.value <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a valid amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color.fromRGBO(255, 195, 0, 1),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Prepare request body
      final requestBody = {
        "amount": selectedAmount.value,
        "method": selectedPaymentMethod.value,
        "status": "success"
      };

      print("🔄 Sending top-up request: $requestBody");

      // Call API endpoint
      final response = await FHttpHelper.post('topup/create', requestBody);

      print("📡 API Response: $response");

      isLoading.value = false;

      if (response['message'] == "Top-up processed successfully") {
        // Success - show message and navigate to wallet
        Get.snackbar(
          'Success',
          'Top up of PKR ${selectedAmount.value} completed successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Navigate back to wallet screen after short delay
        Get.back();
        await Future.delayed(const Duration(milliseconds: 100));
        Get.back();
        Get.off(() => WalletScreen());
        // Get.until((route) => route.settings.name == '/wallet' || Get.previousRoute == '/wallet');

      } else {
        // API returned success: false
        String errorMessage = response['message'] ?? 'Top up failed. Please try again.';
        Get.snackbar(
          'Failed',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      print("❌ Top-up error: $e");
      Get.snackbar(
        'Error',
        'Failed to process top up: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}