import 'package:get/get.dart';
import '../models/notification_model.dart';

class NotificationController extends GetxController {
  var notifications = <NotificationModel>[].obs;
  var notificationsEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  void loadNotificationsForRole(String role) {
    if (role == 'Driver') {
      _loadDriverNotifications();
    } else {
      _loadPassengerNotifications();
    }
  }

  void _loadDriverNotifications() {
    notifications.value = [
      // Today notifications
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
      // Yesterday notifications
      NotificationModel(
        id: '4',
        title: 'System Announcement: Policy Update',
        time: '9:15 AM',
        iconPath: 'assets/drawer/account.svg',
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
        iconPath: 'assets/drawer/account.svg',
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