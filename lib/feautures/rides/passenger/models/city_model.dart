class CityModel {
  final String id;
  final String cityName;
  final double baseFare;
  final double perKmCharge;
  final double surgeValue;
  final bool isSurged;
  final String surgeStartDateTime;
  final String surgeEndDateTime;
  final String status;
  final double commission;
  final double waitingCharges;
  final int isWaitingChargesApplied;

  CityModel({
    required this.id,
    required this.cityName,
    required this.baseFare,
    required this.perKmCharge,
    required this.surgeValue,
    required this.isSurged,
    required this.surgeStartDateTime,
    required this.surgeEndDateTime,
    required this.status,
    required this.commission,
    required this.waitingCharges,
    required this.isWaitingChargesApplied,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json["_id"] ?? "",
      cityName: json["city_name"] ?? "",
      baseFare: (json["base_fare"] ?? 0).toDouble(),
      perKmCharge: (json["per_km_charge"] ?? 0).toDouble(),
      surgeValue: (json["surge_value"] ?? 0).toDouble(),
      isSurged: json["is_surged"] ?? false,
      surgeStartDateTime: json["surge_start_date_time"] ?? "",
      surgeEndDateTime: json["surge_end_date_time"] ?? "",
      status: json["status"] ?? "",
      commission: (json["commission"] ?? 0).toDouble(),
      waitingCharges: (json["waiting_charges"] ?? 0).toDouble(),
      isWaitingChargesApplied: json["is_waitingCharges_applied"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "city_name": cityName,
      "base_fare": baseFare,
      "per_km_charge": perKmCharge,
      "surge_value": surgeValue,
      "is_surged": isSurged,
      "surge_start_date_time": surgeStartDateTime,
      "surge_end_date_time": surgeEndDateTime,
      "status": status,
      "commission": commission,
      "waiting_charges": waitingCharges,
      "is_waitingCharges_applied": isWaitingChargesApplied,
    };
  }
}
