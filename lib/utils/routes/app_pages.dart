import 'package:get/get.dart';

import '../../feautures/start/views/getting_started_screen.dart';
import '../../feautures/start/views/otp_screen.dart';
import '../../splash/views/home_screen.dart';
import '../../splash/views/splash_screen.dart';
import '../../splash/views/welcome_screen.dart';

class AppPages {
  static final pages = [
    GetPage(name: '/', page: () =>  SplashScreen()),
    GetPage(name: '/welcome', page: () => const WelcomeScreen()),
    GetPage(name: '/getting-started', page: () => const GettingStartedScreen()),
    GetPage(name: '/otp', page: () => const OtpScreen()),
    GetPage(name: '/home', page: () => const HomeScreen()),
  ];
}
