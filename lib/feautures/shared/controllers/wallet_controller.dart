import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:doorcab/utils/http/http_client.dart';
import '../../../common/widgets/snakbar/snackbar.dart';
import '../models/wallet_model.dart';
import '../screens/payment_methods_screen.dart';

class WalletController extends GetxController {
  var isLoading = true.obs;
  var walletData = WalletModel.fallback(isDriver: true).obs;

  @override
  void onInit() {
    super.onInit();
    fetchWalletData();
  }

  Future<void> fetchWalletData() async {
    try {
      isLoading.value = true;
      print("🔄 Starting wallet API call...");


      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response = await FHttpHelper.get('wallet/get/user');
      print("📡 API Response received: ${response}");

      // Check if API call was successful
      if (response['balance'] != null) {
        print("✅ API call successful, parsing data...");

        // Parse API response into our model
        walletData.value = WalletModel.fromJson(response);

        // Debug print to verify data
        print("👤 User Name: ${walletData.value.userName}");
        print("💰 Actual Balance: ${walletData.value.actualBalance}");
        print("📊 Unsettled Balance: ${walletData.value.unsettledBalance}");
        print("🎯 Transactions Count: ${walletData.value.transactions.length}");
        print("👨‍💼 User Type: ${walletData.value.userType}");

      } else {
        print("❌ API returned success: false or missing success field");
        print("📋 Response keys: ${response.keys}");
        // Fallback to static data if API fails
        walletData.value = WalletModel.fallback(isDriver: isDriver);
      }
    } catch (e) {
      print("❌ Error fetching wallet data: $e");
      // Fallback to static data
      walletData.value = WalletModel.fallback(isDriver: isDriver);
    } finally {
      isLoading.value = false;
      print("🏁 Loading completed, isLoading: ${isLoading.value}");
    }
  }

  // Helper method to check if user is driver
  bool get isDriver => _getCurrentRole().toLowerCase() == 'driver';

  // Get current wallet based on role
  WalletModel get currentWallet => walletData.value;

  // Get current transactions
  List<TransactionModel> get currentTransactions => walletData.value.transactions;

  // Get current profile image based on role
  String get currentProfileImage => isDriver
      ? 'assets/images/driver.png'
      : 'assets/images/driver.png';

  // Get current role from storage
  String _getCurrentRole() {
    return StorageService.getRole() ?? 'Driver';
  }

  final RxInt currentIndex = 3.obs;

  void addFunds() {
    Get.back();
    Get.to(() => PaymentMethodsScreen());
  }

  // void topUp() {
  //   Get.snackbar('Top Up', 'Topping up wallet...');
  // }

  // In WalletController - Just update the topUp method
  void topUp() {
    if (!isDriver) {
      // For passengers, use the regular add funds flow
      addFunds();
      return;
    }

    final wallet = currentWallet;
    final unsettledBalance = wallet.unsettledBalance;
    final actualBalance = wallet.actualBalance;

    print('💳 Driver Top Up - Balance: $actualBalance, Unsettled: $unsettledBalance');

    if (unsettledBalance <= 0) {
      Get.snackbar(
        'No Pending Balance',
        'You have no pending balance to settle.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (actualBalance >= unsettledBalance) {
      // ✅ Balance is sufficient - Show payment popup
      _showSettlementPopup();
    } else {
      // ❌ Balance is insufficient
      Get.snackbar(
        'Insufficient Balance',
        'Please add balance first. You need PKR ${unsettledBalance.toInt()} but only have PKR ${actualBalance.toInt()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

// ✅ NEW: Process settlement
  Future<void> _processSettlement() async {
    try {
      Get.back(); // Close dialog
      isLoading.value = true;

      print('🔄 Processing settlement...');

      // Call settlement endpoint with empty body
      final response = await FHttpHelper.post('payment/settle', {});

      print('📡 Settlement API Response: $response');

      isLoading.value = false;

      if (response['message'] != null &&
          response['message'].toString().toLowerCase().contains('success')) {

        // ✅ Success
        FSnackbar.show(
          title: 'Payment Successful',
          message: 'Pending balance settled successfully!',
        );

        // Refresh wallet data
        fetchWalletData();

      } else {
        // ❌ API error
        String errorMessage = response['message'] ?? 'Payment failed';
        FSnackbar.show(
          title: 'Payment Failed',
          message: errorMessage,
          isError: true,
        );
      }

    } catch (e) {
      isLoading.value = false;
      print('❌ Settlement error: $e');
      FSnackbar.show(
        title: 'Error',
        message: '$e',
        isError: true,
      );
    }
  }

  void onTransactionTap(TransactionModel transaction) {
    Get.snackbar(
        transaction.displayTitle,
        'Amount: ${transaction.displayAmount}\nDate: ${transaction.displayDate}\nDescription: ${transaction.description}'
    );
  }

  // ✅ OPTION 2: More precise styling matching your screen
  void _showSettlementPopup() {
    final unsettledAmount = currentWallet.unsettledBalance;
    final screenWidth = Get.width;
    final baseWidth = 440.0;

    double sw(double w) => w * screenWidth / baseWidth;

    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: sw(20)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sw(20)),
        ),
        backgroundColor: Colors.white,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(sw(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                "Settle Pending Balance",
                style: TextStyle(
                  fontSize: sw(18),
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: sw(10)),

              // Subtitle
              Text(
                "Pay your pending amount to DoorCab",
                style: TextStyle(
                  fontSize: sw(14),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: sw(20)),

              // Amount Card - Similar to your wallet cards
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(sw(16)),
                decoration: BoxDecoration(
                  color: Color(0xFFFFF4E6), // Your light yellow color
                  borderRadius: BorderRadius.circular(sw(12)),
                  border: Border.all(color: Color(0xFFFFC300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Pending Amount:",
                      style: TextStyle(
                        fontSize: sw(16),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "PKR ${unsettledAmount.toInt()}",
                      style: TextStyle(
                        fontSize: sw(18),
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366), // Your primary blue color
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sw(25)),

              // Buttons Row
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: Container(
                      height: sw(48),
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF2F2F2), // Your grey color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(sw(8)),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: sw(16),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: sw(12)),

                  // Pay Button
                  Expanded(
                    child: Container(
                      height: sw(48),
                      child: ElevatedButton(
                        onPressed: _processSettlement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFC300), // Your yellow color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(sw(8)),
                          ),
                        ),
                        child: Text(
                          "Pay Now",
                          style: TextStyle(
                            fontSize: sw(16),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

