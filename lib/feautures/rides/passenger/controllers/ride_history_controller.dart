import 'package:get/get.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/storage_service.dart';
import '../models/ride_model.dart';

class RideHistoryController extends BaseController {
  var rides = <RideModel>[].obs;
  var selectedFilter = "All".obs;
  var isLoading = false.obs;
  var currentUserRole = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRides();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  Future<void> fetchRides() async {
    try {
      isLoading.value = true;

      await executeWithRetry(() async {
        // Get user ID and role from storage
        final userId = StorageService.getSignUpResponse()!.userId;
        final userRole = StorageService.getRole();
        currentUserRole.value = userRole!;

        print('🔄 Fetching rides for user: $userId, role: $userRole');

        if (userId.isEmpty || userRole.isEmpty) {
          throw Exception('User information not found. UserId: $userId, Role: $userRole');
        }

        final token = StorageService.getAuthToken();
        if (token == null) {
          print("❌ User token not found for active rides API");
          return;
        }

        FHttpHelper.setAuthToken(token, useBearer: true);

        // Call the API endpoint
        final response = await FHttpHelper.get('ride/get/$userId/$userRole');

        print('✅ API Response received. Contains rides: ${response.containsKey('rides')}');

        if (response.containsKey('rides') && response['rides'] is List) {
          final ridesData = response['rides'] as List;
          print('📊 Number of rides in response: ${ridesData.length}');

          if (ridesData.isEmpty) {
            print('ℹ️ No rides found in API response');
            rides.clear();
            return;
          }

          // Convert API response to RideModel list with role awareness
          final fetchedRides = <RideModel>[];
          int successCount = 0;
          int errorCount = 0;

          for (var i = 0; i < ridesData.length; i++) {
            try {
              if (ridesData[i] is Map<String, dynamic>) {
                final rideData = ridesData[i] as Map<String, dynamic>;
                final rideId = rideData['_id']?.toString() ?? 'unknown';

                // 🎯 PASS ROLE INFORMATION TO MODEL
                final isDriverRole = userRole.toLowerCase() == 'driver';
                final ride = RideModel.fromApiResponse(rideData, isDriverRole: isDriverRole);
                fetchedRides.add(ride);
                successCount++;

                print('✅ Successfully mapped ride $i for $userRole role');
              } else {
                print('❌ Ride $i is not a Map<String, dynamic>');
                errorCount++;
              }
            } catch (e, stackTrace) {
              print('❌ Failed to process ride $i:');
              print('Error: $e');
              print('Stack trace: $stackTrace');
              errorCount++;
              continue;
            }
          }

          print('\n📈 Mapping results: $successCount successful, $errorCount failed');
          print('👤 User role: $userRole');

          // Sort by date (newest first)
          if (fetchedRides.isNotEmpty) {
            fetchedRides.sort((a, b) => b.rawDate.compareTo(a.rawDate));
            rides.assignAll(fetchedRides);
            print('🎉 Successfully loaded ${fetchedRides.length} rides for $userRole');
          } else {
            print('⚠️ No rides were successfully mapped');
            rides.clear();
          }
        } else {
          final errorMessage = 'Invalid response format: rides not found or not a list. Response keys: ${response.keys}';
          print('❌ $errorMessage');
          throw Exception(errorMessage);
        }
      }, maxRetries: 2);
    } catch (e) {
      print('💥 Error in fetchRides: $e');
      showError('Failed to load ride history: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to get filtered rides based on selected filter
  List<RideModel> get filteredRides {
    if (selectedFilter.value == "All") {
      return rides;
    }
    return rides.where((ride) => ride.status.toLowerCase() == selectedFilter.value.toLowerCase()).toList();
  }
}


// import 'package:get/get.dart';
// import '../models/ride_model.dart';
//
// class RideHistoryController extends GetxController {
//   var rides = <RideModel>[].obs;
//   var selectedFilter = "All".obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     fetchRides();
//   }
//
//   void setFilter(String filter) {
//     selectedFilter.value = filter;
//   }
//
//   void fetchRides() {
//     rides.assignAll([
//
//       RideModel(
//         date: "Sunday, August 10",
//         time: "11:25 PM",
//         location: "Service Ln 63 Home",
//         rideType: "Door Comfort",
//         fare: 250,
//         status: "Completed",
//         iconPath: "assets/images/car.png",
//       ),
//       RideModel(
//         date: "Tuesday, August 10",
//         time: "07:50 AM",
//         location: "Service Ln 63 Home",
//         rideType: "Door Bike",
//         fare: 133,
//         status: "Completed",
//         iconPath: "assets/images/bike.png",
//       ),
//       RideModel(
//         date: "Tuesday, August 10",
//         time: "11:00 PM",
//         location: "Service Ln 63 Home",
//         rideType: "Door Comfort",
//         fare: 0,
//         status: "Canceled",
//         iconPath: "assets/images/car.png",
//       ),
//
//
//       RideModel(
//         date: "Tuesday, August 05",
//         time: "07:50 AM",
//         location: "Service Ln 63 Home",
//         rideType: "Door Bike",
//         fare: 133,
//         status: "Completed",
//         iconPath: "assets/images/bike.png",
//       ),
//       RideModel(
//         date: "Tuesday, August 05",
//         time: "02:50 PM",
//         location: "Service Ln 63 Home",
//         rideType: "Delivery",
//         fare: 275,
//         status: "Completed",
//         iconPath: "assets/images/delivery.png",
//       ),
//
//
//       RideModel(
//         date: "Tuesday, August 05",
//         time: "07:50 AM",
//         location: "Service Ln 63 Home",
//         rideType: "Door Bike",
//         fare: 133,
//         status: "Completed",
//         iconPath: "assets/images/bike.png",
//       ),
//       RideModel(
//         date: "Tuesday, August 05",
//         time: "02:50 PM",
//         location: "Service Ln 63 Home",
//         rideType: "Delivery",
//         fare: 275,
//         status: "Completed",
//         iconPath: "assets/images/delivery.png",
//       ),
//
//       RideModel(
//         date: "Tuesday, August 05",
//         time: "07:50 AM",
//         location: "Service Ln 63 Home",
//         rideType: "Door Bike",
//         fare: 133,
//         status: "Completed",
//         iconPath: "assets/images/bike.png",
//       ),
//       RideModel(
//         date: "Tuesday, August 05",
//         time: "02:50 PM",
//         location: "Service Ln 63 Home",
//         rideType: "Delivery",
//         fare: 275,
//         status: "Completed",
//         iconPath: "assets/images/delivery.png",
//       ),
//     ]);
//   }
// }
