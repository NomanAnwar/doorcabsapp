// widgets/permission_gate.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../splash/views/splash_screen.dart';
import '../services/permission_service.dart';

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  final PermissionService _permissionService = Get.find<PermissionService>();
  final RxBool _isChecking = false.obs;
  final RxBool _allPermissionsGranted = false.obs;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    _isChecking.value = true;

    final allGranted = await _permissionService.checkAllPermissions();
    _allPermissionsGranted.value = allGranted;

    _isChecking.value = false;

    if (allGranted) {
      _navigateToSplash();
    }
  }

  Future<void> _requestPermissions() async {
    _isChecking.value = true;

    final allGranted = await _permissionService.requestAllPermissions();
    _allPermissionsGranted.value = allGranted;

    _isChecking.value = false;

    if (allGranted) {
      _navigateToSplash();
    }
  }

  void _navigateToSplash() {
    Get.offAll(() => const SplashScreen());
  }

  Widget _buildPermissionItem(Permission permission, PermissionStatus status) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(
          status.isGranted ? Icons.check_circle : Icons.error,
          color: status.isGranted ? Colors.green : Colors.orange,
        ),
        title: Text(
          _getPermissionTitle(permission),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: status.isGranted ? Colors.green : Colors.black,
          ),
        ),
        subtitle: Text(_permissionService.getPermissionDescription(permission)),
        trailing: status.isGranted
            ? const Icon(Icons.check, color: Colors.green)
            : ElevatedButton(
          onPressed: () => _requestSinglePermission(permission),
          child: const Text('Grant'),
        ),
      ),
    );
  }

  Future<void> _requestSinglePermission(Permission permission) async {
    final granted = await _permissionService.requestSinglePermission(permission);
    if (granted) {
      // Check if all permissions are now granted
      final allGranted = await _permissionService.checkAllPermissions();
      if (allGranted) {
        _navigateToSplash();
      }
    }
  }

  String _getPermissionTitle(Permission permission) {
    switch (permission) {
      case Permission.location:
        return 'Location Access';
      case Permission.notification:
        return 'Notifications';
      case Permission.camera:
        return 'Camera';
      case Permission.storage:
        return 'Storage';
      case Permission.phone:
        return 'Phone';
      default:
        return 'Unknown Permission';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Permissions Required'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (_isChecking.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking permissions...'),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.blue[50],
              child: Column(
                children: [
                  Icon(
                    Icons.security,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Permissions Required',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The following permissions are required for the app to function properly:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Permissions List
            Expanded(
              child: ListView(
                children: _permissionService.requiredPermissions.map((permission) {
                  final status = _permissionService.permissionStatus[permission] ?? PermissionStatus.denied;
                  return _buildPermissionItem(permission, status);
                }).toList(),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!_allPermissionsGranted.value)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _requestPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Grant All Permissions',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _permissionService.openAppSettings,
                    child: const Text('Open App Settings'),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}