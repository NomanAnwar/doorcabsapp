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

  // ✅ NEW FIELDS FROM API RESPONSE
  final double companyCommission;
  final double driverCommission;
  final String createdAt;
  final String updatedAt;
  final int version; // for __v field

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
    // ✅ NEW FIELDS FROM API RESPONSE
    required this.companyCommission,
    required this.driverCommission,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json["_id"] ?? "",
      cityName: json["city_name"] ?? "",
      // baseFare: (json["base_fare"] ?? 0).toDouble(), // NOT IN API RESPONSE
      fare: (json["fare"] ?? 0).toDouble(), // ✅ FROM API RESPONSE
      perKmCharge: (json["per_km_charge"] ?? 0).toDouble(), //  NOT IN API RESPONSE - will be 0
      surgeValue: (json["surge_value"] ?? 0).toDouble(),
      isSurged: json["is_surged"] ?? false,
      surgeStartDateTime: json["surge_start_date_time"] ?? "",
      surgeEndDateTime: json["surge_end_date_time"] ?? "",
      status: json["status"] ?? "",
      commission: (json["commission"] ?? 0).toDouble(),
      waitingCharges: (json["waiting_charges"] ?? 0).toDouble(),
      isWaitingChargesApplied: (json["is_waitingCharges_applied"] ?? 0).toInt(),
      waitingTimeLimit: (json["waiting_time_limit"] ?? 0).toInt(),
      perKmReq: (json["per_km_req"] ?? 0).toInt(),
      // ✅ NEW FIELDS FROM API RESPONSE
      companyCommission: (json["company_commission"] ?? 0).toDouble(),
      driverCommission: (json["driver_commission"] ?? 0).toDouble(),
      createdAt: json["createdAt"] ?? "",
      updatedAt: json["updatedAt"] ?? "",
      version: (json["__v"] ?? 0).toInt(),
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
      // ✅ NEW FIELDS FROM API RESPONSE
      "company_commission": companyCommission,
      "driver_commission": driverCommission,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "__v": version,
    };
  }
}


// class CityModel {
//   final String id;
//   final String cityName;
//   final double baseFare;
//   final double perKmCharge;
//   final double surgeValue;
//   final bool isSurged;
//   final String surgeStartDateTime;
//   final String surgeEndDateTime;
//   final String status;
//   final double commission;
//   final double waitingCharges;
//   final int isWaitingChargesApplied;
//
//   CityModel({
//     required this.id,
//     required this.cityName,
//     required this.baseFare,
//     required this.perKmCharge,
//     required this.surgeValue,
//     required this.isSurged,
//     required this.surgeStartDateTime,
//     required this.surgeEndDateTime,
//     required this.status,
//     required this.commission,
//     required this.waitingCharges,
//     required this.isWaitingChargesApplied,
//   });
//
//   factory CityModel.fromJson(Map<String, dynamic> json) {
//     return CityModel(
//       id: json["_id"] ?? "",
//       cityName: json["city_name"] ?? "",
//       baseFare: (json["base_fare"] ?? 0).toDouble(),
//       perKmCharge: (json["per_km_charge"] ?? 0).toDouble(),
//       surgeValue: (json["surge_value"] ?? 0).toDouble(),
//       isSurged: json["is_surged"] ?? false,
//       surgeStartDateTime: json["surge_start_date_time"] ?? "",
//       surgeEndDateTime: json["surge_end_date_time"] ?? "",
//       status: json["status"] ?? "",
//       commission: (json["commission"] ?? 0).toDouble(),
//       waitingCharges: (json["waiting_charges"] ?? 0).toDouble(),
//       isWaitingChargesApplied: json["is_waitingCharges_applied"] ?? 0,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       "_id": id,
//       "city_name": cityName,
//       "base_fare": baseFare,
//       "per_km_charge": perKmCharge,
//       "surge_value": surgeValue,
//       "is_surged": isSurged,
//       "surge_start_date_time": surgeStartDateTime,
//       "surge_end_date_time": surgeEndDateTime,
//       "status": status,
//       "commission": commission,
//       "waiting_charges": waitingCharges,
//       "is_waitingCharges_applied": isWaitingChargesApplied,
//     };
//   }
// }
