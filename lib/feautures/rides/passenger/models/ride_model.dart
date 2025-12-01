class RideModel {
  final String id;
  final DateTime rawDate;
  final String date;
  final String time;
  final String location;
  final double fareBase;
  final double fareDistance;
  final double fareSurge;
  final double fareDiscount;
  final double fareWaitingCharge;
  final double acceptedPrice;
  final double? requestedFare;
  final String rideType;
  final String status;
  final String vehicleType;
  final String iconPath;
  final int? estimatedArrivalTime;
  final DateTime? rideStartTime;
  final DateTime? rideEndTime;
  final double? distance;
  final int? rideDuration;
  final bool waitingChargeApplied;
  final bool isPaid;
  final int? passengersNo;

  // FIELDS FOR BOTH ROLES
  final String passengerId;
  final String paymentType;
  final List<DropoffLocation> dropoffLocations;
  final DriverInfo? driverInfo;
  final String? cancellationReason;
  final String? cancelledBy;
  final String? vehicleIcon;
  final PickupLocation pickupLocation;

  // NEW: Store passenger info for driver role
  final DriverInfo? passengerInfo;
  final bool isDriverRole;

  // NEW FIELDS FROM API RESPONSE
  final String? comments;
  final int raiseCount;
  final bool cancellationPolicyApplied;
  final DateTime? driverArrivalTime;
  final DateTime? waitingStartTime;
  final DateTime? waitingEndTime;
  final double? onCompletionDistance;
  final String? vehicleModel;
  final String? vehiclePlateNo;
  final double? driverRating;
  final int? driverTotalRatings;
  final String? driverBadge;
  final double? passengerRating;
  final int? passengerTotalRides;

  RideModel({
    required this.id,
    required this.rawDate,
    required this.date,
    required this.time,
    required this.location,
    required this.fareBase,
    required this.fareDistance,
    required this.fareSurge,
    required this.fareDiscount,
    required this.fareWaitingCharge,
    required this.acceptedPrice,
    required this.requestedFare,
    required this.rideType,
    required this.status,
    required this.vehicleType,
    required this.iconPath,
    required this.estimatedArrivalTime,
    required this.rideStartTime,
    required this.rideEndTime,
    required this.distance,
    required this.rideDuration,
    required this.waitingChargeApplied,
    required this.isPaid,
    required this.passengersNo,
    required this.passengerId,
    required this.paymentType,
    required this.dropoffLocations,
    this.driverInfo,
    this.cancellationReason,
    this.cancelledBy,
    this.vehicleIcon,
    required this.pickupLocation,
    this.passengerInfo,
    required this.isDriverRole,

    // NEW FIELDS
    this.comments,
    required this.raiseCount,
    required this.cancellationPolicyApplied,
    this.driverArrivalTime,
    this.waitingStartTime,
    this.waitingEndTime,
    this.onCompletionDistance,
    this.vehicleModel,
    this.vehiclePlateNo,
    this.driverRating,
    this.driverTotalRatings,
    this.driverBadge,
    this.passengerRating,
    this.passengerTotalRides,
  });

  // 🎯 SMART GETTERS THAT WORK FOR BOTH ROLES
  String get displayName {
    if (isDriverRole) {
      // For driver role: show passenger name
      return passengerInfo != null
          ? '${passengerInfo!.firstName} ${passengerInfo!.lastName}'
          : 'Passenger';
    } else {
      // For passenger role: show driver name
      return driverInfo != null
          ? '${driverInfo!.firstName} ${driverInfo!.lastName}'
          : 'Driver Not Assigned';
    }
  }

  String get displayProfileImage {
    if (isDriverRole) {
      // For driver role: show passenger image
      return passengerInfo?.profileImage ?? '';
    } else {
      // For passenger role: show driver image
      return driverInfo?.profileImage ?? '';
    }
  }

  String get displayRole {
    return isDriverRole ? 'Passenger' : 'Driver';
  }

  String get firstDropoffAddress => dropoffLocations.isNotEmpty
      ? dropoffLocations.first.address
      : 'Unknown Destination';

  double get firstDropoffLat => dropoffLocations.isNotEmpty
      ? dropoffLocations.first.lat
      : 0.0;

  double get firstDropoffLng => dropoffLocations.isNotEmpty
      ? dropoffLocations.first.lng
      : 0.0;

  String get displayFare {
    final statusLower = status.toLowerCase();
    if (statusLower == 'completed' || statusLower == 'started' || statusLower == 'accepted') {
      return "PKR ${acceptedPrice.toInt()}";
    } else if (statusLower == 'requested' || statusLower == 'cancelled' || statusLower == 'canceled') {
      return requestedFare != null && requestedFare! > 0
          ? "PKR ${requestedFare!.toInt()}"
          : "N/A";
    } else {
      return "N/A";
    }
  }

  double get totalFare => acceptedPrice > 0 ? acceptedPrice : (requestedFare ?? 0);

  // 🎯 NEW: Get rating for display
  double get displayRating {
    if (isDriverRole) {
      // For driver: show passenger rating
      return passengerRating ?? 0.0;
    } else {
      // For passenger: show driver rating
      return driverRating ?? 0.0;
    }
  }

  // 🎯 NEW: Get total rides/ratings for display
  int get displayTotalRides {
    if (isDriverRole) {
      // For driver: show passenger total rides
      return passengerTotalRides ?? 0;
    } else {
      // For passenger: show driver total ratings
      return driverTotalRatings ?? 0;
    }
  }

  // 🎯 NEW: Get vehicle info for display
  String get displayVehicleInfo {
    if (isDriverRole) {
      // For driver: show their own vehicle
      return '${vehicleModel ?? vehicleType} ${vehiclePlateNo != null ? '($vehiclePlateNo)' : ''}'.trim();
    } else {
      // For passenger: show driver's vehicle
      return driverInfo?.vehicleInfo ?? vehicleType;
    }
  }

  // 🎯 NEW: Get badge for display
  String get displayBadge {
    if (isDriverRole) {
      // For driver: show passenger info or default
      return 'Passenger';
    } else {
      // For passenger: show driver badge
      return driverBadge ?? 'Driver';
    }
  }

  // 🎯 UNIFIED FACTORY METHOD FOR BOTH ROLES
  factory RideModel.fromApiResponse(Map<String, dynamic> data, {required bool isDriverRole}) {
    // Parse the raw date/time
    DateTime parsedDate;
    try {
      final raw = data['request_datetime'] as String?;
      parsedDate = raw != null ? DateTime.parse(raw) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    // Format date & time
    final formattedDate = _formatDate(parsedDate);
    final formattedTime = _formatTime(parsedDate);

    // Handle pickup location
    String location = 'Unknown Location';
    double pickupLat = 0.0;
    double pickupLng = 0.0;

    if (data['pickup_loc'] is Map) {
      final Map<String, dynamic> pl = data['pickup_loc'];
      final addr = pl['address']?.toString().trim();
      if (addr != null && addr.isNotEmpty) {
        location = addr;
      }
      pickupLat = (pl['lat'] as num?)?.toDouble() ?? 0.0;
      pickupLng = (pl['lng'] as num?)?.toDouble() ?? 0.0;
    }

    final pickupLocation = PickupLocation(
      lat: pickupLat,
      lng: pickupLng,
      city: (data['pickup_loc']?['city'] as String?) ?? '',
      address: location,
    );

    // Parse dropoff locations
    final dropoffLocations = <DropoffLocation>[];
    if (data['dropoff_locs'] is List) {
      for (var loc in data['dropoff_locs']) {
        dropoffLocations.add(DropoffLocation(
          lat: (loc['lat'] as num).toDouble(),
          lng: (loc['lng'] as num).toDouble(),
          address: loc['address'] as String? ?? '',
          stopOrder: loc['stop_order'] as int? ?? 0,
          id: loc['_id'] as String? ?? '',
        ));
      }
    }

    // 🎯 SMART ROLE-BASED USER INFO HANDLING
    DriverInfo? driverInfo;
    DriverInfo? passengerInfo;
    String passengerId = '';

    // NEW: Extract vehicle info, ratings, etc.
    String? vehicleModel;
    String? vehiclePlateNo;
    double? driverRating;
    int? driverTotalRatings;
    String? driverBadge;
    double? passengerRating;
    int? passengerTotalRides;

    if (isDriverRole) {
      // DRIVER ROLE: passenger_id contains passenger details, driver_id is just string

      // Handle passenger info
      if (data['passenger_id'] is Map) {
        final passengerData = data['passenger_id'] as Map<String, dynamic>;
        passengerId = passengerData['_id']?.toString() ?? '';

        // Extract passenger rating and rides
        passengerRating = (passengerData['avg_rating'] as num?)?.toDouble();
        passengerTotalRides = passengerData['total_rides'] as int?;

        passengerInfo = DriverInfo(
          id: passengerId,
          firstName: passengerData['name']?['firstName'] as String? ?? 'Passenger',
          lastName: passengerData['name']?['lastName'] as String? ?? '',
          profileImage: passengerData['Profile_Image'] as String? ?? '',
          avgRating: passengerRating,
          // totalRides: passengerTotalRides,
        );
      } else if (data['passenger_id'] is String) {
        passengerId = data['passenger_id'];
      }

      // Handle driver info (just store ID for driver role)
      if (data['driver_id'] is String) {
        driverInfo = DriverInfo(
          id: data['driver_id'],
          firstName: 'You', // Driver is viewing their own rides
          lastName: '',
          profileImage: '',
        );
      }
    } else {
      // PASSENGER ROLE: driver_id contains driver details, passenger_id is just string

      // Handle passenger ID
      if (data['passenger_id'] is String) {
        passengerId = data['passenger_id'];
      } else if (data['passenger_id'] is Map) {
        passengerId = (data['passenger_id']?['_id'] as String?) ?? '';
      }

      // Handle driver info
      if (data['driver_id'] != null && data['driver_id'] is Map) {
        final driverData = data['driver_id'] as Map<String, dynamic>;

        // Extract driver vehicle info
        if (driverData['vehicle'] is Map) {
          final vehicleData = driverData['vehicle'] as Map<String, dynamic>;
          vehicleModel = vehicleData['model'] as String?;
          vehiclePlateNo = vehicleData['plate_no'] as String?;
        }

        // Extract driver rating and badge
        driverRating = (driverData['avg_rating'] as num?)?.toDouble();
        driverTotalRatings = driverData['total_ratings'] as int?;
        driverBadge = driverData['badge'] as String?;

        driverInfo = DriverInfo(
          id: driverData['_id'] as String? ?? '',
          firstName: driverData['name']?['firstName'] as String? ?? 'Driver',
          lastName: driverData['name']?['lastName'] as String? ?? '',
          profileImage: driverData['Profile_Image'] as String? ?? '',
          avgRating: driverRating,
          totalRatings: driverTotalRatings,
          badge: driverBadge,
          vehicleInfo: vehicleModel != null ? '$vehicleModel ${vehiclePlateNo != null ? '($vehiclePlateNo)' : ''}'.trim() : null,
        );
      }
    }

    // Handle cancellation info
    String? cancellationReason;
    String? cancelledBy;
    if (data['cancelled_by'] is Map) {
      final cancelData = data['cancelled_by'] as Map<String, dynamic>;
      cancellationReason = cancelData['cancellation_reason'] as String?;
      cancelledBy = cancelData['user'] as String?;
    }

    // Fare object
    double baseFare = 0, distCharges = 0, surge = 0, discount = 0, waitingCharge = 0;
    if (data['fare'] is Map) {
      final Map<String, dynamic> fare = data['fare'];
      baseFare = (fare['baseFare'] as num?)?.toDouble() ?? 0;
      distCharges = (fare['distanceCharges'] as num?)?.toDouble() ?? 0;
      surge = (fare['surgeCharges'] as num?)?.toDouble() ?? 0;
      discount = (fare['discount'] as num?)?.toDouble() ?? 0;
      waitingCharge = (fare['waiting_charge_amount'] as num?)?.toDouble() ?? 0;
    }

    // Accepted / requested fare
    double acceptedPrice = (data['accepted_price'] as num?)?.toDouble() ?? 0;
    double? requestedFare = (data['requested_rideFare'] as num?)?.toDouble();

    // Ride type & vehicle
    final String vehicleType = data['vehicle_type']?.toString() ?? '';
    final String apiRideType = data['ride_type']?.toString() ?? '';
    final String rideType = _getRideType(vehicleType, apiRideType);

    // Status
    final String apiStatus = data['status']?.toString() ?? '';
    final String status = _getDisplayStatus(apiStatus);

    // Icon path
    final String iconPath = _getIconPath(vehicleType);

    // Other optional fields
    int? estimatedArrival = (data['estimated_arrival_time'] as num?)?.toInt();
    DateTime? startTime;
    if (data['ride_start_time'] != null) {
      try {
        startTime = DateTime.parse(data['ride_start_time']);
      } catch (_) {}
    }
    DateTime? endTime;
    if (data['ride_end_time'] != null) {
      try {
        endTime = DateTime.parse(data['ride_end_time']);
      } catch (_) {}
    }

    double? distance = (data['distance'] as num?)?.toDouble();
    int? duration = (data['ride_duration'] as num?)?.toInt();
    bool waitingApplied = data['waiting_charge_applied'] as bool? ?? false;
    bool paid = data['isPaid'] as bool? ?? false;
    int? pax = (data['passengers_no'] as num?)?.toInt();

    // NEW: Parse additional fields
    String? comments = data['comments'] as String?;
    int raiseCount = (data['raise_count'] as num?)?.toInt() ?? 0;
    bool cancellationPolicyApplied = data['cancellation_policy_applied'] as bool? ?? false;

    DateTime? driverArrivalTime;
    if (data['driver_arrival_time'] != null) {
      try {
        driverArrivalTime = DateTime.fromMillisecondsSinceEpoch(data['driver_arrival_time'] as int);
      } catch (_) {}
    }

    DateTime? waitingStartTime;
    if (data['waiting_start_time'] != null) {
      try {
        waitingStartTime = DateTime.parse(data['waiting_start_time']);
      } catch (_) {}
    }

    DateTime? waitingEndTime;
    if (data['waiting_end_time'] != null) {
      try {
        waitingEndTime = DateTime.parse(data['waiting_end_time']);
      } catch (_) {}
    }

    double? onCompletionDistance = (data['onCompletion_distance'] as num?)?.toDouble();
    String? vehicleIcon = data['vehicle_icon'] as String?;

    return RideModel(
      id: data['_id']?.toString() ?? '',
      rawDate: parsedDate,
      date: formattedDate,
      time: formattedTime,
      location: location,
      fareBase: baseFare,
      fareDistance: distCharges,
      fareSurge: surge,
      fareDiscount: discount,
      fareWaitingCharge: waitingCharge,
      acceptedPrice: acceptedPrice,
      requestedFare: requestedFare,
      rideType: rideType,
      status: status,
      vehicleType: vehicleType,
      iconPath: iconPath,
      estimatedArrivalTime: estimatedArrival,
      rideStartTime: startTime,
      rideEndTime: endTime,
      distance: distance,
      rideDuration: duration,
      waitingChargeApplied: waitingApplied,
      isPaid: paid,
      passengersNo: pax,
      passengerId: passengerId,
      paymentType: data['payment_type']?.toString() ?? 'cash',
      dropoffLocations: dropoffLocations,
      driverInfo: driverInfo,
      cancellationReason: cancellationReason,
      cancelledBy: cancelledBy,
      vehicleIcon: vehicleIcon,
      pickupLocation: pickupLocation,
      passengerInfo: passengerInfo,
      isDriverRole: isDriverRole,

      // NEW FIELDS
      comments: comments,
      raiseCount: raiseCount,
      cancellationPolicyApplied: cancellationPolicyApplied,
      driverArrivalTime: driverArrivalTime,
      waitingStartTime: waitingStartTime,
      waitingEndTime: waitingEndTime,
      onCompletionDistance: onCompletionDistance,
      vehicleModel: vehicleModel,
      vehiclePlateNo: vehiclePlateNo,
      driverRating: driverRating,
      driverTotalRatings: driverTotalRatings,
      driverBadge: driverBadge,
      passengerRating: passengerRating,
      passengerTotalRides: passengerTotalRides,
    );
  }

  static String _formatDate(DateTime dt) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    String dayName = days[dt.weekday - 1];
    String monthName = months[dt.month - 1];
    return "$dayName, $monthName ${dt.day}";
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  static String _getRideType(String vehicleType, String apiRideType) {
    if (apiRideType.toLowerCase().contains('delivery')) {
      return 'Delivery';
    }
    switch (vehicleType.toLowerCase()) {
      case 'bike': return 'Door Bike';
      case 'ride mini': return 'Door Comfort';
      case 'comfort': return 'Door Comfort';
      case 'premium': return 'Door Premium';
      default: return 'Door Ride';
    }
  }

  static String _getDisplayStatus(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'completed': return 'Completed';
      case 'cancelled': case 'canceled': return 'Canceled';
      case 'requested': return 'Requested';
      case 'accepted': return 'Accepted';
      case 'arrived': return 'Arrived';
      case 'started': return 'Started';
      default: return apiStatus;
    }
  }

  static String _getIconPath(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'bike': return "assets/images/bike.png";
      case 'ride mini': case 'comfort': case 'premium': return "assets/images/car.png";
      case 'delivery': return "assets/images/package.png";
      default: return "assets/images/car.png";
    }
  }

  @override
  String toString() {
    return 'RideModel{id: $id, date: $date, time: $time, location: $location, displayName: $displayName, rideType: $rideType, status: $status, isDriverRole: $isDriverRole}';
  }
}

// Updated Supporting classes
class DropoffLocation {
  final double lat;
  final double lng;
  final String address;
  final int stopOrder;
  final String id;

  DropoffLocation({
    required this.lat,
    required this.lng,
    required this.address,
    required this.stopOrder,
    required this.id,
  });
}

class DriverInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String profileImage;
  final double? avgRating;
  final int? totalRatings;
  final String? badge;
  final String? vehicleInfo;

  DriverInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profileImage,
    this.avgRating,
    this.totalRatings,
    this.badge,
    this.vehicleInfo,
  });
}

class PickupLocation {
  final double lat;
  final double lng;
  final String city;
  final String address;

  PickupLocation({
    required this.lat,
    required this.lng,
    required this.city,
    required this.address,
  });
}