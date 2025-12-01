class NotificationModel {
  final String id;
  final String title;
  final String time;
  final String iconPath;
  final NotificationType type;
  final bool isRead;
  final String message;

  NotificationModel({
    required this.id,
    required this.title,
    required this.time,
    required this.iconPath,
    required this.type,
    this.isRead = false,
    this.message = '',
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? time,
    String? iconPath,
    NotificationType? type,
    bool? isRead,
    String? message,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      iconPath: iconPath ?? this.iconPath,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      message: message ?? this.message,
    );
  }
}

enum NotificationType {
  rideRequest,
  paymentReceived,
  rideCompleted,
  newFeature,
  accountUpdate,
  promotions,
  rides,
}