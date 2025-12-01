import 'package:doorcab/feautures/shared/controllers/topup_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';

class TopUpScreen extends StatelessWidget {
  const TopUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TopUpController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: sh(100)),
              child: Column(
                children: [
                  // Back Arrow
                  Padding(
                    padding: EdgeInsets.only(top: sh(39), left: sw(33)),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: SvgPicture.asset(
                          'assets/icons/Arrow.svg',
                          width: sw(28),
                          height: sw(28),
                        ),
                      ),
                    ),
                  ),

                  // Payment Method Box - Dynamic based on selection
                  Obx(() => Container(
                    margin: EdgeInsets.only(top: sh(47), left: sw(4)),
                    width: sw(380),
                    height: sh(97),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(243, 243, 243, 1),
                      borderRadius: BorderRadius.circular(sw(10)),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: sw(17)),
                          child: _buildPaymentIcon(controller.selectedPaymentMethod.value, sw, sh),
                        ),
                        SizedBox(width: sw(15)),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPaymentMethodName(controller.selectedPaymentMethod.value),
                              style: FTextTheme.lightTextTheme.headlineSmall?.copyWith(
                                fontSize: sw(20),
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Payment Method',
                              style: FTextTheme.lightTextTheme.bodyMedium?.copyWith(
                                fontSize: sw(12),
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),

                  // Enter Amount Section
                  Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: sh(20), left: sw(30), right: sw(30)),
                        width: sw(380),
                        height: sh(97),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(sw(10)),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: sw(20), vertical: sh(15)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Enter amount',
                              style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                                fontSize: sw(16),
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: sh(5)),
                            Expanded(
                              child: Obx(() => TextField(
                                controller: controller.amountController,
                                enabled: controller.isEditing.value,
                                style: FTextTheme.lightTextTheme.displaySmall?.copyWith(
                                  fontSize: sw(32),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                  prefix: Text(
                                    'PKR ',
                                    style: FTextTheme.lightTextTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: sw(32),
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: controller.updateAmount,
                              )),
                            ),
                          ],
                        ),
                      ),
                      // Edit Icon on top-right corner
                      Positioned(
                        top: sh(30),
                        right: sw(35),
                        child: GestureDetector(
                          onTap: controller.toggleEditing,
                          child: Obx(() => SvgPicture.asset(
                            'assets/Dashboard/edit.svg',
                            width: sw(25),
                            height: sw(24),
                            color: controller.isEditing.value ? Colors.blue : Colors.black,
                          )),
                        ),
                      ),
                    ],
                  ),

                  // Amount Selection Buttons
                  Obx(() => Padding(
                    padding: EdgeInsets.symmetric(horizontal: sw(35), vertical: sh(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: controller.quickAmounts
                          .map((item) => _buildAmountButton(
                        item['amount'] as int,
                        item['rides'] as int,
                        sw,
                        sh,
                        controller,
                      ))
                          .toList(),
                    ),
                  )),

                  // Rides Info Text
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: sw(55)),
                    child: Text(
                      'the number of rides is approximate',
                      style: FTextTheme.lightTextTheme.bodySmall?.copyWith(
                        fontSize: sw(13),
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Top Up Button
                  Obx(() => Padding(
                    padding: EdgeInsets.symmetric(horizontal: sw(42), vertical: sh(13)),
                    child: SizedBox(
                      width: sw(356),
                      height: sh(45),
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.topUpWallet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(sw(10)),
                          ),
                        ),
                        child: controller.isLoading.value
                            ? SizedBox(
                          width: sw(20),
                          height: sw(20),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text(
                          'Top up',
                          style: FTextTheme.lightTextTheme.titleLarge?.copyWith(
                            fontSize: sw(16),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )),

                  SizedBox(height: sh(300)),
                ],
              ),
            ),

            Obx(() => controller.isLoading.value
                ? Container(
              height: screenHeight,
              width: screenWidth,
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: CircularProgressIndicator(
                  color: FColors.secondaryColor,
                ),
              ),
            )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  // Helper method to get payment method name
  String _getPaymentMethodName(String method) {
    switch (method.toLowerCase()) {
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

  // Helper method to build payment icon
  Widget _buildPaymentIcon(String method, double Function(double) sw, double Function(double) sh) {
    switch (method.toLowerCase()) {
      case 'jazzcash':
        return Image.asset(
          'assets/Dashboard/jc.png',
          width: sw(76),
          height: sh(76),
        );
      case 'easypaisa':
        return SvgPicture.asset(
          'assets/transaction/easypaisa.svg',
          width: sw(76),
          height: sh(76),
        );
      case 'card':
        return SvgPicture.asset(
          'assets/transaction/card.svg',
          width: sw(76),
          height: sh(76),
        );
      default:
        return Image.asset(
          'assets/transaction/card.svg',
          width: sw(76),
          height: sh(76),
        );
    }
  }

  Widget _buildAmountButton(
      int amount,
      int rides,
      double Function(double) sw,
      double Function(double) sh,
      TopUpController controller,
      ) {
    return Obx(() {
      bool isSelected = controller.selectedAmount.value == amount;
      return GestureDetector(
        onTap: () => controller.selectAmount(amount),
        child: Container(
          width: sw(116.0),
          height: sh(60.0),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color.fromRGBO(255, 195, 0, 1)
                : const Color.fromRGBO(243, 243, 243, 1),
            borderRadius: BorderRadius.circular(sw(10.0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                amount.toString(),
                style: FTextTheme.lightTextTheme.headlineSmall?.copyWith(
                  fontSize: sw(24.0),
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                '$rides rides',
                style: FTextTheme.lightTextTheme.bodySmall?.copyWith(
                  fontSize: sw(10.0),
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

}