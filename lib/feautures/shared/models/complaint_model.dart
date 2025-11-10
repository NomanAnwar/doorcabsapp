class ComplaintModel {
  final String status;
  final String issue;
  final String? id;

  ComplaintModel({
    required this.status,
    required this.issue,
    this.id,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      status: json['status'] ?? '',
      issue: json['issue'] ?? '',
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'issue': issue,
      'id': id,
    };
  }
}

class DriverModel {
  final String name;
  final double rating;
  final int totalRides;
  final String role;
  final String? imageUrl;

  DriverModel({
    required this.name,
    required this.rating,
    required this.totalRides,
    required this.role,
    this.imageUrl,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      name: json['name'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      role: json['role'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
}