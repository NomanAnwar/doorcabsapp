import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:doorcab/splash/views/splash_screen.dart';
import 'package:doorcab/utils/http/http_client.dart';
import 'package:doorcab/utils/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'feautures/shared/services/driver_location_service.dart';
import 'feautures/shared/services/pusher_beams.dart';
import 'feautures/shared/services/enhanced_pusher_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start showing your custom splash immediately
  runApp(const MyApp());

  // Initialize services in background without blocking UI
  _initializeServicesInBackground();
}

// Non-blocking service initialization
void _initializeServicesInBackground() async {
  try {
    await Firebase.initializeApp();
    FHttpHelper.setBaseUrl("http://dc.tricasol.pk");

    final EnhancedPusherManager pusherManager = EnhancedPusherManager();
    final PusherBeamsService pusherBeams = PusherBeamsService();
    final DriverLocationService driverLocationService = DriverLocationService();

    // Initialize services without awaiting (they'll run in background)
    pusherManager.initializeOnce();
    pusherBeams.initialize();
    pusherBeams.registerDevice();

    // Configure location service if driver
    if (StorageService.getRole() == "Driver" || StorageService.getRole() == "driver") {
      driverLocationService.configure();
      driverLocationService.start();
    }
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
      home: const SplashScreen(), // Your custom splash with all existing logic
    );
  }
}

// import 'package:doorcab/feautures/shared/services/storage_service.dart';
// import 'package:doorcab/splash/views/splash_screen.dart';
// import 'package:doorcab/utils/http/http_client.dart';
// import 'package:doorcab/utils/local_storage/storage_utility.dart';
// import 'package:doorcab/utils/routes/app_pages.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'feautures/shared/services/driver_location_service.dart';
// import 'feautures/shared/services/pusher_beams.dart';
// import 'feautures/shared/services/pusher_channels.dart';
//
// final PusherChannelsService globalPusherChannels = PusherChannelsService();
// final PusherBeamsService globalPusherBeams = PusherBeamsService();
// final DriverLocationService globalDriverLocationService = DriverLocationService();
//
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Initialize local storage before anything else
//   // await FLocalStorage.init();
//
//   // Firebase initialization
//   await Firebase.initializeApp();
//
//   FHttpHelper.setBaseUrl("http://dc.tricasol.pk");
//
//   // Initialize Pusher only ONCE globally
//   await globalPusherChannels.initialize();
//
//   // Initialize Beams only ONCE globally
//   await globalPusherBeams.initialize();
//   await globalPusherBeams.registerDevice();
//
//   // ✅ Configure location service globally (but don't start yet)
//   if (StorageService.getRole() == "Driver" || StorageService.getRole() == "driver") {
//     await globalDriverLocationService.configure();
//     // Don't start here - let the controller manage start/stop based on online status
//   }
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'DoorCabs',
//       initialRoute: '/',
//       getPages: AppPages.pages,
//       home: const SplashScreen(),
//     );
//   }
// }