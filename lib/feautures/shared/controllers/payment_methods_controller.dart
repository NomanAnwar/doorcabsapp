import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import '../models/payment_method_model.dart';
import '../screens/topup_screen.dart';

class PaymentMethodController extends GetxController {
  final paymentMethod = PaymentMethodModel().obs;
  final isButtonEnabled = false.obs;

  // Text editing controllers
  final cardNumberController = TextEditingController();
  final expiryDateController = TextEditingController();
  final cvvController = TextEditingController();
  final jazzcashController = TextEditingController();
  final easypasaController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadPaymentMethods();

    // Listen to text changes for real-time validation
    cardNumberController.addListener(() {
      updateCardNumber(cardNumberController.text);
      validateButton();
    });

    expiryDateController.addListener(() {
      updateExpiryDate(expiryDateController.text);
      validateButton();
    });

    cvvController.addListener(() {
      updateCvv(cvvController.text);
      validateButton();
    });

    jazzcashController.addListener(() {
      updateJazzcashNumber(jazzcashController.text);
      validateButton();
    });

    easypasaController.addListener(() {
      updateEasypasaNumber(easypasaController.text);
      validateButton();
    });
  }

  @override
  void onClose() {
    cardNumberController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    jazzcashController.dispose();
    easypasaController.dispose();
    super.onClose();
  }

  // Load payment methods from storage
  void loadPaymentMethods() {
    try {
      final savedData = StorageService.getPaymentMethod();
      if (savedData != null) {
        paymentMethod.value = savedData;
        updateTextControllers();

        // Auto-enable the active method
        if (savedData.activeMethod.isNotEmpty) {
          _enableActiveMethod(savedData.activeMethod);
        }

        validateButton();
        print("✅ Loaded payment method from storage: ${savedData.activeMethod}");
      } else {
        print("ℹ️ No saved payment method found");
      }
    } catch (e) {
      print("❌ Error loading payment methods: $e");
    }
  }

  void _enableActiveMethod(String method) {
    switch (method) {
      case 'card':
        toggleCard(true);
        break;
      case 'jazzcash':
        toggleJazzcash(true);
        break;
      case 'easypaisa':
        toggleEasypasa(true);
        break;
    }
  }

  // Save payment method to storage
  Future<void> _savePaymentMethod() async {
    try {
      await StorageService.savePaymentMethod(paymentMethod.value);
      print("💾 Payment method saved to storage: ${paymentMethod.value.activeMethod}");
    } catch (e) {
      print("❌ Error saving payment method: $e");
    }
  }

  // Update text controllers with loaded data
  void updateTextControllers() {
    cardNumberController.text = paymentMethod.value.cardNumber;
    expiryDateController.text = paymentMethod.value.expiryDate;
    cvvController.text = paymentMethod.value.cvv;
    jazzcashController.text = paymentMethod.value.jazzcashNumber;
    easypasaController.text = paymentMethod.value.easypasaNumber;
  }

  // Toggle methods with exclusive activation
  void toggleCard(bool value) {
    paymentMethod.update((val) {
      val!.isCardEnabled = value;
      if (value) {
        // Disable other methods
        val.isJazzcashEnabled = false;
        val.isEasypasaEnabled = false;
        val.activeMethod = 'card';
      } else {
        val.activeMethod = '';
      }
    });
    _savePaymentMethod();
    validateButton();
  }

  void toggleJazzcash(bool value) {
    paymentMethod.update((val) {
      val!.isJazzcashEnabled = value;
      if (value) {
        // Disable other methods
        val.isCardEnabled = false;
        val.isEasypasaEnabled = false;
        val.activeMethod = 'jazzcash';
      } else {
        val.activeMethod = '';
      }
    });
    _savePaymentMethod();
    validateButton();
  }

  void toggleEasypasa(bool value) {
    paymentMethod.update((val) {
      val!.isEasypasaEnabled = value;
      if (value) {
        // Disable other methods
        val.isCardEnabled = false;
        val.isJazzcashEnabled = false;
        val.activeMethod = 'easypaisa';
      } else {
        val.activeMethod = '';
      }
    });
    _savePaymentMethod();
    validateButton();
  }

  // Update methods
  void updateCardNumber(String value) {
    paymentMethod.update((val) {
      val!.cardNumber = value;
    });
  }

  void updateExpiryDate(String value) {
    paymentMethod.update((val) {
      val!.expiryDate = value;
    });
  }

  void updateCvv(String value) {
    paymentMethod.update((val) {
      val!.cvv = value;
    });
  }

  void updateJazzcashNumber(String value) {
    paymentMethod.update((val) {
      val!.jazzcashNumber = value;
    });
  }

  void updateEasypasaNumber(String value) {
    paymentMethod.update((val) {
      val!.easypasaNumber = value;
    });
  }

  // Validate button
  void validateButton() {
    // Clean the card number (remove spaces)
    String cleanCardNumber = cardNumberController.text.replaceAll(' ', '');

    // Clean the expiry date (remove /)
    String cleanExpiry = expiryDateController.text.replaceAll('/', '');

    // Clean the CVV (remove any non-digit characters)
    String cleanCvv = cvvController.text.replaceAll(RegExp(r'\D'), '');

    bool isCardValid = paymentMethod.value.isCardEnabled &&
        cleanCardNumber.length == 16 &&
        cleanExpiry.length == 4 &&
        cleanCvv.length == 3;

    bool isJazzValid = paymentMethod.value.isJazzcashEnabled &&
        jazzcashController.text.replaceAll(' ', '').length == 11;

    bool isEasypaisaValid = paymentMethod.value.isEasypasaEnabled &&
        easypasaController.text.replaceAll(' ', '').length == 11;

    // If ANY method valid → enable button
    isButtonEnabled.value = isCardValid || isJazzValid || isEasypaisaValid;
  }

  // Get selected payment method type
  String getSelectedPaymentMethod() {
    if (paymentMethod.value.isCardEnabled &&
        cardNumberController.text.replaceAll(' ', '').length == 16 &&
        expiryDateController.text.replaceAll('/', '').length == 4 &&
        cvvController.text.length == 3) {
      return 'card';
    } else if (paymentMethod.value.isJazzcashEnabled &&
        jazzcashController.text.replaceAll(' ', '').length == 11) {
      return 'jazzcash';
    } else if (paymentMethod.value.isEasypasaEnabled &&
        easypasaController.text.replaceAll(' ', '').length == 11) {
      return 'easypaisa';
    }
    return '';
  }

  // Get payment method details for display
  Map<String, dynamic> getSelectedPaymentDetails() {
    String method = getSelectedPaymentMethod();

    switch (method) {
      case 'card':
        return {
          'type': 'card',
          'name': 'Card',
          'icon': 'assets/transaction/card.svg',
          'iconType': 'svg',
          'details': cardNumberController.text,
        };
      case 'jazzcash':
        return {
          'type': 'jazzcash',
          'name': 'Jazzcash',
          'icon': 'assets/transaction/Jazzcash.png',
          'iconType': 'image',
          'details': jazzcashController.text,
        };
      case 'easypaisa':
        return {
          'type': 'easypaisa',
          'name': 'Easypasa',
          'icon': 'assets/transaction/easypaisa.svg',
          'iconType': 'svg',
          'details': easypasaController.text,
        };
      default:
        return {};
    }
  }

  // Add new payment method
  void addNewPaymentMethod() {
    print('Payment Method Data: ${paymentMethod.value.toJson()}');

    // Get selected payment method details
    Map<String, dynamic> selectedMethod = getSelectedPaymentDetails();

    // Navigate to next screen with payment method details
    Get.to(() => TopUpScreen(), arguments: selectedMethod);

    // Get.snackbar(
    //   'Success',
    //   'Payment method added successfully',
    //   snackPosition: SnackPosition.BOTTOM,
    //   backgroundColor: const Color(0xFFFFC300),
    //   colorText: Colors.black,
    // );
  }
}