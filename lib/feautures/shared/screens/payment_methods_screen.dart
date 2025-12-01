import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../utils/formatters/formatter.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/payment_methods_controller.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentMethodController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base reference (iPhone 16 Pro Max)
    final baseWidth = 440.0;
    final baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(context, sw, sh),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(bottom: sh(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: sh(37)),

                      // Add Debit/Credit Card Details
                      Padding(
                        padding: EdgeInsets.only(left: sw(15)),
                        child: Text(
                          'Add Debit/Credit Card Details',
                          style: FTextTheme.lightTextTheme.headlineLarge?.copyWith(
                            fontSize: sw(18),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF141414),
                          ),
                        ),
                      ),

                      SizedBox(height: sh(25)),

                      // Card Icon and Toggle
                      _buildCardSection(controller, context, sw, sh),

                      SizedBox(height: sh(18)),

                      // Digital Wallets
                      Padding(
                        padding: EdgeInsets.only(left: sw(15)),
                        child: Text(
                          'Digital Wallets',
                          style: FTextTheme.lightTextTheme.headlineLarge?.copyWith(
                            fontSize: sw(18),
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      SizedBox(height: sh(19)),

                      // Jazzcash Section
                      _buildJazzcashSection(controller, context, sw, sh),

                      SizedBox(height: sh(18)),

                      // Easypasa Section
                      _buildEasypasaSection(controller, context, sw, sh),

                      SizedBox(height: sh(30)),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Button at Bottom
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: sw(15),
                vertical: sh(16),
              ),
              child: _buildAddButton(controller, context, sw, sh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double Function(double) sw, double Function(double) sh) {
    return Container(
      padding: EdgeInsets.only(
        left: sw(33),
        right: sw(33),
        top: sh(23),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: sw(28),
                height: sh(28),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/icons/Arrow.svg',
                  width: sw(28),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              'Payment Methods',
              style: FTextTheme.lightTextTheme.headlineLarge?.copyWith(
                fontSize: sw(18),
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection(PaymentMethodController controller, BuildContext context, double Function(double) sw, double Function(double) sh) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sw(15)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Card Icon
              Container(
                width: sw(37),
                height: sh(23),
                child: SvgPicture.asset(
                  'assets/transaction/card.svg',
                  width: sw(37),
                  height: sh(23),
                ),
              ),
              Obx(() => _buildCustomToggle(
                value: controller.paymentMethod.value.isCardEnabled,
                onChanged: (value) => controller.toggleCard(value),
                sw: sw,
                sh: sh,
              )),
            ],
          ),
          SizedBox(height: sh(18)),
          // Text fields always visible
          Row(
            children: [
              Expanded(
                flex: 213,
                child: _buildTextField(
                  controller: controller.cardNumberController,
                  height: sh(55),
                  hintText: '0000 0000 0000 0000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    CardNumberInputFormatter(),
                  ],
                  sw: sw,
                  sh: sh,
                ),
              ),
              SizedBox(width: sw(5)),
              Expanded(
                flex: 70,
                child: _buildTextField(
                  controller: controller.expiryDateController,
                  height: sh(55),
                  hintText: '10/05',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    ExpiryDateInputFormatter(),
                  ],
                  sw: sw,
                  sh: sh,
                ),
              ),
              SizedBox(width: sw(5)),
              Expanded(
                flex: 70,
                child: _buildTextField(
                  controller: controller.cvvController,
                  height: sh(55),
                  hintText: 'CVC',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  sw: sw,
                  sh: sh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJazzcashSection(PaymentMethodController controller, BuildContext context, double Function(double) sw, double Function(double) sh) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sw(15)),
      child: Column(
        children: [
          Row(
            children: [
              // Jazzcash Icon
              Container(
                width: sw(39),
                height: sh(39),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(sw(8)),
                ),
                child: Image.asset(
                  'assets/transaction/Jazzcash.png',
                  width: sw(39),
                  height: sh(39),
                ),
              ),
              SizedBox(width: sw(14)),
              Text(
                'Jazzcash',
                style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
                  fontSize: sw(16),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Obx(() => _buildCustomToggle(
                value: controller.paymentMethod.value.isJazzcashEnabled,
                onChanged: (value) => controller.toggleJazzcash(value),
                sw: sw,
                sh: sh,
              )),
            ],
          ),
          SizedBox(height: sh(11)),
          // Text field always visible
          _buildTextField(
            controller: controller.jazzcashController,
            width: double.infinity,
            height: sh(55),
            hintText: '0300 123 4567',
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
              PhoneNumberInputFormatter(),
            ],
            sw: sw,
            sh: sh,
          ),
        ],
      ),
    );
  }

  Widget _buildEasypasaSection(PaymentMethodController controller, BuildContext context, double Function(double) sw, double Function(double) sh) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sw(15)),
      child: Column(
        children: [
          Row(
            children: [
              // Easypasa Icon
              Container(
                width: sw(39),
                height: sh(39),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(sw(8)),
                ),
                child: SvgPicture.asset(
                  'assets/transaction/easypaisa.svg',
                  width: sw(39),
                  height: sh(39),
                ),
              ),
              SizedBox(width: sw(14)),
              Text(
                'Easypasa',
                style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
                  fontSize: sw(16),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Obx(() => _buildCustomToggle(
                value: controller.paymentMethod.value.isEasypasaEnabled,
                onChanged: (value) => controller.toggleEasypasa(value),
                sw: sw,
                sh: sh,
              )),
            ],
          ),
          SizedBox(height: sh(11)),
          // Text field always visible
          _buildTextField(
            controller: controller.easypasaController,
            width: double.infinity,
            height: sh(55),
            hintText: '0300 000 0000',
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
              PhoneNumberInputFormatter(),
            ],
            sw: sw,
            sh: sh,
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required double Function(double) sw,
    required double Function(double) sh,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(sw(14)),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
          width: 2,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: FTextTheme.lightTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: FTextTheme.lightTextTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: Colors.grey[400],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: sw(15), vertical: sh(14)),
        ),
      ),
    );
  }

  Widget _buildCustomToggle({
    required bool value,
    required Function(bool) onChanged,
    required double Function(double) sw,
    required double Function(double) sh,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: sw(51),
        height: sh(31),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(sw(15.5)),
          color: value ? const Color(0xFFFFC300) : Colors.grey[300],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: sw(27),
            height: sh(27),
            margin: EdgeInsets.symmetric(horizontal: sw(2)),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(
      PaymentMethodController controller,
      BuildContext context,
      double Function(double) sw,
      double Function(double) sh,
      ) {
    return Obx(() {
      bool enabled = controller.isButtonEnabled.value;

      return GestureDetector(
        onTap: enabled ? () => controller.addNewPaymentMethod() : null,
        child: Container(
          width: double.infinity,
          height: sh(48),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(sw(8)),
            color: enabled ? const Color(0xFFFFC300) : Colors.grey[400],
          ),
          alignment: Alignment.center,
          child: Text(
            'Add New Payment Method',
            style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
              fontSize: sw(16),
              fontWeight: FontWeight.w500,
              color: enabled ? Colors.black : Colors.white,
            ),
          ),
        ),
      );
    });
  }
}