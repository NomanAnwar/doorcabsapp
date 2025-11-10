import 'package:doorcab/feautures/shared/screens/rules_terms_screen.dart';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:doorcab/feautures/start/views/getting_started_screen.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/settings_model.dart';
import '../screens/change_city_screen.dart';
import '../screens/change_language_screen.dart';
import '../screens/change_phonenumber_screen.dart';
import '../screens/complaint_screen.dart';
import '../screens/delete_account_screen.dart';
import '../screens/help_screen.dart';
import '../screens/promos_gifts_screen.dart';
import '../screens/wallet_screen.dart';

class SettingsController extends GetxController {
  var userSettings = UserSettings().obs;
  var accountSettings = <SettingItemModel>[].obs;
  var supportSettings = <SettingItemModel>[].obs;

  // Add user mode - default to passenger or get from arguments
  var currentUserMode = '';

  @override
  void onInit() {
    super.onInit();
    // Check if user mode is passed as argument
    // if (Get.arguments != null && Get.arguments['userMode'] != null) {
      currentUserMode = StorageService.getRole()!;
    // }
    loadSettings();
  }

  void loadSettings() {
    accountSettings.value = [
      SettingItemModel(
        id: 'language',
        title: 'Language',
        iconPath: 'assets/drawer/language.svg',
        category: SettingCategory.account,
        onTap: navigateToLanguage,
      ),
      // Conditionally add Promos & Gift OR Change City based on user mode
      if (currentUserMode == 'Passenger')
        SettingItemModel(
          id: 'promos',
          title: 'Promos & Gift',
          iconPath: 'assets/drawer/gift_promo.svg',
          category: SettingCategory.account,
          onTap: navigateToPromos,
        )
      else
        SettingItemModel(
          id: 'changeCity',
          title: 'Change City',
          iconPath: 'assets/drawer/changecity.svg',
          category: SettingCategory.account,
          onTap: navigateToChangeCity,
        ),
      SettingItemModel(
        id: 'wallet',
        title: 'Wallet',
        iconPath: 'assets/drawer/wallet.svg',
        category: SettingCategory.account,
        onTap: navigateToWallet,
      ),
      SettingItemModel(
        id: 'phone',
        title: 'Phone Number',
        iconPath: 'assets/drawer/phone_number.svg',
        category: SettingCategory.account,
        onTap: navigateToPhoneNumber,
      ),
    ];

    supportSettings.value = [
      SettingItemModel(
        id: 'rules',
        title: 'Rules & Terms',
        iconPath: 'assets/drawer/rules.svg',
        category: SettingCategory.support,
        onTap: navigateToRulesTerms,
      ),
      SettingItemModel(
        id: 'faqs',
        title: 'FAQs & Support',
        iconPath: 'assets/drawer/support.svg',
        category: SettingCategory.support,
        onTap: navigateToFAQs,
      ),
      SettingItemModel(
        id: 'complaints',
        title: 'Complaints & Disputes',
        iconPath: 'assets/drawer/complaints.svg',
        category: SettingCategory.support,
        onTap: navigateToComplaints,
      ),
    ];
  }

  // Method to switch user mode dynamically
  // void switchUserMode(UserType mode) {
  //   currentUserMode.value = mode;
  //   loadSettings(); // Reload settings with new mode
  // }

  // Navigation methods
  void navigateToLanguage() {
    Get.to(() => ChangeLanguageScreen());
  }

  void navigateToPromos() {
    Get.to(() => PromoGiftScreen());
  }

  void navigateToChangeCity() {
    Get.to(() => ChangeCityScreen());
  }

  void navigateToWallet() {
    Get.to(() => WalletScreen());
  }

  void navigateToPhoneNumber() {
    Get.to(() => ChangePhoneNumberScreen());
  }

  void navigateToRulesTerms() {
    Get.to(() => RulesTermsScreen());
  }

  void navigateToFAQs() {
    Get.to(() => HelpScreen());
  }

  void navigateToComplaints() {
    Get.to(() => ComplaintsListScreen());
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // Perform logout logic
              Get.snackbar(
                'Logout',
                'Logged out successfully',
                snackPosition: SnackPosition.BOTTOM,
              );
              Get.offAll(() => GettingStartedScreen());
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void deleteAccount() {
    Get.to(() => const DeleteAccountScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }
}