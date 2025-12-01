import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../rides/driver/screens/reuseable_widgets/driver_bottom_nav.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_model.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';

import '../services/storage_service.dart';

class WalletScreen extends StatelessWidget {
  final WalletController controller = Get.put(WalletController());

  WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base reference (iPhone 16 Pro Max)
    final baseWidth = 440.0;
    final baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: sw(24)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Wallet',
          style: FTextTheme.lightTextTheme.headlineLarge?.copyWith(
            fontSize: sw(18),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),

      body: Obx(() {
        final loading = controller.isLoading.value;
        final wallet = controller.currentWallet;
        final transactions = controller.currentTransactions;

        // ✅ FIX: Safe data extraction with null checks
        Map<String, dynamic>? profileData = StorageService.getProfile();

        print("User profile on app drawer : " + profileData.toString());

        String profileImage = '';

        if (profileData != null) {
          try {
            profileImage = profileData['Profile_Image']?.toString() ?? '';
          } catch (e) {
            print('❌ Error parsing profile data: $e');
          }
        }

        return Stack(
          children: [
            /// Main UI
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: sw(20),
                  vertical: sh(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Avatar
                    Center(
                      child: Container(
                        width: sw(100),
                        height: sw(100),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF4E6),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          children: [
                            // ClipOval(
                            //   child: Image.asset(
                            //     controller.currentProfileImage,
                            //     fit: BoxFit.cover,
                            //     errorBuilder: (context, error, stackTrace) {
                            //       return Icon(
                            //         Icons.person,
                            //         size: sw(40),
                            //         color: Colors.grey,
                            //       );
                            //     },
                            //   ),
                            // ),
                            CircleAvatar(
                              radius: sw(50),
                              // backgroundColor: Colors.grey[300],
                              backgroundImage:
                                  profileImage.isNotEmpty &&
                                          profileImage.startsWith('http')
                                      ? NetworkImage(profileImage)
                                          as ImageProvider
                                      : AssetImage(
                                        profileImage.isEmpty
                                            ? 'assets/Dashboard/profile.png'
                                            : profileImage,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: sh(20)),

                    // Name
                    Text(
                      wallet.displayName,
                      style: FTextTheme.lightTextTheme.headlineLarge?.copyWith(
                        fontSize: sw(20),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: sh(5)),

                    // ID or Wallet Balance subtitle
                    if (controller.isDriver) ...[
                      Text(
                        wallet.displayId,
                        style: FTextTheme.lightTextTheme.bodyMedium?.copyWith(
                          fontSize: sw(14),
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    SizedBox(height: sh(25)),

                    // Balance Section (only for driver)
                    if (controller.isDriver) ...[
                      Text(
                        'Balance',
                        style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                          fontSize: sw(14),
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: sh(5)),
                      Text(
                        wallet.displayBalance,
                        style: FTextTheme.lightTextTheme.displaySmall?.copyWith(
                          fontSize: sw(28),
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: sh(25)),
                    ],

                    // Pending Banner (Driver) or Wallet Row (Passenger)
                    if (controller.isDriver)
                      _buildPendingBanner(wallet, sw, sh)
                    else
                      _buildPassengerWalletRow(wallet, sw, sh),

                    SizedBox(height: sh(20)),

                    // Action Buttons
                    _buildActionButtons(sw, sh),

                    SizedBox(height: sh(30)),

                    // Transactions Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Transactions',
                        style: FTextTheme.lightTextTheme.headlineSmall
                            ?.copyWith(
                              fontSize: sw(18),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                      ),
                    ),
                    SizedBox(height: sh(20)),

                    // Transaction List
                    if (transactions.isEmpty && !loading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sh(40)),
                        child: Text(
                          'No transactions found',
                          style: FTextTheme.lightTextTheme.bodyMedium?.copyWith(
                            fontSize: sw(14),
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        separatorBuilder:
                            (context, index) => SizedBox(height: sh(15)),
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return _buildTransactionItem(transaction, sw, sh);
                        },
                      ),
                    SizedBox(height: sh(20)),
                  ],
                ),
              ),
            ),

            /// Loader Overlay
            if (loading)
              Container(
                height: screenHeight,
                width: screenWidth,
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: CircularProgressIndicator(
                    color: FColors.secondaryColor,
                  ),
                ),
              ),
          ],
        );
      }),

      bottomNavigationBar:
          controller.isDriver
              ? DriverBottomNav(
                currentIndex: 3, // Wallet is active
                isRequestsListActive: false,
              )
              : SizedBox(),
    );
  }

  Widget _buildPendingBanner(
    WalletModel wallet,
    double Function(double) sw,
    double Function(double) sh,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: sw(20), vertical: sh(18)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCC00),
        borderRadius: BorderRadius.circular(sw(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              wallet.displayPendingLabel,
              style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                fontSize: sw(14),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            wallet.displayPendingAmount,
            style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
              fontSize: sw(14),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerWalletRow(
    WalletModel wallet,
    double Function(double) sw,
    double Function(double) sh,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: sw(16), vertical: sh(18)),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC00),
              borderRadius: BorderRadius.circular(sw(12)),
            ),
            child: Center(
              child: Text(
                'DoorCabs Wallet',
                style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                  fontSize: sw(14),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: sw(12)),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: sw(16), vertical: sh(18)),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(sw(12)),
            ),
            child: Center(
              child: Text(
                wallet.displayBalance,
                style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                  fontSize: sw(14),
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

  Widget _buildActionButtons(
    double Function(double) sw,
    double Function(double) sh,
  ) {
    final buttonWidth = (sw(440) - sw(40) - sw(12)) / 2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: controller.isDriver ? buttonWidth : sw(380),
          height: sh(48),
          child: ElevatedButton(
            onPressed: controller.addFunds,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(sw(8)),
              ),
            ),
            child: Text(
              'Top Up',
              style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: sw(14),
              ),
            ),
          ),
        ),
        SizedBox(width: sw(12)),
        if (controller.isDriver) ...[
          SizedBox(
            width: buttonWidth,
            height: sh(48),
            child: ElevatedButton(
              onPressed: controller.topUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2F2F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(sw(8)),
                ),
              ),
              child: Text(
                'Settlement',
                style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontSize: sw(14),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTransactionItem(
    TransactionModel transaction,
    double Function(double) sw,
    double Function(double) sh,
  ) {
    return InkWell(
      onTap: () => controller.onTransactionTap(transaction),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sw(12), vertical: sh(8)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(sw(10)),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(sw(6)),
              ),
              child: Icon(
                transaction.isPositive
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                size: sw(18),
                color: transaction.isPositive ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(width: sw(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.displayTitle,
                    style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: sw(14),
                    ),
                  ),
                  SizedBox(height: sh(2)),
                  Text(
                    transaction.description,
                    style: FTextTheme.lightTextTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: sw(12),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: sh(2)),
                  Text(
                    transaction.displayDate,
                    style: FTextTheme.lightTextTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: sw(10),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              transaction.displayAmount,
              style: FTextTheme.lightTextTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: transaction.isPositive ? Colors.green : Colors.redAccent,
                fontSize: sw(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
