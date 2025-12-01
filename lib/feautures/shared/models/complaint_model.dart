class ComplaintModel {
  final String id;
  final String rideId;
  final String complainantName;
  final String complainantId;
  final String complaintByType;
  final String complaintForType;
  final String type;
  final String comment;
  final String status;
  final String complaintType;
  final String? attachmentUrl;
  final String complaintDate;
  final String createdAt;

  ComplaintModel({
    required this.id,
    required this.rideId,
    required this.complainantName,
    required this.complainantId,
    required this.complaintByType,
    required this.complaintForType,
    required this.type,
    required this.comment,
    required this.status,
    required this.complaintType,
    this.attachmentUrl,
    required this.complaintDate,
    required this.createdAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    final complaintById = json['complaintById'] ?? {};
    final nameData = complaintById['name'] ?? {};
    final firstName = nameData['firstName'] ?? '';
    final lastName = nameData['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    // Format date
    String formatDate(String dateString) {
      try {
        if (dateString.isNotEmpty) {
          final dateTime = DateTime.parse(dateString);
          return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
        }
      } catch (e) {
        print('Date parsing error: $e');
      }
      return 'Unknown date';
    }

    return ComplaintModel(
      id: json['_id'] ?? '',
      rideId: json['rideId'] ?? '',
      complainantName: fullName.isNotEmpty ? fullName : 'Unknown',
      complainantId: complaintById['_id'] ?? '',
      complaintByType: json['complaintByType'] ?? '',
      complaintForType: json['complaintForType'] ?? '',
      type: json['type'] ?? '',
      comment: json['comment'] ?? '',
      status: json['status'] ?? '',
      complaintType: json['complaint_type'] ?? '',
      attachmentUrl: json['attachment_url'],
      complaintDate: formatDate(json['complaintDate'] ?? ''),
      createdAt: formatDate(json['createdAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'complainantName': complainantName,
      'complainantId': complainantId,
      'complaintByType': complaintByType,
      'complaintForType': complaintForType,
      'type': type,
      'comment': comment,
      'status': status,
      'complaintType': complaintType,
      'attachmentUrl': attachmentUrl,
      'complaintDate': complaintDate,
      'createdAt': createdAt,
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