// lib/feautures/rides/models/ride.dart
class Ride {
  final String service;
  final String time;
  final int price;

  Ride({required this.service, required this.time, required this.price});
}


class RideModel {
  final String date;
  final String time;
  final String location;
  final String rideType;
  final double fare;
  final String status;
  final String iconPath; // new for images

  RideModel({
    required this.date,
    required this.time,
    required this.location,
    required this.rideType,
    required this.fare,
    required this.status,
    required this.iconPath,
  });
}
