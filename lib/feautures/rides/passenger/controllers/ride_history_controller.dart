import 'package:get/get.dart';
import '../models/driver_model.dart';

class RideHistoryController extends GetxController {
  final rides = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    // populate mock history
    rides.assignAll(List.generate(8, (i) {
      final fare = 250 + i * 10;
      return {
        'id': i,
        'title': i % 2 == 0 ? 'Door Comfort' : 'Door Bike',
        'time': '11:${(i+1).toString().padLeft(2, '0')} PM',
        'date': 'Sunday, August ${10 - i}',
        'fare': fare,
        'status': i % 3 == 0 ? 'Canceled' : 'Completed',
        'driver': DriverModel(
          id: i,
          name: 'Malik shahid',
          car: 'Suzuki Alto',
          avatar: 'assets/images/profile_img_sample.png',
          phone: '03244227502',
          rating: 4.9,
          totalRatings: 120,
          category: 'AC Ride',
          eta: 2,
          distance: 0.65,
          fare: fare,
          pickup: 'Model Town Link Rd Zainab Tower',
          dropoff: 'Township, Lahore',
        ).toMap(),
      };
    }));
  }

  void openDetail(Map<String, dynamic> ride) {
    Get.toNamed('/ride-detail', arguments: ride);
  }
}
