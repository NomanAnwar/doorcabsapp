import 'package:get/get.dart';
import '../models/performance_model.dart';

class PerformanceController extends GetxController {
  var isOnline = true.obs;
  // var currentIndex = 2.obs;

  final performance = PerformanceModel(
    totalRides: 1234,
    accountStatus: "Active (no warnings)",
    rating: 4.8,
    reviewCount: 123,
    acceptanceRate: 95,
    cancellationRate: 5,
    earnings: 1234,
    walletBalance: 1850,
    bonus: 550,
    achievement: "Completed 1000 rides",
    accountHealth: "Excellent",
  ).obs;

  void toggleOnline(bool value) {
    isOnline.value = value;
  }
}
