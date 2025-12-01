import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../common/widgets/snakbar/snackbar.dart';
import '../../../splash/views/welcome_screen.dart';
import '../../../utils/http/http_client.dart';
import '../services/storage_service.dart';

class DeleteAccountScreen extends StatelessWidget {
  DeleteAccountScreen({super.key});

  final TextEditingController _reasonController = TextEditingController();
  final RxBool _isLoading = false.obs;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final baseWidth = 440.0;
    final baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              /// White Background Container (like ProfileScreen)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white,
                ),
              ),

              /// Back Arrow button - positioned like ProfileScreen
              Positioned(
                top: sh(23),
                left: sw(23),
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: sw(28),
                    height: sh(28),
                    child: SvgPicture.asset(
                      "assets/images/Arrow.svg",
                      width: sw(28),
                      height: sh(28),
                    ),
                  ),
                ),
              ),

              /// Title - positioned centrally at top
              Positioned(
                top: sh(23),
                left: 0,
                right: 0,
                child: Container(
                  height: sh(28),
                  alignment: Alignment.center,
                  child: Text(
                    "Delete Account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Plus Jakarta Sans",
                      fontWeight: FontWeight.w700,
                      fontSize: sw(18),
                      height: 23 / 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              /// Confirmation Text
              Positioned(
                top: sh(80),
                left: sw(25),
                right: sw(25),
                child: Text(
                  "Are you sure you want to delete your account?",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: "Plus Jakarta Sans",
                    fontWeight: FontWeight.w700,
                    fontSize: sw(22),
                    height: 28 / 22,
                    color: Colors.black,
                  ),
                ),
              ),

              /// Description Text
              Positioned(
                top: sh(150),
                left: sw(25),
                right: sw(25),
                child: Text(
                  "Deleting your account will permanently remove all your data, including ratings, reviews, and payment information. This action cannot be undone.",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: "Plus Jakarta Sans",
                    fontWeight: FontWeight.w400,
                    fontSize: sw(16),
                    height: 24 / 16,
                    color: Colors.black87,
                  ),
                ),
              ),

              /// Reason TextField
              Positioned(
                bottom: sh(100),
                left: sw(25),
                right: sw(25),
                child: Container(
                  width: sw(405),
                  height: sh(163),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E3E3),
                    borderRadius: BorderRadius.circular(sw(14)),
                  ),
                  child: TextField(
                    controller: _reasonController,
                    maxLines: null,
                    style: TextStyle(
                      fontSize: sw(16),
                      fontFamily: "Plus Jakarta Sans",
                    ),
                    decoration: const InputDecoration(
                      hintText: "Write reason",
                      hintStyle: TextStyle(color: Colors.black45),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              /// Delete Account Button - Fixed at bottom
              Positioned(
                left: sw(25),
                right: sw(25),
                bottom: sh(30),
                child: Obx(() {
                  return SizedBox(
                    width: sw(358),
                    height: sh(48),
                    child: ElevatedButton(
                      onPressed: _isLoading.value ? null : _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDF0A0A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(sw(8)),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading.value
                          ? SizedBox(
                        width: sw(20),
                        height: sw(20),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        "Delete Account",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta Sans",
                          fontWeight: FontWeight.w600,
                          fontSize: sw(16),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              /// Loader Overlay
              Obx(() {
                if (_isLoading.value) {
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.black.withOpacity(0.4),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      _isLoading.value = true;

      if(_reasonController.text == "" || _reasonController.text.isEmpty){
        FSnackbar.show(title: "Error", message: "Please explain the reason.", isError: true);
        return;
      }

      final body = {
        "reason": _reasonController.text.toString(),
      };

      // Call delete account endpoint
      final response = await FHttpHelper.post('service/delete', body);

      // Clear all storage data
      await _clearAllStorageData();

      // Show success message
      FSnackbar.show(
        title: "Account Deleted",
        message: "Your account has been successfully deleted",
      );

      // Navigate to WelcomeScreen
      Get.offAll(() => WelcomeScreen());

    } catch (e) {
      print('Error deleting account: $e');
      FSnackbar.show(
        title: "Error",
        message: "Failed to delete account. Please try again.",
        isError: true,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _clearAllStorageData() async {
    try {
      // Clear all storage using StorageService
      await StorageService.clearAll();

      // Additional specific clears if needed
      await StorageService.clearAllActiveRides();
      await StorageService.clearAllQueueRides();
      await StorageService.clearDriverOnlineStatus();
      await StorageService.clearPaymentMethod();

      print('🧹 All storage data cleared successfully');

    } catch (e) {
      print('Error clearing storage: $e');
      // Continue even if storage clearing fails
    }
  }
}