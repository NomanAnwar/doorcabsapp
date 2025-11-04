// services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

class PermissionService extends GetxService {
  // Updated permissions list with proper grouping
  final List<Permission> requiredPermissions = [
    Permission.location,
    Permission.notification,
    // Permission.camera,
    // Permission.storage,
    Permission.phone,
  ];

  final Map<Permission, String> permissionDescriptions = {
    Permission.location: 'Location access is required to show nearby rides and drivers',
    Permission.notification: 'Notifications keep you updated about ride requests and status',
    Permission.camera: 'Camera is needed for profile pictures and document verification',
    Permission.storage: 'Storage access is required to save and upload documents',
    Permission.phone: 'Phone permission allows you to call drivers/passengers directly',
  };

  final RxMap<Permission, PermissionStatus> permissionStatus = <Permission, PermissionStatus>{}.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializePermissionStatus();
  }

  Future<void> _initializePermissionStatus() async {
    for (var permission in requiredPermissions) {
      permissionStatus[permission] = await permission.status;
    }
    permissionStatus.refresh();
  }

  Future<bool> checkAllPermissions() async {
    bool allGranted = true;

    for (var permission in requiredPermissions) {
      final status = await permission.status;
      permissionStatus[permission] = status;

      if (!status.isGranted) {
        allGranted = false;
      }
    }

    permissionStatus.refresh();
    return allGranted;
  }

  Future<bool> requestAllPermissions() async {
    bool allGranted = true;

    for (var permission in requiredPermissions) {
      final status = await _requestPermissionWithRetry(permission);
      permissionStatus[permission] = status;

      if (!status.isGranted) {
        allGranted = false;
      }
    }

    permissionStatus.refresh();
    return allGranted;
  }

  Future<PermissionStatus> _requestPermissionWithRetry(Permission permission) async {
    try {
      // First attempt
      var status = await permission.request();

      // If denied and it's storage/camera on Android, might need special handling
      if (status.isDenied && _isStorageOrCamera(permission)) {
        // Wait a bit and try again (sometimes needed for storage/camera)
        await Future.delayed(const Duration(milliseconds: 500));
        status = await permission.request();
      }

      return status;
    } catch (e) {
      print('❌ Error requesting $permission: $e');
      return PermissionStatus.denied;
    }
  }

  bool _isStorageOrCamera(Permission permission) {
    return permission == Permission.storage || permission == Permission.camera;
  }

  Future<bool> requestSinglePermission(Permission permission) async {
    try {
      final status = await _requestPermissionWithRetry(permission);
      permissionStatus[permission] = status;
      permissionStatus.refresh();

      return status.isGranted;
    } catch (e) {
      print('❌ Error requesting single permission $permission: $e');
      return false;
    }
  }

  String getPermissionDescription(Permission permission) {
    return permissionDescriptions[permission] ?? 'This permission is required for app functionality';
  }

  Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}