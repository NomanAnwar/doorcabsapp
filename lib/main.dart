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

final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
final PusherBeamsService _pusherBeams = PusherBeamsService();
final DriverLocationService _driverLocationService = DriverLocationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize core services
  // await _initializeCoreServices();
  runApp(const MyApp());
}

Future<void> _initializeCoreServices() async {
  try {
    await Firebase.initializeApp();
    FHttpHelper.setBaseUrl("https://dc.tricasol.pk");
    await _pusherManager.initializeOnce();
    await _pusherBeams.initialize();
    await _pusherBeams.registerDevice();

    // Configure location service if driver
    if (StorageService.getRole() == "Driver" || StorageService.getRole() == "driver") {
      await _driverLocationService.configure();
      await _driverLocationService.start();
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
      home: const SplashScreen(),
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