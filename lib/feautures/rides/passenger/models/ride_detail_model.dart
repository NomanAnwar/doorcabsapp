class RideDetailModel {
  final String date;
  final String time;
  final String rideType;
  final String location;
  final String dropLocation;
  final double ridePrice;
  final double promoAmount;
  final double totalFare;
  final String paymentMethod;
  final String driverName;
  final String driverRating;
  final String driverProfilePic;
  final String carModel;
  final String licensePlate;
  final String arrivalTime;
  final String dropTime;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final String totalrides;

  RideDetailModel({
    required this.date,
    required this.time,
    required this.rideType,
    required this.location,
    required this.dropLocation,
    required this.ridePrice,
    required this.promoAmount,
    required this.totalFare,
    required this.paymentMethod,
    required this.driverName,
    required this.driverRating,
    required this.driverProfilePic,
    required this.carModel,
    required this.licensePlate,
    required this.arrivalTime,
    required this.dropTime,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    required this.totalrides,
  });

  /// ✅ copyWith to update only specific fields
  RideDetailModel copyWith({
    String? location,
    String? dropLocation,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
  }) {
    return RideDetailModel(
      date: date,
      time: time,
      rideType: rideType,
      location: location ?? this.location,
      dropLocation: dropLocation ?? this.dropLocation,
      ridePrice: ridePrice,
      promoAmount: promoAmount,
      totalFare: totalFare,
      paymentMethod: paymentMethod,
      driverName: driverName,
      driverRating: driverRating,
      driverProfilePic: driverProfilePic,
      carModel: carModel,
      licensePlate: licensePlate,
      arrivalTime: arrivalTime,
      dropTime: dropTime,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      totalrides: totalrides,
    );
  }
}
