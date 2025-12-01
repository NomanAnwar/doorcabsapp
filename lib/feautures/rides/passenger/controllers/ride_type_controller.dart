import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';
import '../../../shared/services/pusher_background_service.dart';
import '../../../shared/services/storage_service.dart';
import '../models/location_model.dart';
import '../models/ride_type_screen_model.dart';
import '../models/services/location_service.dart';

class RideTypeController extends BaseController {
  /// API service list (categories with vehicles)
  var services = <RideTypeScreenModel>[].obs;

  // Active rides observable - from API only
  final activeRides = <Map<String, dynamic>>[].obs;
  final isLoadingActiveRides = false.obs;

  /// User location
  final userLocation = Rx<UserLocation?>(null);
  final isLoadingLocation = false.obs;
  final locationError = ''.obs;

  /// Location service
  final RideTypeLocationService locationService = RideTypeLocationService();

  /// Track completion of all parallel API calls
  var areAllDataLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllData();
    _loadActiveRidesFromApi(); // Only load from API
  }

  // ✅ NEW: Fetch active rides from API
  Future<void> _loadActiveRidesFromApi() async {
    try {
      isLoadingActiveRides(true);
      print('🔄 Fetching active rides from API...');

      final response = await FHttpHelper.post(
          'passenger/active-rides',
          {}
      );

      print('📦 Active rides API response: $response');

      if (response['rideId'] != null) {
        final hasActiveRide = response['hasActiveRide'] == true;

        if (hasActiveRide) {
          // Store the complete response data
          final rideData = Map<String, dynamic>.from(response);

          // Clear and add to active rides list
          activeRides.assignAll([rideData]);

          // Setup listener for this ride
          final rideId = rideData['rideId']?.toString();
          if (rideId != null && rideId.isNotEmpty) {
            listenToActiveRideChannel(rideId);
          }

          print('✅ Active ride loaded from API: $rideId');
        } else {
          print('ℹ️ No active rides found in API');
          activeRides.clear();
        }
      } else {
        print('❌ Active rides API returned success: false');
        activeRides.clear();
      }
    } catch (e) {
      print('❌ Error fetching active rides from API: $e');
      activeRides.clear();
    } finally {
      isLoadingActiveRides(false);
    }
  }

  // ✅ IMPROVED: Listen to active ride channel
  void listenToActiveRideChannel(String rideId) {
    print('🔔 Setting up listener for active ride: $rideId');

    EnhancedPusherManager().subscribeOnce(
      "ride-$rideId",
      events: {
        "ride-ended": (data) {
          print('🏁 Active ride ended: $rideId');
          _handleActiveRideEnded(rideId, data);
        },
        "ride-cancelled": (data) {
          print('❌ Active ride cancelled: $rideId');
          _handleActiveRideEnded(rideId, data);
        },
        "driver-location": (data) {
          print('📍 Driver location update for ride $rideId: $data');
          _handleDriverLocationUpdate(rideId, data);
        },
        "new-message": (data) {
          print('💬 New message for ride $rideId: $data');
          _showMessageNotification(rideId, data);
        },
        "driver-arrived": (data) {
          print('🚗 Driver arrived for ride $rideId: $data');
          _handleDriverArrived(rideId, data);
        },
        "ride-started": (data) {
          print('🚦 Ride started for ride $rideId: $data');
          _handleRideStarted(rideId, data);
        },
      },
    );
  }

  // ✅ NEW: Handle driver location updates
  void _handleDriverLocationUpdate(String rideId, Map<String, dynamic> data) {
    print('📍 Driver location for $rideId: ${data['lat']}, ${data['lng']}');
  }

  // ✅ NEW: Handle driver arrived
  void _handleDriverArrived(String rideId, Map<String, dynamic> data) {
    FSnackbar.show(
      title: 'Driver Arrived',
      message: 'Your driver has arrived at pickup location',
    );
  }

  // ✅ NEW: Handle ride started
  void _handleRideStarted(String rideId, Map<String, dynamic> data) {
    FSnackbar.show(
      title: 'Ride Started',
      message: 'Your ride has started',
    );
  }

  // ✅ IMPROVED: Handle active ride ended
  void _handleActiveRideEnded(String rideId, Map<String, dynamic> data) {
    print('🗑️ Removing completed ride: $rideId');

    // Remove from local list
    activeRides.removeWhere((ride) => ride['rideId'] == rideId);

    // Stop background service for this ride
    final passengerId = StorageService.getSignUpResponse()?.userId;
    if (passengerId != null) {
      PusherBackgroundService().stopBackgroundMode();
    }

    // Show notification
    FSnackbar.show(
      title: 'Ride Completed',
      message: 'Your ride has been completed',
    );

    print('✅ Successfully removed ride: $rideId, remaining: ${activeRides.length}');

    // Refresh from API to ensure consistency
    _loadActiveRidesFromApi();
  }

  // ✅ NEW: Show message notification
  void _showMessageNotification(String rideId, Map<String, dynamic> messageData) {
    final senderName = messageData['senderName'] ?? 'Driver';
    final message = messageData['text'] ?? 'New message';

    FSnackbar.show(
      title: 'Message from $senderName',
      message: message,
    );
  }

  // // ✅ UPDATED: Navigate to active ride with API data
  // void navigateToActiveRide(Map<String, dynamic> rideData) {
  //   try {
  //     final rideId = rideData['rideId'];
  //     final bid = rideData['bid'];
  //     final rideType = rideData['rideType'];
  //
  //     if (rideId == null || bid == null || rideType == null) {
  //       FSnackbar.show(
  //         title: 'Error',
  //         message: 'Could not load ride data',
  //         isError: true,
  //       );
  //       return;
  //     }
  //
  //     print('🚀 Navigating to active ride: $rideId');
  //
  //     // Navigate to DriversWaitingScreen with the exact structure you need
  //     Get.offAllNamed("/drivers-waiting", arguments: {
  //       ...rideData, // This includes all the API response data
  //       'bid': bid,
  //       'rideType': rideType,
  //     });
  //
  //   } catch (e) {
  //     print('❌ Error navigating to active ride: $e');
  //     FSnackbar.show(
  //       title: 'Error',
  //       message: 'Failed to load ride',
  //       isError: true,
  //     );
  //   }
  // }

  // ✅ UPDATED: Navigate to active ride with API data
  void navigateToActiveRide(Map<String, dynamic> rideData) {
    try {
      final rideId = rideData['rideId'];
      final bid = rideData['bid'];
      final rideType = rideData['rideType'];
      final pickup = rideData['pickup'];
      final dropoffs = rideData['dropoffs'];
      final status = rideData['status'];

      if (rideId == null) {
        FSnackbar.show(
          title: 'Error',
          message: 'Could not load ride data',
          isError: true,
        );
        return;
      }

      print('🚀 Navigating to active ride: $rideId | Status: $status | Has Bid: ${bid != null}');

      if (bid == null) {
        // No driver assigned yet - navigate to available-drivers
        print('📋 No bid found, navigating to available-drivers');

        // Extract pickup coordinates
        final pickupCoords = pickup != null
            ? LatLng(pickup['lat'], pickup['lng'])
            : null;

        Get.offAllNamed("/available-drivers", arguments: {
          'rideId': rideId,
          'rideData': rideData,
          "status": status,
          'pickup': pickup ?? {
            "lat": userLocation.value?.latitude,
            "lng": userLocation.value?.longitude,
            "address": userLocation.value?.address ?? "Current Location",
          },
          'dropoffs': dropoffs ?? [],
          'rideType': rideType ?? "Unknown",
          // Add other required parameters with defaults
          'fare': 0,
          'passengers': 1,
          'payment': 'Cash',
          'pickupLat': pickupCoords?.latitude ?? userLocation.value?.latitude,
          'pickupLng': pickupCoords?.longitude ?? userLocation.value?.longitude,
        });
      } else {
        // Driver is assigned - navigate to drivers-waiting
        print('🚗 Bid found, navigating to drivers-waiting');

        Get.offAllNamed("/drivers-waiting", arguments: {
          ...rideData, // This includes all the API response data
          'bid': bid,
          'rideType': rideType,
        });
      }

    } catch (e) {
      print('❌ Error navigating to active ride: $e');
      FSnackbar.show(
        title: 'Error',
        message: 'Failed to load ride',
        isError: true,
      );
    }
  }

  // ✅ NEW: Check if user can request more rides
  bool get canRequestMoreRides {
    // Business logic - usually only 1 active ride allowed at a time
    return activeRides.isEmpty;
  }

  // ✅ NEW: Get current active rides count
  int get activeRidesCount {
    return activeRides.length;
  }

  // ✅ NEW: Refresh active rides manually
  Future<void> refreshActiveRides() async {
    await _loadActiveRidesFromApi();
  }

  // ✅ NEW: Get the first active ride
  Map<String, dynamic>? get firstActiveRide {
    return activeRides.isNotEmpty ? activeRides.first : null;
  }

  // ✅ NEW: Check if user has any active rides
  bool get hasActiveRides {
    return activeRides.isNotEmpty;
  }

  /// ✅ UPDATED: Load all data including active rides from API
  Future<void> loadAllData() async {
    print("User profile data : " + StorageService.getProfile().toString());
    try {
      isLoading.value = true;
      error.value = '';
      areAllDataLoaded(false);

      await executeWithRetry(() async {
        await Future.wait([
          fetchServices(),
          _getUserLocation(),
          _loadActiveRidesFromApi(), // Now included in parallel loading
        ], eagerError: true);

        areAllDataLoaded(true);

        // Pre-cache images after services are loaded
        precacheServiceImages();

        if (kDebugMode) {
          print('[RideTypeController] All data loaded successfully');
          print('[RideTypeController] Services: ${services.length}');
          print('[RideTypeController] User Location: ${userLocation.value?.address}');
          print('[RideTypeController] Active Rides: ${activeRides.length}');
        }
      });
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        print('[RideTypeController] Error loading all data: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  void precacheServiceImages() {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (var service in services) {
          final icon = service.categoryIcon ?? '';

          if (icon.isNotEmpty) {
            if (_looksLikeBase64(icon)) {
              continue;
            } else {
              try {
                precacheImage(NetworkImage(icon), Get.context!);
                if (kDebugMode) {
                  print('[RideTypeController] Pre-cached network image: $icon');
                }
              } catch (e) {
                if (kDebugMode) {
                  print('[RideTypeController] Failed to pre-cache network image: $e');
                }
              }
            }
          }

          final defaultAssetPath = _getDefaultAssetPath(service.categoryName);
          try {
            precacheImage(AssetImage(defaultAssetPath), Get.context!);
            if (kDebugMode) {
              print('[RideTypeController] Pre-cached asset image: $defaultAssetPath');
            }
          } catch (e) {
            if (kDebugMode) {
              print('[RideTypeController] Failed to pre-cache asset image: $e');
            }
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('[RideTypeController] Error in precacheServiceImages: $e');
      }
    }
  }

  bool _looksLikeBase64(String s) {
    if (s.isEmpty) return false;
    if (s.startsWith('data:image')) return true;
    final sanitized = s.replaceAll(RegExp(r'\s+'), '');
    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(sanitized);
  }

  String _getDefaultAssetPath(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('courier')) return "assets/images/courier.png";
    if (name.contains('freight')) return "assets/images/frieght.png";
    if (name.contains('city to city')) return "assets/images/city.png";
    if (name.contains('instant ride')) return "assets/images/instant.png";
    if (name.contains('delivery')) return "assets/images/delievrybike.png";
    if (name.contains('schedule ride')) return "assets/images/scity.png";
    return "assets/images/courier.png";
  }

  /// ✅ EXISTING: Your original methods
  Future<void> _getUserLocation() async {
    try {
      isLoadingLocation(true);
      locationError('');

      final location = await locationService.getCompleteUserLocation();
      userLocation.value = location;

      if (kDebugMode) {
        print('[RideTypeController] User location obtained: ${location.address}');
        print('[RideTypeController] Coordinates: ${location.latitude}, ${location.longitude}');
      }
    } catch (e) {
      locationError.value = 'Failed to get location: $e';
      print('[RideTypeController] Location error: $e');

      userLocation.value = UserLocation(
        latitude: 0.0,
        longitude: 0.0,
        address: 'Your Current Location',
      );
    } finally {
      isLoadingLocation(false);
    }
  }

  Future<void> fetchServices() async {
    try {
      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response = await FHttpHelper.get('vehicle/list');

      print("Vehicle list API Response in RideTypeController : $response");

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];

        services.assignAll(
          data.map((item) => RideTypeScreenModel.fromJson(item)).toList(),
        );

        if (kDebugMode) {
          print('[RideTypeController] Successfully loaded ${services.length} services');
          for (var s in services) {
            print('Service: ${s.categoryName}, Vehicles: ${s.vehicleList.length}');
          }
        }
      } else {
        throw Exception('Services API returned success: false');
      }
    } catch (e) {
      throw Exception('Failed to load services: $e');
    }
  }

  List<RideTypeScreenModel> getDefaultServices() {
    return [
      RideTypeScreenModel(
        id: '1',
        categoryName: "Courier",
        categoryIcon: "",
        fare: 0,
        status: "active",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        v: 0,
        vehicleList: [],
      ),
      RideTypeScreenModel(
        id: '2',
        categoryName: "Freight",
        categoryIcon: "",
        fare: 0,
        status: "active",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        v: 0,
        vehicleList: [],
      ),
      RideTypeScreenModel(
        id: '3',
        categoryName: "City to City",
        categoryIcon: "",
        fare: 0,
        status: "active",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        v: 0,
        vehicleList: [],
      ),
      RideTypeScreenModel(
        id: '4',
        categoryName: "Instant Ride",
        categoryIcon: "",
        fare: 0,
        status: "active",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        v: 0,
        vehicleList: [],
      ),
      RideTypeScreenModel(
        id: '5',
        categoryName: "Delivery",
        categoryIcon: "",
        fare: 0,
        status: "active",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        v: 0,
        vehicleList: [],
      ),
    ];
  }

  RideTypeScreenModel? getServiceByTitle(String title) {
    try {
      return services.firstWhere(
            (service) => service.categoryName.toLowerCase() == title.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  RideTypeScreenModel findServiceByApproximateTitle(String searchTitle) {
    final lowerSearch = searchTitle.toLowerCase();

    try {
      return services.firstWhere(
            (service) => service.categoryName.toLowerCase() == lowerSearch,
      );
    } catch (e) {
      try {
        return services.firstWhere(
              (service) =>
          service.categoryName.toLowerCase().contains(lowerSearch) ||
              lowerSearch.contains(service.categoryName.toLowerCase()),
        );
      } catch (e) {
        return getDefaultServices().firstWhere(
              (service) => service.categoryName.toLowerCase().contains(lowerSearch),
          orElse: () => getDefaultServices().first,
        );
      }
    }
  }

  bool get isReadyForNavigation {
    return services.isNotEmpty &&
        userLocation.value != null &&
        areAllDataLoaded.value;
  }
}



// 24 nov old code

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import '../../../../common/widgets/snakbar/snackbar.dart';
// import '../../../../utils/http/http_client.dart';
// import '../../../shared/controllers/base_controller.dart';
// import '../../../shared/services/enhanced_pusher_manager.dart';
// import '../../../shared/services/pusher_background_service.dart';
// import '../../../shared/services/storage_service.dart';
// import '../models/location_model.dart';
// import '../models/ride_type_screen_model.dart';
// import '../models/services/location_service.dart';
//
// class RideTypeController extends BaseController { // ✅ CHANGED: Extend BaseController
//   /// API service list (categories with vehicles)
//   var services = <RideTypeScreenModel>[].obs;
//
//   // Active rides observable
//   final activeRides = <Map<String, dynamic>>[].obs;
//
//   /// Cities list
//   // final cities = <CityModel>[].obs;
//   // var isLoadingCities = true.obs;
//
//   /// User location
//   final userLocation = Rx<UserLocation?>(null);
//   final isLoadingLocation = false.obs;
//   final locationError = ''.obs;
//
//   /// Location service
//   final RideTypeLocationService locationService = RideTypeLocationService();
//
//   /// Track completion of all parallel API calls
//   var areAllDataLoaded = false.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     loadAllData();
//     _loadActiveRides(); // Load active rides on init
//     _setupActiveRidesListeners(); // Setup listeners for active rides
//
//   }
//
//   // ✅ NEW: Load active rides from storage
//   void _loadActiveRides() {
//     try {
//       final rides = StorageService.getActiveRides();
//       activeRides.assignAll(rides);
//       print('📦 Loaded ${activeRides.length} active rides from storage');
//
//       if (activeRides.isNotEmpty) {
//         print('🔔 Setting up listeners for ${activeRides.length} active rides');
//       }
//     } catch (e) {
//       print('❌ Error loading active rides: $e');
//     }
//   }
//
//   void _setupActiveRidesListeners() {
//     final activeRides = StorageService.getActiveRides();
//     print('🔔 Setting up listeners for ${activeRides.length} active rides');
//
//     for (final ride in activeRides) {
//       final rideId = ride['rideId']?.toString();
//       if (rideId != null && rideId.isNotEmpty) {
//         listenToActiveRideChannel(rideId);
//       } else {
//         print('⚠️ Skipping ride with invalid rideId: $ride');
//       }
//     }
//   }
// // ✅ IMPROVED: Listen to active ride channel with reconnection logic
//   void listenToActiveRideChannel(String rideId) {
//     print('🔔 Setting up listener for active ride: $rideId');
//
//     EnhancedPusherManager().subscribeOnce(
//       "ride-$rideId",
//       events: {
//         "ride-ended": (data) {
//           print('🏁 Active ride ended: $rideId');
//           _handleActiveRideEnded(rideId, data);
//         },
//         "ride-cancelled": (data) {
//           print('❌ Active ride cancelled: $rideId');
//           _handleActiveRideEnded(rideId, data);
//         },
//         "driver-location": (data) {
//           print('📍 Driver location update for ride $rideId: $data');
//           _handleDriverLocationUpdate(rideId, data);
//         },
//         "new-message": (data) {
//           print('💬 New message for ride $rideId: $data');
//           _showMessageNotification(rideId, data);
//         },
//         "driver-arrived": (data) {
//           print('🚗 Driver arrived for ride $rideId: $data');
//           // _showDriverArrivedNotification(rideId, data);
//         },
//         "ride-started": (data) {
//           print('🚦 Ride started for ride $rideId: $data');
//           _handleRideStarted(rideId, data);
//         },
//       },
//     );
//   }
//
//
//   // ✅ NEW: Handle driver location updates
//   void _handleDriverLocationUpdate(String rideId, Map<String, dynamic> data) {
//     // You can update UI or store location data if needed
//     print('📍 Driver location for $rideId: ${data['lat']}, ${data['lng']}');
//   }
//
// // ✅ NEW: Handle driver arrived
//   void _handleDriverArrived(String rideId, Map<String, dynamic> data) {
//     FSnackbar.show(
//       title: 'Driver Arrived',
//       message: 'Your driver has arrived at pickup location',
//     );
//   }
//
// // ✅ NEW: Handle ride started
//   void _handleRideStarted(String rideId, Map<String, dynamic> data) {
//     FSnackbar.show(
//       title: 'Ride Started',
//       message: 'Your ride has started',
//     );
//   }
//
// // ✅ IMPROVED: Handle active ride ended with better cleanup
//   void _handleActiveRideEnded(String rideId, Map<String, dynamic> data) {
//     print('🗑️ Removing completed ride: $rideId');
//
//     // Remove from storage first
//     StorageService.removeActiveRide(rideId);
//
//     // Remove from local list
//     activeRides.removeWhere((ride) => ride['rideId'] == rideId);
//
//     // Stop background service for this ride
//     final passengerId = StorageService.getSignUpResponse()?.userId;
//     if (passengerId != null) {
//       PusherBackgroundService().stopBackgroundMode();
//     }
//
//     // Show notification
//     FSnackbar.show(
//       title: 'Ride Completed',
//       message: 'One of your active rides has been completed',
//     );
//
//     print('✅ Successfully removed ride: $rideId, remaining: ${activeRides.length}');
//   }
//
// // ✅ NEW: Show message notification
//   void _showMessageNotification(String rideId, Map<String, dynamic> messageData) {
//     final senderName = messageData['senderName'] ?? 'Driver';
//     final message = messageData['text'] ?? 'New message';
//
//     FSnackbar.show(
//       title: 'Message from $senderName',
//       message: message,
//     );
//   }
//
// // ✅ NEW: Navigate to active ride
//   void navigateToActiveRide(Map<String, dynamic> rideData) {
//     try {
//       final rideArgs = rideData['rideData']?['rideArgs'];
//       final rideId = rideData['rideId'];
//
//       if (rideArgs == null || rideId == null) {
//         FSnackbar.show(
//           title: 'Error',
//           message: 'Could not load ride data',
//           isError: true,
//         );
//         return;
//       }
//
//       print('🚀 Navigating to active ride: $rideId');
//
//       // Navigate directly to DriversWaitingScreen with saved arguments
//       Get.toNamed('/drivers-waiting', arguments: rideArgs);
//
//     } catch (e) {
//       print('❌ Error navigating to active ride: $e');
//       FSnackbar.show(
//         title: 'Error',
//         message: 'Failed to load ride',
//         isError: true,
//       );
//     }
//   }
//
// // ✅ NEW: Check if user can request more rides (for UI)
//   bool get canRequestMoreRides {
//     return StorageService.canAddMoreRides();
//   }
//
// // ✅ NEW: Get current active rides count (for UI)
//   int get activeRidesCount {
//     return StorageService.getActiveRidesCount();
//   }
//
//   /// ✅ UPDATED: Use BaseController's executeWithRetry
//   Future<void> loadAllData() async {
//
//     print("User profile data : "+ StorageService.getProfile().toString());
//     try {
//       isLoading.value = true;
//       error.value = '';
//       areAllDataLoaded(false);
//
//       await executeWithRetry(() async {
//         await Future.wait([
//           fetchServices(),
//           // _fetchCities(),
//           _getUserLocation(),
//         ], eagerError: true);
//
//         areAllDataLoaded(true);
//
//         // ✅ ADD THIS: Pre-cache images after services are loaded
//         precacheServiceImages();
//
//         if (kDebugMode) {
//           print('[RideTypeController] All data loaded successfully');
//           print('[RideTypeController] Services: ${services.length}');
//           // print('[RideTypeController] Cities: ${cities.length}');
//           print('[RideTypeController] User Location: ${userLocation.value?.address}');
//         }
//       });
//     } catch (e) {
//       error.value = e.toString();
//       if (kDebugMode) {
//         print('[RideTypeController] Error loading all data: $e');
//       }
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   void precacheServiceImages() {
//     try {
//       // Wait for the next frame to ensure context is available
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         for (var service in services) {
//           final icon = service.categoryIcon ?? '';
//
//           if (icon.isNotEmpty) {
//             if (_looksLikeBase64(icon)) {
//               // Skip base64 images as they're handled differently
//               continue;
//             } else {
//               // Pre-cache network images
//               try {
//                 precacheImage(NetworkImage(icon), Get.context!);
//                 if (kDebugMode) {
//                   print('[RideTypeController] Pre-cached network image: $icon');
//                 }
//               } catch (e) {
//                 if (kDebugMode) {
//                   print('[RideTypeController] Failed to pre-cache network image: $e');
//                 }
//               }
//             }
//           }
//
//           // Always pre-cache the default asset image for this category
//           final defaultAssetPath = _getDefaultAssetPath(service.categoryName);
//           try {
//             precacheImage(AssetImage(defaultAssetPath), Get.context!);
//             if (kDebugMode) {
//               print('[RideTypeController] Pre-cached asset image: $defaultAssetPath');
//             }
//           } catch (e) {
//             if (kDebugMode) {
//               print('[RideTypeController] Failed to pre-cache asset image: $e');
//             }
//           }
//         }
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print('[RideTypeController] Error in precacheServiceImages: $e');
//       }
//     }
//   }
//
//   /// Helper method to check if string looks like base64
//   bool _looksLikeBase64(String s) {
//     if (s.isEmpty) return false;
//     if (s.startsWith('data:image')) return true;
//     final sanitized = s.replaceAll(RegExp(r'\s+'), '');
//     return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(sanitized);
//   }
//
//   /// Helper method to get default asset path for category
//   String _getDefaultAssetPath(String categoryName) {
//     final name = categoryName.toLowerCase();
//     if (name.contains('courier')) return "assets/images/courier.png";
//     if (name.contains('freight')) return "assets/images/frieght.png";
//     if (name.contains('city to city')) return "assets/images/city.png";
//     if (name.contains('instant ride')) return "assets/images/instant.png";
//     if (name.contains('delivery')) return "assets/images/delievrybike.png";
//     if (name.contains('schedule ride')) return "assets/images/scity.png";
//     return "assets/images/courier.png";
//   }
//
//   /// ✅ EXISTING: Your original methods (unchanged)
//   Future<void> _getUserLocation() async {
//     try {
//       isLoadingLocation(true);
//       locationError('');
//
//       final location = await locationService.getCompleteUserLocation();
//       userLocation.value = location;
//
//       if (kDebugMode) {
//         print('[RideTypeController] User location obtained: ${location.address}');
//         print('[RideTypeController] Coordinates: ${location.latitude}, ${location.longitude}');
//       }
//     } catch (e) {
//       locationError.value = 'Failed to get location: $e';
//       print('[RideTypeController] Location error: $e');
//
//       // fallback default location
//       userLocation.value = UserLocation(
//         latitude: 0.0,
//         longitude: 0.0,
//         address: 'Your Current Location',
//       );
//     } finally {
//       isLoadingLocation(false);
//     }
//   }
//
//   /// Fetch ride services (vehicle categories) from API
//   Future<void> fetchServices() async {
//     try {
//       final response = await FHttpHelper.get('vehicle/list');
//
//       print("Vehicle list API Response in RideTypeController : $response");
//
//       if (response['success'] == true) {
//         final List<dynamic> data = response['data'] ?? [];
//
//         /// Parse into RideTypeScreenModel (with vehicleList inside)
//         services.assignAll(
//           data.map((item) => RideTypeScreenModel.fromJson(item)).toList(),
//         );
//
//         if (kDebugMode) {
//           print('[RideTypeController] Successfully loaded ${services.length} services');
//           for (var s in services) {
//             print('Service: ${s.categoryName}, Vehicles: ${s.vehicleList.length}');
//           }
//         }
//       } else {
//         throw Exception('Services API returned success: false');
//       }
//     } catch (e) {
//       throw Exception('Failed to load services: $e');
//     }
//   }
//
//   /// Fetch cities
//   // Future<void> _fetchCities() async {
//   //   try {
//   //     isLoadingCities(true);
//   //
//   //     final token = StorageService.getAuthToken();
//   //
//   //     if (token == null) {
//   //       print("Error" + "User token not found. Please login again.");
//   //       return;
//   //     }
//   //
//   //     FHttpHelper.setAuthToken(token, useBearer: true);
//   //
//   //     final res = await FHttpHelper.get("city/list-cities");
//   //
//   //     print("Cities list API Response in RideTypeController : $res");
//   //
//   //     if (res['success'] != true) {
//   //       throw Exception('Cities API returned success: false');
//   //     }
//   //
//   //     final data = (res["data"] is List) ? (res["data"] as List) : const [];
//   //
//   //     if (data.isEmpty) {
//   //       print("[RideTypeController] Cities API returned empty data");
//   //       return;
//   //     }
//   //
//   //     final apiCities = data.map((e) => CityModel.fromJson(e)).toList();
//   //     cities.assignAll(apiCities);
//   //
//   //     print("[RideTypeController] Cities API Response: ${data.length} cities received");
//   //   } catch (e) {
//   //     throw Exception('Failed to load cities: $e');
//   //   } finally {
//   //     isLoadingCities(false);
//   //   }
//   // }
//
//   /// Default services fallback (when API fails)
//   List<RideTypeScreenModel> getDefaultServices() {
//     return [
//       RideTypeScreenModel(
//         id: '1',
//         categoryName: "Courier",
//         categoryIcon: "",
//         fare: 0,
//         status: "active",
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         v: 0,
//         vehicleList: [],
//       ),
//       RideTypeScreenModel(
//         id: '2',
//         categoryName: "Freight",
//         categoryIcon: "",
//         fare: 0,
//         status: "active",
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         v: 0,
//         vehicleList: [],
//       ),
//       RideTypeScreenModel(
//         id: '3',
//         categoryName: "City to City",
//         categoryIcon: "",
//         fare: 0,
//         status: "active",
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         v: 0,
//         vehicleList: [],
//       ),
//       RideTypeScreenModel(
//         id: '4',
//         categoryName: "Instant Ride",
//         categoryIcon: "",
//         fare: 0,
//         status: "active",
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         v: 0,
//         vehicleList: [],
//       ),
//       RideTypeScreenModel(
//         id: '5',
//         categoryName: "Delivery",
//         categoryIcon: "",
//         fare: 0,
//         status: "active",
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         v: 0,
//         vehicleList: [],
//       ),
//     ];
//   }
//
//   /// Get service by category name
//   RideTypeScreenModel? getServiceByTitle(String title) {
//     try {
//       return services.firstWhere(
//             (service) => service.categoryName.toLowerCase() == title.toLowerCase(),
//       );
//     } catch (e) {
//       return null;
//     }
//   }
//
//   /// Approximate matching for category name
//   RideTypeScreenModel findServiceByApproximateTitle(String searchTitle) {
//     final lowerSearch = searchTitle.toLowerCase();
//
//     try {
//       return services.firstWhere(
//             (service) => service.categoryName.toLowerCase() == lowerSearch,
//       );
//     } catch (e) {
//       try {
//         return services.firstWhere(
//               (service) =>
//           service.categoryName.toLowerCase().contains(lowerSearch) ||
//               lowerSearch.contains(service.categoryName.toLowerCase()),
//         );
//       } catch (e) {
//         return getDefaultServices().firstWhere(
//               (service) => service.categoryName.toLowerCase().contains(lowerSearch),
//           orElse: () => getDefaultServices().first,
//         );
//       }
//     }
//   }
//
//   /// Ready to navigate when all data is available
//   bool get isReadyForNavigation {
//     return services.isNotEmpty &&
//         // cities.isNotEmpty &&
//         userLocation.value != null &&
//         areAllDataLoaded.value;
//   }
// }
//

// first old code
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
//
// import '../../../../utils/http/http_client.dart';
// import '../../../shared/services/storage_service.dart';
// import '../models/city_model.dart';
// import '../models/location_model.dart';
// import '../models/ride_type_screen_model.dart';
// import '../models/services/location_service.dart';
//
// class RideTypeController extends GetxController {
//   /// API service list (categories with vehicles)
//   var services = <RideTypeScreenModel>[].obs;
//
//   /// Loading and error states
//   var isLoading = true.obs;
//   var error = ''.obs;
//
//   /// Cities list
//   final cities = <CityModel>[].obs;
//   var isLoadingCities = true.obs;
//
//   /// User location
//   final userLocation = Rx<UserLocation?>(null);
//   final isLoadingLocation = false.obs;
//   final locationError = ''.obs;
//
//   /// Location service
//   final RideTypeLocationService locationService = RideTypeLocationService();
//
//   /// Track completion of all parallel API calls
//   var areAllDataLoaded = false.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     loadAllData();
//   }
//
//   /// Load services, cities, and user location in parallel
//   Future<void>  loadAllData() async {
//     try {
//       isLoading(true);
//       error('');
//       areAllDataLoaded(false);
//
//       await Future.wait([
//         fetchServices(),
//         _fetchCities(),
//         _getUserLocation(),
//       ], eagerError: true);
//
//       areAllDataLoaded(true);
//
//       if (kDebugMode) {
//         print('[RideTypeController] All data loaded successfully');
//         print('[RideTypeController] Services: ${services.length}');
//         print('[RideTypeController] Cities: ${cities.length}');
//         print('[RideTypeController] User Location: ${userLocation.value?.address}');
//       }
//     } catch (e) {
//       error(e.toString());
//       if (kDebugMode) {
//         print('[RideTypeController] Error loading all data: $e');
//       }
//     } finally {
//       isLoading(false);
//     }
//   }
//
//   /// Fetch current user location
//   Future<void> _getUserLocation() async {
//     try {
//       isLoadingLocation(true);
//       locationError('');
//
//       final location = await locationService.getCompleteUserLocation();
//       userLocation.value = location;
//
//       if (kDebugMode) {
//         print('[RideTypeController] User location obtained: ${location.address}');
//         print('[RideTypeController] Coordinates: ${location.latitude}, ${location.longitude}');
//       }
//     } catch (e) {
//       locationError.value = 'Failed to get location: $e';
//       print('[RideTypeController] Location error: $e');
//
//       // fallback default location
//       userLocation.value = UserLocation(
//         latitude: 0.0,
//         longitude: 0.0,
//         address: 'Your Current Location',
//       );
//     } finally {
//       isLoadingLocation(false);
//     }
//   }
//
//   /// Fetch ride services (vehicle categories) from API
//   Future<void> fetchServices() async {
//     try {
//       final response = await FHttpHelper.get('vehicle/list');
//
//       print("Vehicle list API Response in RideTypeController : $response");
//
//       if (response['success'] == true) {
//         final List<dynamic> data = response['data'] ?? [];
//
//         /// Parse into RideTypeScreenModel (with vehicleList inside)
//         services.assignAll(
//           data.map((item) => RideTypeScreenModel.fromJson(item)).toList(),
//         );
//
//         if (kDebugMode) {
//           print('[RideTypeController] Successfully loaded ${services.length} services');
//           for (var s in services) {
//             print('Service: ${s.categoryName}, Vehicles: ${s.vehicleList.length}');
//           }
//         }
//       } else {
//         throw Exception('Services API returned success: false');
//       }
//     } catch (e) {
//       throw Exception('Failed to load services: $e');
//     }
//   }
//
//   /// Fetch cities
//   Future<void> _fetchCities() async {
//     try {
//       isLoadingCities(true);
//
//       final token = StorageService.getAuthToken();
//
//       if (token == null) {
//         print("Error" + "User token not found. Please login again.");
//         return;
//       }
//
//       FHttpHelper.setAuthToken(token, useBearer: true);
//
//       final res = await FHttpHelper.get("city/list-cities");
//
//       print("Cities list API Response in RideTypeController : $res");
//
//       if (res['success'] != true) {
//         throw Exception('Cities API returned success: false');
//       }
//
//       final data = (res["data"] is List) ? (res["data"] as List) : const [];
//
//       if (data.isEmpty) {
//         print("[RideTypeController] Cities API returned empty data");
//         return;
//       }
//
//       final apiCities = data.map((e) => CityModel.fromJson(e)).toList();
//       cities.assignAll(apiCities);
//
//       print("[RideTypeController] Cities API Response: ${data.length} cities received");
//     } catch (e) {
//       throw Exception('Failed to load cities: $e');
//     } finally {
//       isLoadingCities(false);
//     }
//   }
//
//   /// Default services fallback (when API fails)
//   List<RideTypeScreenModel> getDefaultServices() {
//     return [
//       RideTypeScreenModel(
//         id: '1',
//         categoryName: "Courier",
//         categoryIcon: "",
//         fare: 0,
//         status: "active",
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         v: 0,
//         vehicleList: [],
//       ),
//       RideTypeScreenModel(
//         id: '2',
//         categoryName: "Freight",
//         categoryIcon: "",
//         fare: 0,
//         status: "active",
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         v: 0,
//         vehicleList: [],
//       ),
//       RideTypeScreenModel(
//         id: '3',
//         categoryName: "City to City",
//         categoryIcon: "",
//         fare: 0,
//         status: "active",
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         v: 0,
//         vehicleList: [],
//       ),
//       RideTypeScreenModel(
//         id: '4',
//         categoryName: "Instant Ride",
//         categoryIcon: "",
//         fare: 0,
//         status: "active",
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         v: 0,
//         vehicleList: [],
//       ),
//       RideTypeScreenModel(
//         id: '5',
//         categoryName: "Delivery",
//         categoryIcon: "",
//         fare: 0,
//         status: "active",
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         v: 0,
//         vehicleList: [],
//       ),
//     ];
//   }
//
//   /// Get service by category name
//   RideTypeScreenModel? getServiceByTitle(String title) {
//     try {
//       return services.firstWhere(
//             (service) => service.categoryName.toLowerCase() == title.toLowerCase(),
//       );
//     } catch (e) {
//       return null;
//     }
//   }
//
//   /// Approximate matching for category name
//   RideTypeScreenModel findServiceByApproximateTitle(String searchTitle) {
//     final lowerSearch = searchTitle.toLowerCase();
//
//     try {
//       return services.firstWhere(
//             (service) => service.categoryName.toLowerCase() == lowerSearch,
//       );
//     } catch (e) {
//       try {
//         return services.firstWhere(
//               (service) =>
//           service.categoryName.toLowerCase().contains(lowerSearch) ||
//               lowerSearch.contains(service.categoryName.toLowerCase()),
//         );
//       } catch (e) {
//         return getDefaultServices().firstWhere(
//               (service) => service.categoryName.toLowerCase().contains(lowerSearch),
//           orElse: () => getDefaultServices().first,
//         );
//       }
//     }
//   }
//
//   /// Ready to navigate when all data is available
//   bool get isReadyForNavigation {
//     return services.isNotEmpty &&
//         cities.isNotEmpty &&
//         userLocation.value != null &&
//         areAllDataLoaded.value;
//   }
// }
