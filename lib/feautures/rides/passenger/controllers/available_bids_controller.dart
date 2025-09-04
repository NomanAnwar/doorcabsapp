import 'dart:async';
import 'package:get/get.dart';

class AvailableBidsController extends GetxController {
  final bids = <Map<String, dynamic>>[].obs;
  final driverAvatars = <String>[
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
    "assets/images/profile_img_sample.png",
  ].obs;
  final viewingDrivers = 3.obs;
  final autoAccept = false.obs;
  final remainingSeconds = 60.obs;
  Timer? _timer;
  Timer? _bidTimer;

  @override
  void onInit() {
    super.onInit();
    _startCountdown();
    _simulateIncomingBids();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        t.cancel();
      }
    });
  }

  void _simulateIncomingBids() {
    // Simulate bids coming in every 5-10 seconds
    _bidTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (bids.length < 5) { // Limit to 5 simultaneous bids
        _addNewBid();
      }
    });
  }

  void _addNewBid() {
    final bidId = DateTime.now().millisecondsSinceEpoch;
    final newBid = {
      'id': bidId,
      'name': "Driver ${bids.length + 1}",
      'car': "Toyota Corolla",
      'fare': 250 + bids.length * 20,
      'eta': 5 + bids.length,
      'distance': (1.5 + bids.length * 0.3).toStringAsFixed(1),
      'avatar': driverAvatars[bids.length % driverAvatars.length],
      'rating': (4.0 + bids.length * 0.1).toStringAsFixed(1),
      'totalRatings': 100 + bids.length * 20,
      'category': "Standard",
      'progress': 1.0.obs, // Start with full progress
    };

    bids.insert(0, newBid);

    // Start countdown for this bid (10 seconds)
    _startBidCountdown(bidId);
  }

  void _startBidCountdown(int bidId) {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final bidIndex = bids.indexWhere((bid) => bid['id'] == bidId);
      if (bidIndex == -1) {
        timer.cancel();
        return;
      }

      final bid = bids[bidIndex];
      final progress = bid['progress'] as RxDouble;
      progress.value -= 0.01; // Decrease progress by 1% every 100ms

      if (progress.value <= 0) {
        timer.cancel();
        bids.removeWhere((bid) => bid['id'] == bidId);
      }
    });
  }

  void acceptBid(Map bid) {
    // First stop timers so bids don't keep coming in
    _timer?.cancel();
    _bidTimer?.cancel();

    // Remove this bid from the list
    // bids.remove(bid);

    // Navigate to DriversWaitingScreen with selected driver data
    Get.toNamed("/drivers-waiting", arguments: bid);

    // Optionally show a confirmation snackbar
    Get.snackbar("Bid Accepted", "Driver ${bid['name']} confirmed");
  }


  void rejectBid(Map bid) {
    bids.remove(bid);
  }

  void cancelRequest() {
    _timer?.cancel();
    _bidTimer?.cancel();
    Get.back();
    Get.snackbar("Cancelled", "Your ride request was cancelled.");
  }

  @override
  void onClose() {
    _timer?.cancel();
    _bidTimer?.cancel();
    super.onClose();
  }
}