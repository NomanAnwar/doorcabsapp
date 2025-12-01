class TransactionModel {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String userType;
  final String userId;
  final Map<String, dynamic> balanceAtTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.userType,
    required this.userId,
    required this.balanceAtTime,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper getters for display
  bool get isPositive => amount > 0;
  String get displayAmount => '${isPositive ? '+' : ''}PKR ${amount.abs().toStringAsFixed(0)}';

  // Create display title from description
  String get displayTitle {
    if (description.toLowerCase().contains('ride fare') ||
        description.toLowerCase().contains('ride payment')) {
      return 'Ride Payment';
    } else if (description.toLowerCase().contains('commission')) {
      return 'Commission';
    } else if (description.toLowerCase().contains('dispute')) {
      return 'Dispute Resolution';
    } else if (description.toLowerCase().contains('settled')) {
      return 'Payment Settled';
    } else {
      return 'Transaction';
    }
  }

  // Format date for display
  String get displayDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Safe date parsing
    DateTime parseDate(String dateString) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return DateTime.now();
      }
    }

    return TransactionModel(
      id: json['_id']?.toString() ?? '',
      description: json['description']?.toString() ?? 'No description',
      amount: (json['amount'] ?? 0).toDouble(),
      date: parseDate(json['date']?.toString() ?? DateTime.now().toIso8601String()),
      userType: json['user_type']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      balanceAtTime: Map<String, dynamic>.from(json['balance'] ?? {}),
      createdAt: parseDate(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: parseDate(json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

class WalletModel {
  final String id;
  final String userType;
  final String userId;
  final double actualBalance;
  final double unsettledBalance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userName;
  final String userPhone;
  final List<TransactionModel> transactions;

  WalletModel({
    required this.id,
    required this.userType,
    required this.userId,
    required this.actualBalance,
    required this.unsettledBalance,
    required this.createdAt,
    required this.updatedAt,
    required this.userName,
    required this.userPhone,
    required this.transactions,
  });

  // Helper getters for display (compatible with your existing UI)
  String get displayName => userName;

  String get displayId {
    if (userType.toLowerCase() == 'driver') {
      return 'Driver ID ${id.length >= 8 ? id.substring(0, 8) : id}';
    } else {
      return 'PKR ${actualBalance.toStringAsFixed(0)}';
    }
  }

  String get displayBalance => 'PKR ${actualBalance.toStringAsFixed(0)}';

  String get displayPendingAmount {
    if (userType.toLowerCase() == 'driver') {
      return 'PKR ${unsettledBalance.toStringAsFixed(0)}';
    }
    return 'PKR 0';
  }

  String get displayPendingLabel {
    if (userType.toLowerCase() == 'driver') {
      return 'DoorCabs Pending';
    }
    return 'Pending Balance';
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    try {
      final userData = json['user'] ?? {};
      final nameData = userData['name'] ?? {};
      final balanceData = json['balance'] ?? {};

      String firstName = nameData['firstName']?.toString() ?? '';
      String lastName = nameData['lastName']?.toString() ?? '';
      String fullName = '$firstName $lastName'.trim();
      if (fullName.isEmpty) fullName = 'User';

      List<TransactionModel> transactionsList = [];
      if (json['transactions'] != null && json['transactions'] is List) {
        transactionsList = (json['transactions'] as List)
            .whereType<Map<String, dynamic>>()
            .map((transactionJson) => TransactionModel.fromJson(transactionJson))
            .toList();
      }

      // Handle date parsing safely
      DateTime parseDate(String dateString) {
        try {
          return DateTime.parse(dateString);
        } catch (e) {
          return DateTime.now();
        }
      }

      return WalletModel(
        id: json['_id']?.toString() ?? 'unknown_id',
        userType: json['user_type']?.toString() ?? 'Driver',
        userId: json['user_id']?.toString() ?? 'unknown_user',
        actualBalance: (balanceData['actual_balance'] ?? 0).toDouble(),
        unsettledBalance: (balanceData['unsetteled_balance'] ?? 0).toDouble(),
        createdAt: parseDate(json['createdAt']?.toString() ?? ''),
        updatedAt: parseDate(json['updatedAt']?.toString() ?? ''),
        userName: fullName,
        userPhone: userData['phone_no']?.toString() ?? '',
        transactions: transactionsList,
      );
    } catch (e) {
      print("❌ Error parsing WalletModel: $e");
      // Return fallback model if parsing fails
      return WalletModel.fallback(isDriver: true);
    }
  }

  // For fallback/static data
  WalletModel.fallback({required bool isDriver})
      : id = isDriver ? 'driver_123' : 'passenger_123',
        userType = isDriver ? 'Driver' : 'Passenger',
        userId = isDriver ? 'user_driver_123' : 'user_passenger_123',
        actualBalance = isDriver ? 1500.0 : 150.0,
        unsettledBalance = isDriver ? 150.0 : 0.0,
        createdAt = DateTime.now(),
        updatedAt = DateTime.now(),
        userName = isDriver ? 'Malik Shahid' : 'Ahmad Ali',
        userPhone = isDriver ? '+923001234567' : '+923001234568',
        transactions = isDriver
            ? _getFallbackDriverTransactions()
            : _getFallbackPassengerTransactions();

  static List<TransactionModel> _getFallbackDriverTransactions() {
    return [
      TransactionModel(
        id: '1',
        description: 'Delivery Parcel Payment',
        amount: 250.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        userType: 'Driver',
        userId: 'driver_123',
        balanceAtTime: {'actual_balance': 1500, 'unsetteled_balance': 150},
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: '2',
        description: 'Doorcabs Communion Payment',
        amount: -130.0,
        date: DateTime.now().subtract(const Duration(days: 2)),
        userType: 'Driver',
        userId: 'driver_123',
        balanceAtTime: {'actual_balance': 1250, 'unsetteled_balance': 150},
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  static List<TransactionModel> _getFallbackPassengerTransactions() {
    return [
      TransactionModel(
        id: '1',
        description: 'Ride to Airport',
        amount: -250.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        userType: 'Passenger',
        userId: 'passenger_123',
        balanceAtTime: {'actual_balance': 150, 'unsetteled_balance': 0},
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: '2',
        description: 'Ride to Downtown',
        amount: -130.0,
        date: DateTime.now().subtract(const Duration(days: 2)),
        userType: 'Passenger',
        userId: 'passenger_123',
        balanceAtTime: {'actual_balance': 280, 'unsetteled_balance': 0},
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}


// class TransactionModel {
//   final String title;
//   final String subtitle;
//   final String amount;
//   final bool isPositive;
//
//   TransactionModel({
//     required this.title,
//     required this.subtitle,
//     required this.amount,
//     required this.isPositive,
//   });
// }
//
// class WalletModel {
//   final String name;
//   final String id;
//   final String balance;
//   final String? pendingAmount;
//   final String? pendingLabel;
//
//   WalletModel({
//     required this.name,
//     required this.id,
//     required this.balance,
//     this.pendingAmount,
//     this.pendingLabel,
//   });
// }
