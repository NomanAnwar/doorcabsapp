class PerformanceModel {
  final String driverId;
  final bool isOnline;
  final String accountStatus;
  final double averageRating;
  final int totalRatings;
  final int totalRides;
  final double acceptanceRate;
  final double cancellationRate;
  final double totalEarnings;
  final double totalBonus;
  final double walletBalance;
  final double unsettledBalance;

  PerformanceModel({
    required this.driverId,
    required this.isOnline,
    required this.accountStatus,
    required this.averageRating,
    required this.totalRatings,
    required this.totalRides,
    required this.acceptanceRate,
    required this.cancellationRate,
    required this.totalEarnings,
    required this.totalBonus,
    required this.walletBalance,
    required this.unsettledBalance,
  });

  factory PerformanceModel.fromJson(Map<String, dynamic> json) {
    return PerformanceModel(
      driverId: json['driver_id'] ?? '',
      isOnline: json['is_online'] ?? false,
      accountStatus: json['account_status'] ?? 'unknown',
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      totalRatings: json['total_ratings'] ?? 0,
      totalRides: json['total_rides'] ?? 0,
      acceptanceRate: (json['acceptance_rate'] ?? 0.0).toDouble(),
      cancellationRate: (json['cancellation_rate'] ?? 0.0).toDouble(),
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      totalBonus: (json['total_bonus'] ?? 0).toDouble(),
      walletBalance: json['wallet'] != null ? (json['wallet']['actual_balance'] ?? 0).toDouble() : 0,
      unsettledBalance: json['wallet'] != null ? (json['wallet']['unsettled_balance'] ?? 0).toDouble() : 0,
    );
  }
}