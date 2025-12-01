import 'package:get/get.dart';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:doorcab/utils/http/http_client.dart';
import '../models/notification_model.dart';

class NotificationController extends GetxController {
  var notifications = <NotificationModel>[].obs;
  var notificationsEnabled = false.obs;
  var isLoading = true.obs; // Add loading state

  @override
  void onInit() {
    super.onInit();

    _fetchNotificationsFromAPI();
  }

  Future<void> _fetchNotificationsFromAPI() async {
    try {
      isLoading.value = true; // Start loading

      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      final response = await FHttpHelper.get('notifi/all');

      if (response['success'] == true && response['data'] is List) {
        final notificationsData = response['data'] as List;

        // Convert API response to NotificationModel list
        final fetchedNotifications = <NotificationModel>[];

        for (var notificationData in notificationsData) {
          final notification = _mapApiToNotificationModel(notificationData);
          fetchedNotifications.add(notification);
        }

        notifications.assignAll(fetchedNotifications);
      } else {
        // Fallback to static data if API fails
        _loadFallbackNotifications();
      }

    } catch (e) {
      print('Error fetching notifications: $e');
      // Fallback to static data on error
      _loadFallbackNotifications();
    } finally {
      isLoading.value = false; // Stop loading
    }
  }

  // ... rest of your existing methods remain the same
  NotificationModel _mapApiToNotificationModel(Map<String, dynamic> apiData) {
    final String id = apiData['_id']?.toString() ?? '';
    final String title = apiData['title']?.toString() ?? 'Notification';
    final String message = apiData['message']?.toString() ?? '';
    final String notificationType = apiData['notification_type']?.toString() ?? 'general';
    final String createdAt = apiData['createdAt']?.toString() ?? '';

    // Map API notification_type to our NotificationType enum
    final NotificationType type = _mapApiTypeToNotificationType(notificationType);

    // Format time from createdAt
    final String displayTime = _formatNotificationTime(createdAt);

    return NotificationModel(
      id: id,
      title: title,
      time: displayTime,
      iconPath: _getIconPathForType(type),
      type: type,
      isRead: false,
      message: message,
    );
  }

  NotificationType _mapApiTypeToNotificationType(String apiType) {
    switch (apiType.toLowerCase()) {
      case 'ride':
      case 'ride_request':
        return NotificationType.rideRequest;
      case 'payment':
      case 'promotion':
        return NotificationType.paymentReceived;
      case 'ride_completed':
      case 'achievement':
        return NotificationType.rideCompleted;
      case 'general':
      case 'announcement':
        return NotificationType.accountUpdate;
      case 'feature':
      case 'update':
        return NotificationType.newFeature;
      default:
        return NotificationType.accountUpdate;
    }
  }

  String _formatNotificationTime(String createdAt) {
    try {
      if (createdAt.isEmpty) return 'Recently';

      final createdDate = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(createdDate);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else {
        // Format as date
        return '${createdDate.day}/${createdDate.month}/${createdDate.year}';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  String _getIconPathForType(NotificationType type) {
    final userRole = StorageService.getRole();

    if (userRole == 'Driver') {
      switch (type) {
        case NotificationType.rideRequest:
          return 'assets/drawer/car.svg';
        case NotificationType.paymentReceived:
          return 'assets/drawer/earn.svg';
        case NotificationType.rideCompleted:
          return 'assets/drawer/star.svg';
        case NotificationType.newFeature:
          return 'assets/drawer/gift.svg';
        case NotificationType.accountUpdate:
          return 'assets/images/notification.svg';
        case NotificationType.promotions:
          return 'assets/drawer/gift.svg';
        case NotificationType.rides:
          return 'assets/drawer/car.svg';
      }
    } else {
      // Passenger icons
      switch (type) {
        case NotificationType.rideRequest:
          return 'assets/drawer/car.svg';
        case NotificationType.paymentReceived:
          return 'assets/drawer/payment.svg';
        case NotificationType.rideCompleted:
          return 'assets/drawer/complete.svg';
        case NotificationType.newFeature:
          return 'assets/drawer/gift.svg';
        case NotificationType.accountUpdate:
          return 'assets/images/notification.svg';
        case NotificationType.promotions:
          return 'assets/drawer/gift.svg';
        case NotificationType.rides:
          return 'assets/drawer/car.svg';

      }
    }
  }

  void _loadFallbackNotifications() {
    final userRole = StorageService.getRole();
    if (userRole == 'Driver') {
      _loadDriverNotifications();
    } else {
      _loadPassengerNotifications();
    }
  }

  void _loadDriverNotifications() {
    notifications.value = [
      NotificationModel(
        id: '1',
        title: 'New Ride Request',
        time: '10:30 AM',
        iconPath: 'assets/drawer/car.svg',
        type: NotificationType.rideRequest,
      ),
      NotificationModel(
        id: '2',
        title: 'Earnings Update: PKR 1225',
        time: '11:45 AM',
        iconPath: 'assets/drawer/payment.svg',
        type: NotificationType.paymentReceived,
      ),
      NotificationModel(
        id: '3',
        title: 'Passenger Feedback: 4.8 Stars',
        time: '1:20 PM',
        iconPath: 'assets/drawer/complete.svg',
        type: NotificationType.rideCompleted,
      ),
      NotificationModel(
        id: '4',
        title: 'System Announcement: Policy Update',
        time: '9:15 AM',
        iconPath: 'assets/images/notification.svg',
        type: NotificationType.accountUpdate,
      ),
      NotificationModel(
        id: '5',
        title: 'Bonus Alert: Complete 5 Rides for PKR150',
        time: '3:00 PM',
        iconPath: 'assets/drawer/gift.svg',
        type: NotificationType.newFeature,
      ),
    ];
  }

  void _loadPassengerNotifications() {
    notifications.value = [
      NotificationModel(
        id: '1',
        title: 'Ride Request',
        time: '10:30 AM',
        iconPath: 'assets/drawer/car.svg',
        type: NotificationType.rideRequest,
      ),
      NotificationModel(
        id: '2',
        title: 'Payment Received',
        time: 'Yesterday',
        iconPath: 'assets/drawer/payment.svg',
        type: NotificationType.paymentReceived,
      ),
      NotificationModel(
        id: '3',
        title: 'Ride Completed',
        time: '2 days ago',
        iconPath: 'assets/drawer/complete.svg',
        type: NotificationType.rideCompleted,
      ),
      NotificationModel(
        id: '4',
        title: 'New Feature Available',
        time: '3 days ago',
        iconPath: 'assets/drawer/gift.svg',
        type: NotificationType.newFeature,
      ),
      NotificationModel(
        id: '5',
        title: 'Account Update',
        time: '4 days ago',
        iconPath: 'assets/images/notification.svg',
        type: NotificationType.accountUpdate,
      ),
    ];
  }

  void toggleNotifications(bool value) {
    notificationsEnabled.value = value;
    // Add your logic to enable/disable notifications
    if (value) {
      print('Notifications enabled');
    } else {
      print('Notifications disabled');
    }
  }

  void markAsRead(String id) {
    final index = notifications.indexWhere((notif) => notif.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
    }
  }

  void deleteNotification(String id) {
    notifications.removeWhere((notif) => notif.id == id);
  }

  void clearAllNotifications() {
    notifications.clear();
  }
}