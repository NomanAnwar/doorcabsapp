class CityModel {
  final String id;
  final String cityName;
  // final double baseFare; //  NOT IN API RESPONSE - using 'fare' instead
  final double fare; //  FROM API RESPONSE
  final double perKmCharge; // NOT IN API RESPONSE - will be 0
  final double surgeValue;
  final bool isSurged;
  final String surgeStartDateTime;
  final String surgeEndDateTime;
  final String status;
  final double commission;
  final double waitingCharges;
  final int isWaitingChargesApplied;
  final int waitingTimeLimit;
  final int perKmReq;

  // ✅ EXISTING FIELDS FROM API RESPONSE
  final double companyCommission;
  final double driverCommission;
  final String createdAt;
  final String updatedAt;
  final int version; // for __v field

  // ✅ NEW FIELDS FROM API THAT WERE MISSING
  final double baseRadiusKm;
  final List<dynamic> radiusLevels;
  final double queueRadiusKm;
  final String country;
  final String state;

  CityModel({
    required this.id,
    required this.cityName,
    // required this.baseFare, // NOT IN API RESPONSE
    required this.fare, //  FROM API RESPONSE
    required this.perKmCharge, //  NOT IN API RESPONSE - will be 0
    required this.surgeValue,
    required this.isSurged,
    required this.surgeStartDateTime,
    required this.surgeEndDateTime,
    required this.status,
    required this.commission,
    required this.waitingCharges,
    required this.isWaitingChargesApplied,
    required this.waitingTimeLimit,
    required this.perKmReq,
    // ✅ EXISTING FIELDS FROM API RESPONSE
    required this.companyCommission,
    required this.driverCommission,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    // ✅ NEW FIELDS FROM API
    required this.baseRadiusKm,
    required this.radiusLevels,
    required this.queueRadiusKm,
    required this.country,
    required this.state,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json["_id"]?.toString() ?? "",
      cityName: json["city_name"]?.toString() ?? "",
      // baseFare: (json["base_fare"] ?? 0).toDouble(), // NOT IN API RESPONSE
      fare: (json["fare"] ?? 0).toDouble(), // ✅ FROM API RESPONSE
      perKmCharge: (json["per_km_charge"] ?? 0).toDouble(), //  NOT IN API RESPONSE - will be 0
      surgeValue: (json["surge_value"] ?? 0).toDouble(),
      isSurged: json["is_surged"] ?? false,
      surgeStartDateTime: json["surge_start_date_time"]?.toString() ?? "",
      surgeEndDateTime: json["surge_end_date_time"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
      commission: (json["commission"] ?? 0).toDouble(),
      waitingCharges: (json["waiting_charges"] ?? 0).toDouble(),
      isWaitingChargesApplied: (json["is_waitingCharges_applied"] ?? 0).toInt(),
      waitingTimeLimit: (json["waiting_time_limit"] ?? 0).toInt(),
      perKmReq: (json["per_km_req"] ?? 0).toInt(),
      // ✅ EXISTING FIELDS FROM API RESPONSE
      companyCommission: (json["company_commission"] ?? 0).toDouble(),
      driverCommission: (json["driver_commission"] ?? 0).toDouble(),
      createdAt: json["createdAt"]?.toString() ?? "",
      updatedAt: json["updatedAt"]?.toString() ?? "",
      version: (json["__v"] ?? 0).toInt(),
      // ✅ NEW FIELDS FROM API
      baseRadiusKm: (json["base_radius_km"] ?? 0).toDouble(),
      radiusLevels: json["radius_levels"] is List ? json["radius_levels"] : [],
      queueRadiusKm: (json["queue_radius_km"] ?? 0).toDouble(),
      country: json["country"]?.toString() ?? "",
      state: json["state"]?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "city_name": cityName,
      // "base_fare": baseFare, // ❌ NOT IN API RESPONSE
      "fare": fare, // ✅ FROM API RESPONSE
      "per_km_charge": perKmCharge, // ❌ NOT IN API RESPONSE - will be 0
      "surge_value": surgeValue,
      "is_surged": isSurged,
      "surge_start_date_time": surgeStartDateTime,
      "surge_end_date_time": surgeEndDateTime,
      "status": status,
      "commission": commission,
      "waiting_charges": waitingCharges,
      "is_waitingCharges_applied": isWaitingChargesApplied,
      "waiting_time_limit": waitingTimeLimit,
      "per_km_req": perKmReq,
      // ✅ EXISTING FIELDS FROM API RESPONSE
      "company_commission": companyCommission,
      "driver_commission": driverCommission,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "__v": version,
      // ✅ NEW FIELDS FROM API
      "base_radius_km": baseRadiusKm,
      "radius_levels": radiusLevels,
      "queue_radius_km": queueRadiusKm,
      "country": country,
      "state": state,
    };
  }
}

