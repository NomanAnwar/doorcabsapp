import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../utils/http/http_client.dart';

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

  late final Map<String, dynamic> rideArgs;

  @override
  void onInit() {
    super.onInit();

    rideArgs = Map<String, dynamic>.from(Get.arguments ?? {});
    print("📌 Ride args in AvailableBidsController: $rideArgs");

    final argBids = rideArgs['bids'];
    if (argBids != null) {
      if (argBids is RxList<Map<String, dynamic>>) {
        ever(argBids, (_) {
          bids.assignAll(argBids);
        });
        bids.assignAll(argBids);
      } else if (argBids is List<Map<String, dynamic>>) {
        bids.assignAll(argBids);
      }
    }

    print("📌 Initial bids: $bids");

    _startCountdown();
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

  /// ✅ Accept a bid and call backend
  Future<void> acceptBid(Map bid) async {
    try {
      _timer?.cancel();

      final bidId = bid['bidId'];
      if (bidId == null) {
        Get.snackbar("Error", "Invalid bid ID.");
        return;
      }

      // Parse ETA (example: "1 min" or "5 mins")
      DateTime etaDateTime = DateTime.now().toUtc();
      if (bid['eta'] != null && bid['eta'].toString().contains("min")) {
        final parts = bid['eta'].toString().split(" ");
        final minutes = int.tryParse(parts[0]) ?? 0;
        etaDateTime = etaDateTime.add(Duration(minutes: minutes));
      }

      // Format ETA to ISO
      final etaIso =
      DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(etaDateTime);

      // ✅ Merge bid + rideArgs
      final body = {
        "bidId": bidId,
        "rideId": rideArgs['rideId'],
        "pickup": rideArgs['pickup'],
        "dropoffs": rideArgs['dropoffs'],
        "fare": rideArgs['fare'],
        "passengers": rideArgs['passengers'],
        "payment": rideArgs['payment'],
        "rideType": rideArgs['rideType'],
        "estimated_arrival_time": etaIso,
      };

      print("🚀 Sending accept-bid request: $body");

      final response = await FHttpHelper.post("ride/accept-bids", body);

      print("✅ Accept bid API Response: $response");

      if (response['message'] == "Bid accepted successfully.") {
        Get.snackbar("Bid Accepted",
            "Driver ${bid['driver']?['name']?['firstName'] ?? ''} confirmed");

        // Navigate to next screen with response
        final responseMap = Map<String, dynamic>.from(response);
        Get.toNamed("/drivers-waiting", arguments: {...responseMap,
          'bid': bid,});
      } else {
        Get.snackbar("Error", response['message'] ?? "Failed to accept bid");
      }
    } catch (e, s) {
      print("❌ Error in acceptBid: $e");
      print(s);
      Get.snackbar("Error", "Something went wrong while accepting bid.");
    }
  }

  void rejectBid(Map bid) {
    bids.remove(bid);
  }

  void cancelRequest() {
    _timer?.cancel();
    Get.back();
    Get.snackbar("Cancelled", "Your ride request was cancelled.");
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
