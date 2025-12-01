import 'package:get/get.dart';
import '../storage_service.dart';

class DriverRideQueueManager extends GetxController {
  static DriverRideQueueManager get instance => Get.find<DriverRideQueueManager>();

  final RxBool hasQueuedRide = false.obs;
  final RxList<Map<String, dynamic>> queuedRides = RxList<Map<String, dynamic>>([]);

  @override
  void onInit() {
    super.onInit();
    _loadQueuedRides();
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    _loadQueuedRides();
    print('✅ DriverRideQueueManager ready');
  }

  void _loadQueuedRides() {
    final rides = StorageService.getQueueRides();
    queuedRides.value = rides;
    hasQueuedRide.value = rides.isNotEmpty;
  }

  Future<void> addRideToQueue(String rideId, Map<String, dynamic> rideData) async {
    if (StorageService.canAddMoreQueueRides()) {
      await StorageService.saveQueueRide(rideId, rideData);
      _loadQueuedRides();
      print("✅ Ride added to queue: $rideId");
    } else {
      print("❌ Queue is full, cannot add more rides");
    }
  }

  Future<void> removeRideFromQueue(String rideId) async {
    await StorageService.removeQueueRide(rideId);
    _loadQueuedRides();
    print("✅ Ride removed from queue: $rideId");
  }

  Map<String, dynamic>? getNextQueuedRide() {
    return queuedRides.isNotEmpty ? queuedRides.first : null;
  }

  void clearAllQueuedRides() {
    StorageService.clearAllQueueRides();
    _loadQueuedRides();
    print("🧹 All queued rides cleared");
  }

  bool canAcceptMoreRides() {
    return StorageService.canAddMoreQueueRides();
  }

  int getQueueSize() {
    return queuedRides.length;
  }
}