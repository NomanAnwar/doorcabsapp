import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:get/get.dart';
import '../models/wallet_model.dart';
import '../screens/payment_methods_screen.dart';

class WalletController extends GetxController {
  // Add profile images
  final driverImage = 'assets/images/driver.png';
  final passengerImage = 'assets/images/driver.png';

  final driverWallet = WalletModel(
    name: 'Malik Shahid',
    id: 'Driver ID 123456',
    balance: 'PKR 1500',
    pendingAmount: 'PKR 150',
    pendingLabel: 'DoorCabs Pending',
  ).obs;

  final passengerWallet = WalletModel(
    name: 'Ahmad Ali',
    id: 'PKR 550',
    balance: 'PKR 150',
  ).obs;

  final driverTransactions = <TransactionModel>[
    TransactionModel(
      title: 'Delivery Parcel',
      subtitle: 'Payment',
      amount: '+PKR 250',
      isPositive: true,
    ),
    TransactionModel(
      title: 'Doorcabs Communion',
      subtitle: 'Payment',
      amount: '-PKR 130',
      isPositive: false,
    ),
  ].obs;

  final passengerTransactions = <TransactionModel>[
    TransactionModel(
      title: 'Ride to Airport',
      subtitle: 'Payment',
      amount: '-PKR 250',
      isPositive: false,
    ),
    TransactionModel(
      title: 'Ride to Downtown',
      subtitle: 'Payment',
      amount: '-PKR 130',
      isPositive: false,
    ),
    TransactionModel(
      title: 'Ride to Home',
      subtitle: 'Payment',
      amount: '-PKR 180',
      isPositive: false,
    ),
    TransactionModel(
      title: 'Ride to Office',
      subtitle: 'Payment',
      amount: '-PKR 210',
      isPositive: false,
    ),
  ].obs;

  // Helper method to check if user is driver
  bool get isDriver => _getCurrentRole().toLowerCase() == 'driver';

  // Get current wallet based on role
  WalletModel get currentWallet =>
      isDriver ? driverWallet.value : passengerWallet.value;

  // Get current transactions based on role
  List<TransactionModel> get currentTransactions =>
      isDriver ? driverTransactions : passengerTransactions;

  // Get current profile image based on role
  String get currentProfileImage =>
      isDriver ? driverImage : passengerImage;

  // Switch user type (if you still need this functionality)
  void switchUserType(String role) {
    // You can store the switched role temporarily if needed
    // For now, it will always use StorageService.getRole()
    update(); // Notify listeners
  }

  // Get current role from storage
  String _getCurrentRole() {
    return StorageService.getRole() ?? 'Passenger'; // Default to Passenger if null
  }

  final RxInt currentIndex = 3.obs;

  void addFunds() {
    // Get.snackbar('Add Funds', 'Adding funds to wallet...');
    Get.to(() => PaymentMethodsScreen());
  }

  void topUp() {
    Get.snackbar('Top Up', 'Topping up wallet...');
  }

  void onTransactionTap(TransactionModel transaction) {
    Get.snackbar('Transaction', 'Viewing ${transaction.title}');
  }

  void onBottomNavTap(int index) {
    currentIndex.value = index;
    switch (index) {
      case 0:
        Get.toNamed('/requests');
        break;
      case 1:
        Get.toNamed('/schedule');
        break;
      case 2:
        Get.toNamed('/performance');
        break;
      case 3:
        break;
    }
  }
}