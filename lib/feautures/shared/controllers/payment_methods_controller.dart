import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/payment_method_model.dart';


class PaymentMethodController extends GetxController {
  final paymentMethod = PaymentMethodModel().obs;

  // Text editing controllers
  final cardNumberController = TextEditingController();
  final expiryDateController = TextEditingController();
  final cvvController = TextEditingController();
  final jazzcashController = TextEditingController();
  final easypasaController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Initialize with default values if needed
    loadPaymentMethods();
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

  // Load payment methods from backend
  void loadPaymentMethods() {
    // TODO: Implement API call to load payment methods
    // Example:
    // final data = await apiService.getPaymentMethods();
    // paymentMethod.value = PaymentMethodModel.fromJson(data);
    // updateTextControllers();
  }

  // Update text controllers with loaded data
  void updateTextControllers() {
    cardNumberController.text = paymentMethod.value.cardNumber;
    expiryDateController.text = paymentMethod.value.expiryDate;
    cvvController.text = paymentMethod.value.cvv;
    jazzcashController.text = paymentMethod.value.jazzcashNumber;
    easypasaController.text = paymentMethod.value.easypasaNumber;
  }

  // Toggle card enabled
  void toggleCard(bool value) {
    paymentMethod.update((val) {
      val!.isCardEnabled = value;
    });
  }

  // Toggle Jazzcash
  void toggleJazzcash(bool value) {
    paymentMethod.update((val) {
      val!.isJazzcashEnabled = value;
    });
  }

  // Toggle Easypasa
  void toggleEasypasa(bool value) {
    paymentMethod.update((val) {
      val!.isEasypasaEnabled = value;
    });
  }

  // Update card number
  void updateCardNumber(String value) {
    paymentMethod.update((val) {
      val!.cardNumber = value;
    });
  }

  // Update expiry date
  void updateExpiryDate(String value) {
    paymentMethod.update((val) {
      val!.expiryDate = value;
    });
  }

  // Update CVV
  void updateCvv(String value) {
    paymentMethod.update((val) {
      val!.cvv = value;
    });
  }

  // Update Jazzcash number
  void updateJazzcashNumber(String value) {
    paymentMethod.update((val) {
      val!.jazzcashNumber = value;
    });
  }

  // Update Easypasa number
  void updateEasypasaNumber(String value) {
    paymentMethod.update((val) {
      val!.easypasaNumber = value;
    });
  }

  // Add new payment method
  void addNewPaymentMethod() {
    print('Payment Method Data: ${paymentMethod.value.toJson()}');

    Get.snackbar(
      'Success',
      'Payment method added successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFFFC300),
      colorText: Colors.black,
    );
  }
}