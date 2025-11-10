import 'package:get/get.dart';
import '../models/ride_model.dart';

class RideHistoryController extends GetxController {
  var rides = <RideModel>[].obs;
  var selectedFilter = "All".obs;

  @override
  void onInit() {
    super.onInit();
    fetchRides();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void fetchRides() {
    rides.assignAll([

      RideModel(
        date: "Sunday, August 10",
        time: "11:25 PM",
        location: "Service Ln 63 Home",
        rideType: "Door Comfort",
        fare: 250,
        status: "Completed",
        iconPath: "assets/images/car.png",
      ),
      RideModel(
        date: "Tuesday, August 10",
        time: "07:50 AM",
        location: "Service Ln 63 Home",
        rideType: "Door Bike",
        fare: 133,
        status: "Completed",
        iconPath: "assets/images/bike.png",
      ),
      RideModel(
        date: "Tuesday, August 10",
        time: "11:00 PM",
        location: "Service Ln 63 Home",
        rideType: "Door Comfort",
        fare: 0,
        status: "Canceled",
        iconPath: "assets/images/car.png",
      ),


      RideModel(
        date: "Tuesday, August 05",
        time: "07:50 AM",
        location: "Service Ln 63 Home",
        rideType: "Door Bike",
        fare: 133,
        status: "Completed",
        iconPath: "assets/images/bike.png",
      ),
      RideModel(
        date: "Tuesday, August 05",
        time: "02:50 PM",
        location: "Service Ln 63 Home",
        rideType: "Delivery",
        fare: 275,
        status: "Completed",
        iconPath: "assets/images/delivery.png",
      ),


      RideModel(
        date: "Tuesday, August 05",
        time: "07:50 AM",
        location: "Service Ln 63 Home",
        rideType: "Door Bike",
        fare: 133,
        status: "Completed",
        iconPath: "assets/images/bike.png",
      ),
      RideModel(
        date: "Tuesday, August 05",
        time: "02:50 PM",
        location: "Service Ln 63 Home",
        rideType: "Delivery",
        fare: 275,
        status: "Completed",
        iconPath: "assets/images/delivery.png",
      ),

      RideModel(
        date: "Tuesday, August 05",
        time: "07:50 AM",
        location: "Service Ln 63 Home",
        rideType: "Door Bike",
        fare: 133,
        status: "Completed",
        iconPath: "assets/images/bike.png",
      ),
      RideModel(
        date: "Tuesday, August 05",
        time: "02:50 PM",
        location: "Service Ln 63 Home",
        rideType: "Delivery",
        fare: 275,
        status: "Completed",
        iconPath: "assets/images/delivery.png",
      ),
    ]);
  }
}