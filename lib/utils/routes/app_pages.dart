import 'package:get/get.dart';

import '../../feautures/profile/passenger/screens/profile_screen.dart';
import '../../feautures/rides/screens/dropoff_screen.dart';
import '../../feautures/rides/screens/map_selection_screen.dart';
import '../../feautures/rides/screens/ride_home_screen.dart';
import '../../feautures/start/views/getting_started_screen.dart';
import '../../feautures/start/views/otp_screen.dart';
import '../../splash/views/home_screen.dart';
import '../../splash/views/splash_screen.dart';
import '../../splash/views/welcome_screen.dart';

class AppPages {
  static final pages = [
    GetPage(name: '/', page: () =>  SplashScreen()),
    GetPage(name: '/welcome', page: () => WelcomeScreen()),
    GetPage(name: '/getting-started', page: () => const GettingStartedScreen()),
    GetPage(name: '/otp', page: () => const OtpScreen()),
    GetPage(name: '/home', page: () => const HomeScreen()),
    GetPage(name: '/profile', page: () => ProfileScreen()),
    GetPage(name: '/ride-home', page: () =>  RideHomeScreen()),
    GetPage(name: '/dropoff', page: () =>  DropOffScreen()),
    GetPage(name: '/map-selection', page: () => MapSelectionScreen()),
  ];
}
