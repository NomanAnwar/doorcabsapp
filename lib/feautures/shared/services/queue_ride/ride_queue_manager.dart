// // lib/feautures/rides/passenger/services/ride_queue_manager.dart
// import 'dart:async';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:doorcab/utils/http/http_client.dart';
//
// import '../storage_service.dart';
//
// class ActiveRide {
//   final String rideId;
//   final String driverId;
//   final String rideType;
//   final String pickupAddress;
//   final String dropoffAddress;
//   final double fare;
//   final int passengers;
//   final String paymentMethod;
//   final DateTime requestedAt;
//   final String status; // 'waiting', 'accepted', 'in_progress', 'completed', 'cancelled'
//   final LatLng? pickupCoords;
//   final LatLng? dropoffCoords;
//   final Map<String, dynamic>? driverInfo;
//   final Map<String, dynamic>? bidInfo;
//   final List<Map<String, dynamic>> stops;
//   final String? vehicleType;
//   final double? distance;
//   final String? eta;
//   final String? estimatedDropTime;
//
//   ActiveRide({
//     required this.rideId,
//     required this.driverId,
//     required this.rideType,
//     required this.pickupAddress,
//     required this.dropoffAddress,
//     required this.fare,
//     required this.passengers,
//     required this.paymentMethod,
//     required this.requestedAt,
//     required this.status,
//     this.pickupCoords,
//     this.dropoffCoords,
//     this.driverInfo,
//     this.bidInfo,
//     this.stops = const [],
//     this.vehicleType,
//     this.distance,
//     this.eta,
//     this.estimatedDropTime,
//   });
//
//   Map<String, dynamic> toJson() {
//     return {
//       'rideId': rideId,
//       'driverId': driverId,
//       'rideType': rideType,
//       'pickupAddress': pickupAddress,
//       'dropoffAddress': dropoffAddress,
//       'fare': fare,
//       'passengers': passengers,
//       'paymentMethod': paymentMethod,
//       'requestedAt': requestedAt.toIso8601String(),
//       'status': status,
//       'pickupCoords': pickupCoords != null
//           ? {'lat': pickupCoords!.latitude, 'lng': pickupCoords!.longitude}
//           : null,
//       'dropoffCoords': dropoffCoords != null
//           ? {'lat': dropoffCoords!.latitude, 'lng': dropoffCoords!.longitude}
//           : null,
//       'driverInfo': driverInfo,
//       'bidInfo': bidInfo,
//       'stops': stops,
//       'vehicleType': vehicleType,
//       'distance': distance,
//       'eta': eta,
//       'estimatedDropTime': estimatedDropTime,
//     };
//   }
//
//   static ActiveRide fromJson(Map<String, dynamic> json) {
//     return ActiveRide(
//       rideId: json['rideId'] ?? '',
//       driverId: json['driverId'] ?? '',
//       rideType: json['rideType'] ?? 'Standard',
//       pickupAddress: json['pickupAddress'] ?? '',
//       dropoffAddress: json['dropoffAddress'] ?? '',
//       fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
//       passengers: (json['passengers'] as num?)?.toInt() ?? 1,
//       paymentMethod: json['paymentMethod'] ?? 'cash',
//       requestedAt: DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
//       status: json['status'] ?? 'waiting',
//       pickupCoords: json['pickupCoords'] != null
//           ? LatLng(
//         (json['pickupCoords']['lat'] as num).toDouble(),
//         (json['pickupCoords']['lng'] as num).toDouble(),
//       )
//           : null,
//       dropoffCoords: json['dropoffCoords'] != null
//           ? LatLng(
//         (json['dropoffCoords']['lat'] as num).toDouble(),
//         (json['dropoffCoords']['lng'] as num).toDouble(),
//       )
//           : null,
//       driverInfo: json['driverInfo'] != null
//           ? Map<String, dynamic>.from(json['driverInfo'])
//           : null,
//       bidInfo: json['bidInfo'] != null
//           ? Map<String, dynamic>.from(json['bidInfo'])
//           : null,
//       stops: (json['stops'] as List?)?.cast<Map<String, dynamic>>() ?? [],
//       vehicleType: json['vehicleType'],
//       distance: (json['distance'] as num?)?.toDouble(),
//       eta: json['eta'],
//       estimatedDropTime: json['estimatedDropTime'],
//     );
//   }
//
//   ActiveRide copyWith({
//     String? rideId,
//     String? driverId,
//     String? rideType,
//     String? pickupAddress,
//     String? dropoffAddress,
//     double? fare,
//     int? passengers,
//     String? paymentMethod,
//     DateTime? requestedAt,
//     String? status,
//     LatLng? pickupCoords,
//     LatLng? dropoffCoords,
//     Map<String, dynamic>? driverInfo,
//     Map<String, dynamic>? bidInfo,
//     List<Map<String, dynamic>>? stops,
//     String? vehicleType,
//     double? distance,
//     String? eta,
//     String? estimatedDropTime,
//   }) {
//     return ActiveRide(
//       rideId: rideId ?? this.rideId,
//       driverId: driverId ?? this.driverId,
//       rideType: rideType ?? this.rideType,
//       pickupAddress: pickupAddress ?? this.pickupAddress,
//       dropoffAddress: dropoffAddress ?? this.dropoffAddress,
//       fare: fare ?? this.fare,
//       passengers: passengers ?? this.passengers,
//       paymentMethod: paymentMethod ?? this.paymentMethod,
//       requestedAt: requestedAt ?? this.requestedAt,
//       status: status ?? this.status,
//       pickupCoords: pickupCoords ?? this.pickupCoords,
//       dropoffCoords: dropoffCoords ?? this.dropoffCoords,
//       driverInfo: driverInfo ?? this.driverInfo,
//       bidInfo: bidInfo ?? this.bidInfo,
//       stops: stops ?? this.stops,
//       vehicleType: vehicleType ?? this.vehicleType,
//       distance: distance ?? this.distance,
//       eta: eta ?? this.eta,
//       estimatedDropTime: estimatedDropTime ?? this.estimatedDropTime,
//     );
//   }
// }
//
// class RideQueueManager extends GetxService {
//   static RideQueueManager get instance => Get.find<RideQueueManager>();
//
//   final activeRides = <ActiveRide>[].obs;
//   final currentRideIndex = 0.obs;
//   final maxConcurrentRides = 3;
//   final isLoading = false.obs;
//
//
//   Future<RideQueueManager> init() async {
//     await _loadStoredRides();
//     await cleanupOldRides();
//     return this;
//   }
//
//   @override
//   void onInit() {
//     super.onInit();
//     _loadStoredRides();
//   }
//
//   ActiveRide? get currentRide {
//     if (activeRides.isEmpty) return null;
//     if (currentRideIndex.value < activeRides.length) {
//       return activeRides[currentRideIndex.value];
//     }
//     return activeRides.first;
//   }
//
//   bool get canRequestNewRide => activeRides.length < maxConcurrentRides;
//
//   bool get hasActiveRides => activeRides.isNotEmpty;
//
//   List<ActiveRide> get waitingRides =>
//       activeRides.where((ride) => ride.status == 'waiting').toList();
//
//   List<ActiveRide> get acceptedRides =>
//       activeRides.where((ride) => ride.status == 'accepted').toList();
//
//   List<ActiveRide> get inProgressRides =>
//       activeRides.where((ride) => ride.status == 'in_progress').toList();
//
//   List<ActiveRide> get completedRides =>
//       activeRides.where((ride) => ride.status == 'completed').toList();
//
//   List<ActiveRide> get activeRidesForDisplay =>
//       activeRides.where((ride) =>
//       ride.status == 'waiting' ||
//           ride.status == 'accepted' ||
//           ride.status == 'in_progress'
//       ).toList();
//
//   Future<void> addNewRide(ActiveRide ride) async {
//     if (!canRequestNewRide) {
//       throw Exception('Maximum concurrent rides limit reached');
//     }
//
//     // Check if ride already exists
//     if (activeRides.any((r) => r.rideId == ride.rideId)) {
//       print('⚠️ Ride ${ride.rideId} already exists in queue');
//       return;
//     }
//
//     activeRides.add(ride);
//     currentRideIndex.value = activeRides.length - 1;
//     await _storeRides();
//
//     print('🚗 Ride added to queue: ${ride.rideId}');
//     print('📊 Total active rides: ${activeRides.length}');
//   }
//
//   Future<void> updateRideStatus(String rideId, String newStatus) async {
//     final index = activeRides.indexWhere((ride) => ride.rideId == rideId);
//     if (index != -1) {
//       final updatedRide = activeRides[index].copyWith(status: newStatus);
//       activeRides[index] = updatedRide;
//       await _storeRides();
//
//       print('🔄 Ride ${rideId} status updated to: $newStatus');
//     }
//   }
//
//   Future<void> updateRideInfo(String rideId, Map<String, dynamic> updates) async {
//     final index = activeRides.indexWhere((ride) => ride.rideId == rideId);
//     if (index != -1) {
//       final currentRide = activeRides[index];
//       final updatedRide = ActiveRide(
//         rideId: currentRide.rideId,
//         driverId: updates['driverId'] ?? currentRide.driverId,
//         rideType: updates['rideType'] ?? currentRide.rideType,
//         pickupAddress: updates['pickupAddress'] ?? currentRide.pickupAddress,
//         dropoffAddress: updates['dropoffAddress'] ?? currentRide.dropoffAddress,
//         fare: (updates['fare'] as num?)?.toDouble() ?? currentRide.fare,
//         passengers: (updates['passengers'] as num?)?.toInt() ?? currentRide.passengers,
//         paymentMethod: updates['paymentMethod'] ?? currentRide.paymentMethod,
//         requestedAt: currentRide.requestedAt,
//         status: updates['status'] ?? currentRide.status,
//         pickupCoords: updates['pickupCoords'] != null
//             ? LatLng(
//           (updates['pickupCoords']['lat'] as num).toDouble(),
//           (updates['pickupCoords']['lng'] as num).toDouble(),
//         )
//             : currentRide.pickupCoords,
//         dropoffCoords: updates['dropoffCoords'] != null
//             ? LatLng(
//           (updates['dropoffCoords']['lat'] as num).toDouble(),
//           (updates['dropoffCoords']['lng'] as num).toDouble(),
//         )
//             : currentRide.dropoffCoords,
//         driverInfo: updates['driverInfo'] ?? currentRide.driverInfo,
//         bidInfo: updates['bidInfo'] ?? currentRide.bidInfo,
//         stops: (updates['stops'] as List?)?.cast<Map<String, dynamic>>() ?? currentRide.stops,
//         vehicleType: updates['vehicleType'] ?? currentRide.vehicleType,
//         distance: (updates['distance'] as num?)?.toDouble() ?? currentRide.distance,
//         eta: updates['eta'] ?? currentRide.eta,
//         estimatedDropTime: updates['estimatedDropTime'] ?? currentRide.estimatedDropTime,
//       );
//
//       activeRides[index] = updatedRide;
//       await _storeRides();
//
//       print('📝 Ride ${rideId} info updated');
//     }
//   }
//
//   Future<void> removeRide(String rideId) async {
//     activeRides.removeWhere((ride) => ride.rideId == rideId);
//
//     // Adjust current index if needed
//     if (currentRideIndex.value >= activeRides.length && activeRides.isNotEmpty) {
//       currentRideIndex.value = activeRides.length - 1;
//     } else if (activeRides.isEmpty) {
//       currentRideIndex.value = 0;
//     }
//
//     await _storeRides();
//     print('🗑️ Ride removed from queue: $rideId');
//   }
//
//   void switchToRide(int index) {
//     if (index >= 0 && index < activeRides.length) {
//       currentRideIndex.value = index;
//       print('🔄 Switched to ride: ${activeRides[index].rideId}');
//     }
//   }
//
//   void switchToRideById(String rideId) {
//     final index = activeRides.indexWhere((ride) => ride.rideId == rideId);
//     if (index != -1) {
//       switchToRide(index);
//     }
//   }
//
//   ActiveRide? getRideById(String rideId) {
//     try {
//       return activeRides.firstWhere((ride) => ride.rideId == rideId);
//     } catch (e) {
//       return null;
//     }
//   }
//
//   Future<void> _loadStoredRides() async {
//     try {
//       isLoading.value = true;
//       final stored = StorageService.getStoredRides();
//       if (stored != null) {
//         // Filter out completed and cancelled rides that are older than 1 hour
//         final now = DateTime.now();
//         final activeStoredRides = stored.where((ride) {
//           if (ride.status == 'completed' || ride.status == 'cancelled') {
//             final timeDiff = now.difference(ride.requestedAt);
//             return timeDiff.inHours < 1; // Keep recent completed/cancelled rides for 1 hour
//           }
//           return true;
//         }).toList();
//
//         activeRides.assignAll(activeStoredRides);
//         print('📥 Loaded ${activeRides.length} rides from storage');
//       }
//     } catch (e) {
//       print('❌ Error loading stored rides: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   Future<void> _storeRides() async {
//     try {
//       await StorageService.storeRides(activeRides);
//     } catch (e) {
//       print('❌ Error storing rides: $e');
//     }
//   }
//
//   // Sync ride status with server
//   Future<void> syncRidesWithServer() async {
//     try {
//       isLoading.value = true;
//
//       for (final ride in List.from(activeRides)) {
//         try {
//           final response = await FHttpHelper.get('ride/status/${ride.rideId}');
//           if (response['success'] == true) {
//             final serverStatus = response['data']['status'];
//             if (serverStatus != ride.status) {
//               await updateRideStatus(ride.rideId, serverStatus);
//             }
//
//             // Update other ride info if available
//             final rideData = response['data'];
//             await updateRideInfo(ride.rideId, {
//               'driverInfo': rideData['driver'],
//               'fare': rideData['fare'],
//               'distance': rideData['distance'],
//               'eta': rideData['eta'],
//               'estimatedDropTime': rideData['estimatedDropTime'],
//             });
//           }
//         } catch (e) {
//           print('❌ Error syncing ride ${ride.rideId}: $e');
//         }
//       }
//
//       print('✅ Synced ${activeRides.length} rides with server');
//     } catch (e) {
//       print('❌ Error syncing rides with server: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   // Clean up old completed/cancelled rides
//   Future<void> cleanupOldRides() async {
//     final now = DateTime.now();
//     final ridesToRemove = activeRides.where((ride) {
//       if (ride.status == 'completed' || ride.status == 'cancelled') {
//         final timeDiff = now.difference(ride.requestedAt);
//         return timeDiff.inHours >= 1; // Remove rides completed/cancelled more than 1 hour ago
//       }
//       return false;
//     }).toList();
//
//     for (final ride in ridesToRemove) {
//       await removeRide(ride.rideId);
//     }
//
//     if (ridesToRemove.isNotEmpty) {
//       print('🧹 Cleaned up ${ridesToRemove.length} old rides');
//     }
//   }
//
//   // Get rides that need Pusher subscriptions
//   List<String> getRidesNeedingSubscription() {
//     return activeRides
//         .where((ride) => ride.status != 'completed' && ride.status != 'cancelled')
//         .map((ride) => ride.rideId)
//         .toList();
//   }
//
//   // Print debug info
//   void printQueueStatus() {
//     print('\n🎯 RIDE QUEUE STATUS');
//     print('====================');
//     print('Total Rides: ${activeRides.length}');
//     print('Current Index: $currentRideIndex');
//     print('Can Request New: $canRequestNewRide');
//
//     for (int i = 0; i < activeRides.length; i++) {
//       final ride = activeRides[i];
//       final isCurrent = i == currentRideIndex.value;
//       print('${isCurrent ? '➡️' : '  '} $i. ${ride.rideType} - ${ride.status} - PKR ${ride.fare}');
//     }
//     print('====================\n');
//   }
// }