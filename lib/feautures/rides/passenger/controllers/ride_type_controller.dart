import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/storage_service.dart';
import '../models/city_model.dart';
import '../models/location_model.dart';
import '../models/ride_type_screen_model.dart';
import '../models/services/location_service.dart';

class RideTypeController extends BaseController { // ✅ CHANGED: Extend BaseController
  /// API service list (categories with vehicles)
  var services = <RideTypeScreenModel>[].obs;

  /// Cities list
  final cities = <CityModel>[].obs;
  var isLoadingCities = true.obs;

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
  }

  /// ✅ UPDATED: Use BaseController's executeWithRetry
  Future<void> loadAllData() async {
    try {
      isLoading.value = true;
      error.value = '';
      areAllDataLoaded(false);

      await executeWithRetry(() async {
        await Future.wait([
          fetchServices(),
          _fetchCities(),
          _getUserLocation(),
        ], eagerError: true);

        areAllDataLoaded(true);

        if (kDebugMode) {
          print('[RideTypeController] All data loaded successfully');
          print('[RideTypeController] Services: ${services.length}');
          print('[RideTypeController] Cities: ${cities.length}');
          print('[RideTypeController] User Location: ${userLocation.value?.address}');
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

  /// ✅ EXISTING: Your original methods (unchanged)
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

      // fallback default location
      userLocation.value = UserLocation(
        latitude: 0.0,
        longitude: 0.0,
        address: 'Your Current Location',
      );
    } finally {
      isLoadingLocation(false);
    }
  }

  /// Fetch ride services (vehicle categories) from API
  Future<void> fetchServices() async {
    try {
      final response = await FHttpHelper.get('vehicle/list');

      print("Vehicle list API Response in RideTypeController : $response");

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];

        /// Parse into RideTypeScreenModel (with vehicleList inside)
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

  /// Fetch cities
  Future<void> _fetchCities() async {
    try {
      isLoadingCities(true);

      final token = StorageService.getAuthToken();

      if (token == null) {
        print("Error" + "User token not found. Please login again.");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      final res = await FHttpHelper.get("city/list-cities");

      print("Cities list API Response in RideTypeController : $res");

      if (res['success'] != true) {
        throw Exception('Cities API returned success: false');
      }

      final data = (res["data"] is List) ? (res["data"] as List) : const [];

      if (data.isEmpty) {
        print("[RideTypeController] Cities API returned empty data");
        return;
      }

      final apiCities = data.map((e) => CityModel.fromJson(e)).toList();
      cities.assignAll(apiCities);

      print("[RideTypeController] Cities API Response: ${data.length} cities received");
    } catch (e) {
      throw Exception('Failed to load cities: $e');
    } finally {
      isLoadingCities(false);
    }
  }

  /// Default services fallback (when API fails)
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

  /// Get service by category name
  RideTypeScreenModel? getServiceByTitle(String title) {
    try {
      return services.firstWhere(
            (service) => service.categoryName.toLowerCase() == title.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Approximate matching for category name
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

  /// Ready to navigate when all data is available
  bool get isReadyForNavigation {
    return services.isNotEmpty &&
        cities.isNotEmpty &&
        userLocation.value != null &&
        areAllDataLoaded.value;
  }
}

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
