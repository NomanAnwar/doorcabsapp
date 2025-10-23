// lib/features/rides/models/driver_ride_info.dart
// class DriverRideInfo {
//   // Ride details
//   final String rideId;
//   final String bidId;
//   final double fareOffered;
//   final String eta; // arrival
//   final String dropTime;
//   final String distance;
//   final double promoAmount;
//   final String rideType;
//
//   // Pickup / Dropoff
//   final Map<String, dynamic>? pickup;
//   final List<Map<String, dynamic>> dropoffs;
//
//   // Driver details
//   final String driverId;
//   final String driverName;
//   final String driverImage;
//   final String driverPhone;
//   final String vehicleName;
//   final String vehicleType;
//   final String vehicleImage;
//   final String driverBadge;
//   final String driverCategory;
//   final String avgRating;
//   final String totalRatings;
//
//   DriverRideInfo({
//     required this.rideId,
//     required this.bidId,
//     required this.fareOffered,
//     required this.eta,
//     required this.dropTime,
//     required this.distance,
//     required this.promoAmount,
//     required this.rideType,
//     this.pickup,
//     this.dropoffs = const [],
//     required this.driverId,
//     required this.driverName,
//     required this.driverImage,
//     required this.driverPhone,
//     required this.vehicleName,
//     required this.vehicleType,
//     required this.vehicleImage,
//     required this.driverBadge,
//     required this.driverCategory,
//     required this.avgRating,
//     required this.totalRatings,
//   });
//
//   factory DriverRideInfo.fromArgs(Map<String, dynamic> args) {
//     final bid = args['bid'] ?? {};
//     final driver = bid['driver'] ?? {};
//
//     return DriverRideInfo(
//       // Ride
//       rideId: args['rideId'] ?? bid['rideId'] ?? '',
//       bidId: bid['bidId'] ?? '',
//       fareOffered: (bid['fareOffered'] ?? 0).toDouble(),
//       eta: bid['eta']?.toString() ??
//           args['eta']?.toString() ??
//           args['estimated_arrival_time']?.toString() ??
//           '',
//       dropTime: args['estimated_drop_time']?.toString() ?? '',
//       distance: bid['distance']?.toString() ??
//           args['distance']?.toString() ??
//           args['estimated_distance']?.toString() ??
//           '',
//       promoAmount: (args['promoAmount'] ?? 0).toDouble(),
//       rideType: driver['vehicleType']?.toString() ?? '',
//
//       // Pickup & Dropoff
//       pickup: args['pickup'],
//       dropoffs: args['dropoffs'] != null
//           ? List<Map<String, dynamic>>.from(args['dropoffs'])
//           : [],
//
//       // Driver
//       driverId: driver['id'] ?? '',
//       driverName:
//       "${driver['name']?['firstName'] ?? ''} ${driver['name']?['lastName'] ?? ''}".trim(),
//       driverImage: driver['profileImage'] ?? '',
//       driverPhone: driver['phone']?.toString() ?? '',
//       vehicleName: driver['vehicle'] ?? '',
//       vehicleType: driver['vehicleType'] ?? '',
//       vehicleImage: driver['vehicleImage'] ?? '',
//       driverBadge: driver['badge'] ?? '',
//       driverCategory: driver['category'] ?? '',
//       avgRating: driver['avgRating']?.toString() ?? '',
//       totalRatings: driver['total_ratings']?.toString() ?? '',
//     );
//   }
// }



// lib/feautures/rides/models/driver_ride_info.dart
class DriverRideInfo {
  final String rideId;
  final String bidId;
  final double fareOffered;
  final String eta;
  final String estimated_drop_time;
  final String distance;
  final Map<String, dynamic>? pickup;
  final List<Map<String, dynamic>> dropoffs;
  final Map<String, dynamic>? driver;

  DriverRideInfo({
    required this.rideId,
    required this.bidId,
    required this.fareOffered,
    required this.eta,
    required this.estimated_drop_time,
    required this.distance,
    this.pickup,
    this.dropoffs = const [],
    this.driver,
  });

  factory DriverRideInfo.fromArgs(Map<String, dynamic> args) {
    return DriverRideInfo(
      rideId: args['rideId'] ?? '',
      bidId: args['bidId'] ?? '',
      fareOffered: (args['fareOffered'] ?? 0).toDouble(),
      eta: args['eta'] ?? args['estimated_arrival_time'] ?? '',
      estimated_drop_time: args['estimated_drop_time'] ?? args['estimated_drop_time'] ?? '',
      distance: args['distance']?.toString() ??
          args['estimated_distance']?.toString() ??
          '',
      pickup: args['pickup'],
      dropoffs: args['dropoffs'] != null
          ? List<Map<String, dynamic>>.from(args['dropoffs'])
          : [],
      driver: args['driver'],
    );
  }
}
