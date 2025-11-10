import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/formatters/formatter.dart';
import '../controllers/payment_methods_controller.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentMethodController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Scaling factors for responsive design
    final widthFactor = screenWidth / 440;
    final heightFactor = screenHeight / 956;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(context, widthFactor, heightFactor),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20 * heightFactor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 37 * heightFactor),

                      // Add Debit/Credit Card Details
                      Padding(
                        padding: EdgeInsets.only(left: 41 * widthFactor),
                        child: Text(
                          'Add Debit/Credit Card Details',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 18 * widthFactor,
                            height: 23 / 18,
                            color: const Color(0xFF141414),
                          ),
                        ),
                      ),

                      SizedBox(height: 25 * heightFactor),

                      // Card Icon and Toggle
                      _buildCardSection(controller, widthFactor, heightFactor),

                      SizedBox(height: 18 * heightFactor),

                      // Digital Wallets
                      Padding(
                        padding: EdgeInsets.only(left: 41 * widthFactor),
                        child: Text(
                          'Digital Wallets',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 18 * widthFactor,
                            height: 23 / 18,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      SizedBox(height: 19 * heightFactor),

                      // Jazzcash Section
                      _buildJazzcashSection(controller, widthFactor, heightFactor),

                      SizedBox(height: 18 * heightFactor),

                      // Easypasa Section
                      _buildEasypasaSection(controller, widthFactor, heightFactor),

                      SizedBox(height: 30 * heightFactor),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Button at Bottom
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 41 * widthFactor,
                vertical: 16 * heightFactor,
              ),
              child: _buildAddButton(controller, widthFactor, heightFactor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double widthFactor, double heightFactor) {
    return Container(
      padding: EdgeInsets.only(
        left: 33 * widthFactor,
        right: 33 * widthFactor,
        top: 23 * heightFactor,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 28.02 * widthFactor,
                height: 28.02 * heightFactor,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/icons/Arrow.svg',
                  width: 28 * widthFactor,
                  // color: Colors.black,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              'Payment Methods',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                fontSize: 18 * widthFactor,
                height: 23 / 18,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection(PaymentMethodController controller, double widthFactor, double heightFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 35 * widthFactor),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Card Icon
              Container(
                width: 37 * widthFactor,
                height: 22.9 * heightFactor,
                child: SvgPicture.asset(
                  'assets/transaction/card.svg',
                  width: 37 * widthFactor,
                  height: 22.9 * heightFactor,
                ),
              ),
              Obx(() => _buildCustomToggle(
                value: controller.paymentMethod.value.isCardEnabled,
                onChanged: (value) => controller.toggleCard(value),
                widthFactor: widthFactor,
                heightFactor: heightFactor,
              )),
            ],
          ),
          SizedBox(height: 18 * heightFactor),
          // Text fields always visible - Fixed overflow
          Row(
            children: [
              Expanded(
                flex: 213,
                child: _buildTextField(
                  controller: controller.cardNumberController,
                  height: 52 * heightFactor,
                  hintText: '0000 0000 0000 0000',
                  onChanged: (value) => controller.updateCardNumber(value),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    CardNumberInputFormatter(),
                  ],
                ),
              ),
              SizedBox(width: 9 * widthFactor),
              Expanded(
                flex: 74,
                child: _buildTextField(
                  controller: controller.expiryDateController,
                  height: 52 * heightFactor,
                  hintText: '10/05',
                  onChanged: (value) => controller.updateExpiryDate(value),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    ExpiryDateInputFormatter(),
                  ],
                ),
              ),
              SizedBox(width: 9 * widthFactor),
              Expanded(
                flex: 67,
                child: _buildTextField(
                  controller: controller.cvvController,
                  height: 52 * heightFactor,
                  hintText: 'CVC',
                  onChanged: (value) => controller.updateCvv(value),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJazzcashSection(PaymentMethodController controller, double widthFactor, double heightFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 39 * widthFactor),
      child: Column(
        children: [
          Row(
            children: [
              // Jazzcash Icon
              Container(
                width: 39 * widthFactor,
                height: 39 * heightFactor,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/transaction/Jazzcash.png',
                  width: 39 * widthFactor,
                  height: 39 * heightFactor,
                ),
              ),
              SizedBox(width: 14 * widthFactor),
              Text(
                'Jazzcash',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 16 * widthFactor,
                  height: 24 / 16,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Obx(() => _buildCustomToggle(
                value: controller.paymentMethod.value.isJazzcashEnabled,
                onChanged: (value) => controller.toggleJazzcash(value),
                widthFactor: widthFactor,
                heightFactor: heightFactor,
              )),
            ],
          ),
          SizedBox(height: 11 * heightFactor),
          // Text field always visible
          _buildTextField(
            controller: controller.jazzcashController,
            width: double.infinity,
            height: 52 * heightFactor,
            hintText: '0300 123 4567',
            onChanged: (value) => controller.updateJazzcashNumber(value),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
              PhoneNumberInputFormatter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEasypasaSection(PaymentMethodController controller, double widthFactor, double heightFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 39 * widthFactor),
      child: Column(
        children: [
          Row(
            children: [
              // Easypasa Icon
              Container(
                width: 39 * widthFactor,
                height: 39 * heightFactor,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  'assets/transaction/easypaisa.svg',
                  width: 39 * widthFactor,
                  height: 39 * heightFactor,
                ),
              ),
              SizedBox(width: 14 * widthFactor),
              Text(
                'Easypasa',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 16 * widthFactor,
                  height: 24 / 16,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Obx(() => _buildCustomToggle(
                value: controller.paymentMethod.value.isEasypasaEnabled,
                onChanged: (value) => controller.toggleEasypasa(value),
                widthFactor: widthFactor,
                heightFactor: heightFactor,
              )),
            ],
          ),
          SizedBox(height: 11 * heightFactor),
          // Text field always visible
          _buildTextField(
            controller: controller.easypasaController,
            width: double.infinity,
            height: 52 * heightFactor,
            hintText: '0300 000 0000',
            onChanged: (value) => controller.updateEasypasaNumber(value),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
              PhoneNumberInputFormatter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    double? width,
    required double height,
    required String hintText,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
          width: 2,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.grey[400],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCustomToggle({
    required bool value,
    required Function(bool) onChanged,
    required double widthFactor,
    required double heightFactor,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 51 * widthFactor,
        height: 31 * heightFactor,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.5),
          color: value ? const Color(0xFFFFC300) : Colors.grey[300],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 27 * widthFactor,
            height: 27 * heightFactor,
            margin: EdgeInsets.symmetric(horizontal: 2 * widthFactor),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(PaymentMethodController controller, double widthFactor, double heightFactor) {
    return GestureDetector(
      onTap: () => controller.addNewPaymentMethod(),
      child: Container(
        width: double.infinity,
        height: 48 * heightFactor,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFFFC300),
        ),
        alignment: Alignment.center,
        child: Text(
          'Add New Payment Method',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w500,
            fontSize: 16 * widthFactor,
            height: 24 / 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

}