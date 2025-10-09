class RideTypeScreenModel {
  final String id;
  final String categoryName;
  final String categoryIcon;
  final int fare;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;
  final List<Vehicle> vehicleList;

  RideTypeScreenModel({
    required this.id,
    required this.categoryName,
    required this.categoryIcon,
    required this.fare,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    required this.vehicleList,
  });

  factory RideTypeScreenModel.fromJson(Map<String, dynamic> json) {
    return RideTypeScreenModel(
      id: json["_id"] ?? "",
      categoryName: json["category_name"] ?? "",
      categoryIcon: json["category_icon"] ?? "",
      fare: json["fare"] is int ? json["fare"] : int.tryParse(json["fare"].toString()) ?? 0,
      status: json["status"] ?? "",
      createdAt: DateTime.tryParse(json["createdAt"] ?? "") ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? "") ?? DateTime.now(),
      v: json["__v"] ?? 0,
      vehicleList: (json["vehicle_list"] as List? ?? [])
          .map((e) => Vehicle.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "category_name": categoryName,
      "category_icon": categoryIcon,
      "fare": fare,
      "status": status,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "__v": v,
      "vehicle_list": vehicleList.map((v) => v.toJson()).toList(),
    };
  }

  @override
  String toString() => toJson().toString();
}

class Vehicle {
  final String id;
  final String vehicleName;
  final String baseFare;
  final String perKmCharge;
  final String icon;
  final String noOfPassengers;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  Vehicle({
    required this.id,
    required this.vehicleName,
    required this.baseFare,
    required this.perKmCharge,
    required this.icon,
    required this.noOfPassengers,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json["_id"] ?? "",
      vehicleName: json["vehicle_name"] ?? "",
      baseFare: json["base_fare"]?.toString() ?? "0",
      perKmCharge: json["per_km_charge"]?.toString() ?? "0",
      icon: json["icon"] ?? "",
      noOfPassengers: json["no_of_passengers"] ?? 0,
      status: json["status"] ?? "",
      createdAt: DateTime.tryParse(json["createdAt"] ?? "") ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? "") ?? DateTime.now(),
      v: json["__v"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "vehicle_name": vehicleName,
      "base_fare": baseFare,
      "per_km_charge": perKmCharge,
      "icon": icon,
      "no_of_passengers": noOfPassengers,
      "status": status,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "__v": v,
    };
  }

  @override
  String toString() => toJson().toString();
}
