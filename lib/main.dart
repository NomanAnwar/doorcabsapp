import 'package:doorcab/splash/views/splash_screen.dart';
import 'package:doorcab/utils/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'feautures/shared/handlers/lifecycle_handler.dart';
import 'feautures/shared/services/driver_location_service.dart';
import 'feautures/shared/services/pusher_background_service.dart';
import 'feautures/shared/services/pusher_beams.dart';
import 'feautures/shared/services/enhanced_pusher_manager.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
final PusherBeamsService _pusherBeams = PusherBeamsService();
final DriverLocationService _driverLocationService = DriverLocationService();
final PusherBackgroundService _backgroundService = PusherBackgroundService();

final List<Permission> requiredPermissions = [
  Permission.location,
  Permission.notification,
  Permission.phone,
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);


  await _initializeCoreServices();

  final allPermissionsGranted = await _checkAndRequestPermissions();

  if (allPermissionsGranted) {
    runApp(const MyApp());
  } else {
    runApp(const PermissionDeniedApp());
  }
}

Future<bool> _checkAndRequestPermissions() async {
  bool allGranted = await _checkPermissions();

  if (!allGranted) {
    // Request permissions if not granted
    allGranted = await _requestPermissions();

    if (!allGranted) {
      // Show final dialog and guide to settings
      await _showFinalPermissionDialog();
      return false;
    }
  }

  return true;
}

Future<bool> _checkPermissions() async {
  for (var permission in requiredPermissions) {
    final status = await permission.status;
    if (!status.isGranted) {
      return false;
    }
  }
  return true;
}

Future<bool> _requestPermissions() async {
  // Request all permissions at once
  final Map<Permission, PermissionStatus> statuses = await requiredPermissions.request();

  // Check if all are granted
  for (var permission in requiredPermissions) {
    if (!statuses[permission]!.isGranted) {
      return false;
    }
  }
  return true;
}

Future<void> _showFinalPermissionDialog() async {
  // We need to ensure Flutter binding is initialized for showing dialog
  await WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'All permissions are required for the app to function properly. '
                'Please grant the required permissions from app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(), // Close app
              child: const Text('Exit App'),
            ),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
                SystemNavigator.pop(); // Close app after opening settings
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _initializeCoreServices() async {
  try {
    // Initialize background service first
    await _backgroundService.initialize();

    // Comment/uncomment services as needed
    // await Firebase.initializeApp();
    // FHttpHelper.setBaseUrl("https://dc.tricasol.pk");
    // await _pusherManager.initializeOnce();
    // await _pusherBeams.initialize();
    // await _pusherBeams.registerDevice();

    // Configure location service if driver
    // if (StorageService.getRole() == "Driver" || StorageService.getRole() == "driver") {
    //   await _driverLocationService.configure();
    //   await _driverLocationService.start();
    // }
  } catch (e) {
    print('⚠️ Service initialization error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DoorCabs',
      initialRoute: '/',
      getPages: AppPages.pages,
      navigatorKey: NavigationService.navigatorKey,
      builder: (context, child) {
        // Add lifecycle observer for background/foreground detection
        WidgetsBinding.instance.addObserver(LifecycleEventHandler());

        // Enable wakelock when app is in foreground
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   WakelockPlus.enable();
        // });

        return child!;
      },
      home: const SplashScreen(), // Directly go to splash if permissions granted
    );
  }
}

// App shown when permissions are denied
class PermissionDeniedApp extends StatelessWidget {
  const PermissionDeniedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'All permissions are required for the app to function properly. '
                  'The app will now close. Please reopen and grant the permissions.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  openAppSettings();
                  SystemNavigator.pop();
                },
                child: const Text('Open Settings & Exit'),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Exit App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
