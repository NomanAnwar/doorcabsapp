import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_model.dart';

class WalletScreen extends StatelessWidget {
  final WalletController controller = Get.put(WalletController());

  WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive values
    final horizontalPadding = screenWidth * 0.05;
    final avatarSize = screenWidth * 0.28;
    final nameSize = screenWidth * 0.06;
    final balanceSize = screenWidth * 0.055;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Wallet',
          style: TextStyle(
            color: Colors.black,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      drawer: null,

      body: SingleChildScrollView( // ✅ REMOVED Obx
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Avatar
              Center(
                child: Container( // ✅ REMOVED inner Obx
                  width: avatarSize.clamp(80.0, 120.0),
                  height: avatarSize.clamp(80.0, 120.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF4E6),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      controller.currentProfileImage, // ✅ Direct access
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: avatarSize.clamp(40.0, 60.0),
                          color: Colors.grey,
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Name
              Text(
                controller.currentWallet.name,
                style: TextStyle(
                  fontSize: nameSize.clamp(20.0, 24.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.005),

              // ID or Wallet Balance subtitle
              Text(
                controller.currentWallet.id,
                style: TextStyle(
                  fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: screenHeight * 0.025),

              // Balance Section (only for driver)
              if (controller.isDriver) ...[
                Text(
                  'Balance',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.036).clamp(12.0, 14.0),
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  controller.currentWallet.balance,
                  style: TextStyle(
                    fontSize: balanceSize.clamp(20.0, 32.0),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
              ],

              // Pending Banner (Driver) or Wallet Row (Passenger)
              if (controller.isDriver)
                _buildPendingBanner(screenWidth, screenHeight)
              else
                _buildPassengerWalletRow(screenWidth, screenHeight),

              SizedBox(height: screenHeight * 0.02),

              // Action Buttons
              _buildActionButtons(screenWidth, screenHeight),

              SizedBox(height: screenHeight * 0.03),

              // Transactions Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.05).clamp(18.0, 20.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Transaction List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.currentTransactions.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: screenHeight * 0.015),
                itemBuilder: (context, index) {
                  final transaction = controller.currentTransactions[index];
                  return _buildTransactionItem(
                    transaction,
                    screenWidth,
                    screenHeight,
                  );
                },
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),

      bottomNavigationBar: null,
    );
  }

  // ... rest of your methods remain exactly the same
  Widget _buildPendingBanner(double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.018,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCC00),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              controller.currentWallet.pendingLabel ?? '',
              style: TextStyle(
                fontSize: (screenWidth * 0.04).clamp(14.0, 16.0),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            controller.currentWallet.pendingAmount ?? '',
            style: TextStyle(
              fontSize: (screenWidth * 0.04).clamp(14.0, 16.0),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerWalletRow(double screenWidth, double screenHeight) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.018,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC00),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'DoorCabs Wallet',
                style: TextStyle(
                  fontSize: (screenWidth * 0.038).clamp(13.0, 16.0),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.018,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                controller.currentWallet.balance,
                style: TextStyle(
                  fontSize: (screenWidth * 0.038).clamp(13.0, 16.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(double screenWidth, double screenHeight) {
    final buttonWidth =
        (screenWidth - (screenWidth * 0.1) - (screenWidth * 0.03)) / 2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: buttonWidth,
          height: screenHeight * 0.055,
          child: ElevatedButton(
            onPressed: controller.addFunds,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Add funds',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        SizedBox(
          width: buttonWidth,
          height: screenHeight * 0.055,
          child: ElevatedButton(
            onPressed: controller.topUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2F2F2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Top up',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
      TransactionModel transaction, double screenWidth, double screenHeight) {
    return InkWell(
      onTap: () => controller.onTransactionTap(transaction),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenHeight * 0.006,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.025),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.arrow_outward, size: 18),
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  Text(
                    transaction.subtitle,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              transaction.amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                transaction.isPositive ? Colors.green : Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}