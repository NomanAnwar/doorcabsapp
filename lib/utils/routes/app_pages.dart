import 'package:get/get.dart';

import '../../feautures/profile/driver/screens/profile_completion_screen.dart';
import '../../feautures/profile/driver/screens/select_driver_type_screen.dart';
import '../../feautures/profile/driver/screens/select_vehicle_type_screen.dart';
import '../../feautures/profile/driver/screens/upload_cnic_screen.dart';
import '../../feautures/profile/driver/screens/upload_license_screen.dart';
import '../../feautures/profile/driver/screens/upload_registration_screen.dart';
import '../../feautures/profile/driver/screens/upload_selfie_screen.dart';
import '../../feautures/profile/driver/screens/upload_vehicle_info_screen.dart';
import '../../feautures/profile/passenger/screens/profile_screen.dart';
import '../../feautures/rides/passenger/screens/available_bids_screen.dart';
import '../../feautures/rides/passenger/screens/available_drivers_screen.dart';
import '../../feautures/rides/passenger/screens/chat_screen.dart';
import '../../feautures/rides/passenger/screens/drivers_waiting_screen.dart';
import '../../feautures/rides/passenger/screens/dropoff_screen.dart';
import '../../feautures/rides/passenger/screens/map_selection_screen.dart';
import '../../feautures/rides/passenger/screens/rate_driver_screen.dart';
import '../../feautures/rides/passenger/screens/ride_detail_screen.dart';
import '../../feautures/rides/passenger/screens/ride_history_screen.dart';
import '../../feautures/rides/passenger/screens/ride_home_screen.dart';
import '../../feautures/rides/passenger/screens/ride_in_progress_screen.dart';
import '../../feautures/rides/passenger/screens/ride_request_screen.dart';
import '../../feautures/start/views/getting_started_screen.dart';
import '../../feautures/start/views/otp_screen.dart';
import '../../splash/views/home_screen.dart';
import '../../splash/views/splash_screen.dart';
import '../../splash/views/welcome_screen.dart';

class AppPages {
  static final pages = [
    // Common Routes

    GetPage(name: '/', page: () =>  SplashScreen()),
    GetPage(name: '/welcome', page: () => WelcomeScreen()),
    GetPage(name: '/getting-started', page: () => const GettingStartedScreen()),
    GetPage(name: '/otp', page: () => const OtpScreen()),
    GetPage(name: '/home', page: () => const HomeScreen()),
    GetPage(name: '/profile', page: () => ProfileScreen()),


    // Passenger Side Routes
    GetPage(name: '/ride-home', page: () =>  RideHomeScreen()),
    GetPage(name: '/dropoff', page: () =>  DropOffScreen()),
    GetPage(name: '/map-selection', page: () => MapSelectionScreen()),
    GetPage(name: '/ride-request', page: () => RideRequestScreen()),
    GetPage(name: '/available-drivers', page: () => AvailableDriversScreen()),
    GetPage(name: '/available-bids', page: () => AvailableBidsScreen()),
    GetPage(name: "/drivers-waiting", page: () => DriversWaitingScreen(),),
    GetPage(name: "/chat-with_driver", page: () => ChatScreen(),),
    GetPage(name: "/ride-in-progress", page: () => RideInProgressScreen()),
    GetPage(name: "/rate-driver", page: () => RateDriverScreen()),
    GetPage(name: "/ride-history", page: () => RideHistoryScreen()),
    GetPage(name: "/ride-detail", page: () => RideDetailScreen()),


    // Driver Side Routes

    GetPage(name: "/select_driver_type", page: () => SelectDriverTypeScreen()),
    GetPage(name: "/select_vehicle_type", page: () => SelectVehicleTypeScreen()),
    GetPage(name: "/profile-completion", page: () => ProfileCompletionScreen()),
    GetPage(name: '/upload-cnic', page: () => UploadCnicScreen()),
    GetPage(name: '/upload-selfie', page: () => UploadSelfieScreen()),
    GetPage(name: '/upload-vehicle-info', page: () => UploadVehicleInfoScreen()),
    GetPage(name: '/upload-registration', page: () => UploadRegistrationScreen()),
    GetPage(name: '/upload-license', page: () => UploadLicenseScreen()),

    // GetPage(name: "/basic-info", page: () => const BasicInfoScreen()),
    // GetPage(name: "/cnic", page: () => const CnicScreen()),
    // GetPage(name: "/selfie", page: () => const SelfieScreen()),
    // GetPage(name: "/driver-licence", page: () => const DriverLicenceScreen()),
    // GetPage(name: "/vehicle-info", page: () => const VehicleInfoScreen()),
    // GetPage(name: "/referral", page: () => const ReferralScreen()),
  ];
}
