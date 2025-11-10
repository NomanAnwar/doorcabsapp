class TransactionModel {
  final String title;
  final String subtitle;
  final String amount;
  final bool isPositive;

  TransactionModel({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
  });
}

class WalletModel {
  final String name;
  final String id;
  final String balance;
  final String? pendingAmount;
  final String? pendingLabel;

  WalletModel({
    required this.name,
    required this.id,
    required this.balance,
    this.pendingAmount,
    this.pendingLabel,
  });
}
