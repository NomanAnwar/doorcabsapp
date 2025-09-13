import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ride_request_controller.dart';

class PaymentBottomSheet {
  static void show() {
    final controller = Get.find<RideRequestController>();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
              Text("Payment Method", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              SizedBox(height: 12),
              _buildPaymentTile("Cash Payment", Icons.attach_money, controller),
              _buildPaymentTile("Easypaisa", Icons.account_balance_wallet, controller),
              _buildPaymentTile("JazzCash", Icons.account_balance_wallet, controller),
              _buildPaymentTile("Debit/Credit Card", Icons.credit_card, controller),
              _buildPaymentTile("DoorCabs Wallet", Icons.account_balance_wallet, controller),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  static Widget _buildPaymentTile(String title, IconData icon, RideRequestController controller) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        controller.selectedPaymentLabel.value = title.contains("Cash") ? "Cash" : title;
        Get.back();
      },
    );
  }
}