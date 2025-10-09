import 'dart:async';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/models/place_suggestion.dart';
import '../../../shared/services/places_service.dart';
import '../../../shared/services/storage_service.dart';
import '../models/location_model.dart';

enum ActiveField { pickup, dropoff }

class DropOffController extends BaseController { // ✅ CHANGED: Extend BaseController
  DropOffController(this.apiKey);

  final String apiKey;
  late final PlacesService places;

  final pickupCtrl = TextEditingController();
  final dropCtrl = TextEditingController();

  final pickupFocus = FocusNode();
  final dropFocus = FocusNode();

  final activeField = ActiveField.dropoff.obs;

  final suggestions = <PlaceSuggestion>[].obs;
  final recent = <PlaceSuggestion>[].obs;

  final stops = <PlaceSuggestion>[].obs; // max 3

  Timer? _debounce;

  /// Keep the last selected PlaceSuggestion (with latLng if available)
  PlaceSuggestion? lastPickupPlace;
  PlaceSuggestion? lastDropoffPlace;

  // ✅ ADDED: Store passed data from RideTypeScreen
  final Rx<UserLocation?> userLocation = Rx<UserLocation?>(null);
  final RxList<dynamic> vehicles = <dynamic>[].obs;
  final RxList<dynamic> cities = <dynamic>[].obs;
  final Rx<dynamic> service = Rx<dynamic>(null);

  @override
  void onInit() {
    super.onInit();
    places = PlacesService(apiKey);

    final args = Get.arguments as Map?;

    // ✅ ADDED: Store all passed data
    if (args?['userLocation'] is Map) {
      userLocation.value = UserLocation.fromJson(args!['userLocation'] as Map<String, dynamic>);
    }
    if (args?['vehicles'] is List) {
      vehicles.assignAll(args!['vehicles'] as List);
    }
    if (args?['cities'] is List) {
      cities.assignAll(args!['cities'] as List);
    }
    if (args?['service'] != null) {
      service.value = args!['service'];
    }

    // ✅ UPDATED: Use user location address from params
    pickupCtrl.text = userLocation.value?.address ??
        args?['userCurrentAddress'] ??
        args?['pickup'] ??
        'Your Current Location';
    dropCtrl.text = args?['dropoff'] ?? '';

    // ✅ store pickupLatLng if passed
    if (args?['pickupLatLng'] != null && args?['pickupLatLng'] is LatLng) {
      lastPickupPlace = PlaceSuggestion(
        placeId: 'arg_pickup_${DateTime.now().millisecondsSinceEpoch}',
        description: pickupCtrl.text,
        latLng: args!['pickupLatLng'],
      );
    }
    // ✅ ADDED: Also check for userCurrentLocation from params
    else if (args?['userCurrentLocation'] != null && args?['userCurrentLocation'] is LatLng) {
      lastPickupPlace = PlaceSuggestion(
        placeId: 'current_location_${DateTime.now().millisecondsSinceEpoch}',
        description: pickupCtrl.text,
        latLng: args!['userCurrentLocation'] as LatLng,
      );
    }
    // ✅ ADDED: Also check for userLocation from params
    else if (userLocation.value != null) {
      lastPickupPlace = PlaceSuggestion(
        placeId: 'current_location_${DateTime.now().millisecondsSinceEpoch}',
        description: pickupCtrl.text,
        latLng: userLocation.value!.toLatLng(),
      );
    }

    if (args?['activeField'] == 'pickup') {
      activeField.value = ActiveField.pickup;
      pickupFocus.requestFocus();
    } else {
      activeField.value = ActiveField.dropoff;
      dropFocus.requestFocus();
    }

    recent.assignAll(StorageService.getRecent());

    pickupCtrl.addListener(() => _onQueryChanged(ActiveField.pickup));
    dropCtrl.addListener(() => _onQueryChanged(ActiveField.dropoff));

    pickupFocus.addListener(_handleFocusChange);
    dropFocus.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!pickupFocus.hasFocus && !dropFocus.hasFocus) {
      suggestions.clear();
    }
  }

  void _onQueryChanged(ActiveField field) {
    if ((field == ActiveField.pickup && !pickupFocus.hasFocus) ||
        (field == ActiveField.dropoff && !dropFocus.hasFocus)) {
      return;
    }

    final q = field == ActiveField.pickup ? pickupCtrl.text : dropCtrl.text;

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (q.trim().isEmpty) {
        suggestions.clear();
        return;
      }
      isLoading.value = true;
      suggestions.assignAll(await places.autocomplete(q.trim()));
      isLoading.value = false;
      activeField.value = field;
    });
  }

  Future<void> chooseOnMap() async {
    final result = await Get.toNamed(
      '/map-selection',
      arguments: {
        'activeField':
        activeField.value == ActiveField.pickup ? 'pickup' : 'dropoff',
      },
    );

    if (result is Map && result['lat'] != null && result['lng'] != null) {
      final s = PlaceSuggestion(
        placeId: 'map_${DateTime.now().millisecondsSinceEpoch}',
        description: result['address'] ?? 'Selected on map',
        latLng: LatLng(result['lat'], result['lng']),
      );

      setFieldValue(s);
    }
  }

  Future<void> selectSuggestion(PlaceSuggestion s) async {
    isLoading.value = true;

    // ❌ COMMENTED OUT: Get origin from RideHomeController (user's current position)
    // final rideHome = Get.find<RideHomeController>();
    // final origin = rideHome.currentPosition.value;

    // ✅ ADDED: Use origin from passed params instead
    LatLng? origin;
    if (lastPickupPlace?.latLng != null) {
      origin = lastPickupPlace!.latLng;
    } else if (userLocation.value != null) {
      origin = userLocation.value!.toLatLng();
    } else if (Get.arguments?['userCurrentLocation'] is LatLng) {
      origin = Get.arguments!['userCurrentLocation'] as LatLng;
    } else if (Get.arguments?['pickupLatLng'] is LatLng) {
      origin = Get.arguments!['pickupLatLng'] as LatLng;
    }

    final withLatLng = await places.placeDetails(s, origin: origin);
    isLoading.value = false;

    if (withLatLng != null) {
      setFieldValue(withLatLng);
    }

    suggestions.clear();
  }

  void setFieldValue(PlaceSuggestion s) {
    if (activeField.value == ActiveField.pickup) {
      pickupCtrl.text = s.description;
      lastPickupPlace = s;
      dropFocus.requestFocus();
      activeField.value = ActiveField.dropoff;
    } else {
      dropCtrl.text = s.description;
      lastDropoffPlace = s;
    }

    StorageService.addRecent(s);
    recent.assignAll(StorageService.getRecent());
    suggestions.clear();
  }

  void toggleField(ActiveField field) {
    activeField.value = field;
    if (field == ActiveField.pickup) {
      pickupFocus.requestFocus();
    } else {
      dropFocus.requestFocus();
    }
  }

  void addStop() {
    if (stops.length >= 3) {
      Get.snackbar('Limit reached', 'You can add up to 3 stops only.');
      return;
    }
    _openStopsManager();
  }

  void _openStopsManager() {
    Get.bottomSheet(
      Obx(
            () => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                "Manage Stops",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (stops.isEmpty)
                const Text("No stops added yet",
                    style: TextStyle(color: Colors.grey)),
              ...List.generate(
                stops.length,
                    (i) => Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.place, color: FColors.secondaryColor),
                    title: Text(stops[i].description, style: FTextTheme
                        .lightTextTheme
                        .titleMedium),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: FColors.primaryColor),
                      onPressed: () => stops.removeAt(i),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Get.toNamed(
                    '/map-selection',
                    arguments: {'activeField': 'dropoff'},
                  );
                  if (result is Map && result['lat'] != null) {
                    final s = PlaceSuggestion(
                      placeId: 'stop_${DateTime.now().millisecondsSinceEpoch}',
                      description: result['address'] ?? 'Stop (map)',
                      latLng: LatLng(result['lat'], result['lng']),
                    );
                    if (stops.length < 3) stops.add(s);
                  }
                },
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text("Add stop from map"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FColors.secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // Updated confirmSelection -> pass selected vehicle model and lat/lng (if available)
  void confirmSelection() {
    if (pickupCtrl.text.trim().isEmpty || dropCtrl.text.trim().isEmpty) {
      showError('Pickup and Drop-off are required.');
      return;
    }

    // ❌ COMMENTED OUT: Get from RideHomeController
    // final home = Get.find<RideHomeController>();
    // final selectedVehicleModel = home.selectedVehicle.value;

    // ✅ ADDED: Build payload with ALL data from params
    final payload = {
      'pickup': pickupCtrl.text.trim(),
      'dropoff': dropCtrl.text.trim(),
      'stops': stops.map((e) => e.toJson()).toList(),

      // ✅ ADDED: Pass vehicles, cities, and service data from params
      'vehicles': vehicles.toList(),
      'cities': cities.toList(),
      'service': service.value,
      'userLocation': userLocation.value?.toJson(),
      'userCurrentAddress': userLocation.value?.address,

      // ❌ COMMENTED OUT: RideHomeController data
      // 'rideType': selectedVehicleModel?.name ?? '',
      // 'selectedRideIndex': home.selectedRideIndex.value,
      // 'selectedVehicle': selectedVehicleModel != null ? {
      //   'id': selectedVehicleModel.id,
      //   'name': selectedVehicleModel.name,
      //   'fareValue': selectedVehicleModel.fareValue,
      //   'description': selectedVehicleModel.description,
      //   'iconBase64': selectedVehicleModel.iconBase64,
      //   'supportsRideType': selectedVehicleModel.supportsRideType,
      // } : null,
    };

    // include coordinates if available
    if (lastPickupPlace?.latLng != null) {
      payload['pickupLat'] = lastPickupPlace!.latLng!.latitude;
      payload['pickupLng'] = lastPickupPlace!.latLng!.longitude;
    }
    if (lastDropoffPlace?.latLng != null) {
      payload['dropoffLat'] = lastDropoffPlace!.latLng!.latitude;
      payload['dropoffLng'] = lastDropoffPlace!.latLng!.longitude;
    }

    // ✅ ADDED: Also include user location coordinates
    if (userLocation.value != null) {
      payload['userCurrentLocation'] = userLocation.value!.toLatLng();
    }

    Get.toNamed(
      '/ride-booking',
      arguments: payload,
    );
  }

  @override
  void onClose() {
    _debounce?.cancel();
    pickupCtrl.dispose();
    dropCtrl.dispose();
    pickupFocus.dispose();
    dropFocus.dispose();
    super.onClose();
  }
}

// enum ActiveField { pickup, dropoff }
//
// class DropOffController extends GetxController {
//   DropOffController(this.apiKey);
//
//   final String apiKey;
//   late final PlacesService places;
//
//   final pickupCtrl = TextEditingController();
//   final dropCtrl = TextEditingController();
//
//   final pickupFocus = FocusNode();
//   final dropFocus = FocusNode();
//
//   final activeField = ActiveField.dropoff.obs;
//
//   final suggestions = <PlaceSuggestion>[].obs;
//   final isLoading = false.obs;
//   final recent = <PlaceSuggestion>[].obs;
//
//   final stops = <PlaceSuggestion>[].obs; // max 3
//
//   Timer? _debounce;
//
//   /// Keep the last selected PlaceSuggestion (with latLng if available)
//   PlaceSuggestion? lastPickupPlace;
//   PlaceSuggestion? lastDropoffPlace;
//
//   @override
//   void onInit() {
//     super.onInit();
//     places = PlacesService(apiKey);
//
//     final args = Get.arguments as Map?;
//     pickupCtrl.text = args?['pickup'] ?? 'Your Current Location';
//     dropCtrl.text = args?['dropoff'] ?? '';
//
//     // ✅ store pickupLatLng if passed
//     if (args?['pickupLatLng'] != null && args?['pickupLatLng'] is LatLng) {
//       lastPickupPlace = PlaceSuggestion(
//         placeId: 'arg_pickup_${DateTime.now().millisecondsSinceEpoch}',
//         description: pickupCtrl.text,
//         latLng: args!['pickupLatLng'],
//       );
//     }
//
//     if (args?['activeField'] == 'pickup') {
//       activeField.value = ActiveField.pickup;
//       pickupFocus.requestFocus();
//     } else {
//       activeField.value = ActiveField.dropoff;
//       dropFocus.requestFocus();
//     }
//
//     recent.assignAll(StorageService.getRecent());
//
//     pickupCtrl.addListener(() => _onQueryChanged(ActiveField.pickup));
//     dropCtrl.addListener(() => _onQueryChanged(ActiveField.dropoff));
//
//     pickupFocus.addListener(_handleFocusChange);
//     dropFocus.addListener(_handleFocusChange);
//   }
//
//   void _handleFocusChange() {
//     if (!pickupFocus.hasFocus && !dropFocus.hasFocus) {
//       suggestions.clear();
//     }
//   }
//
//   void _onQueryChanged(ActiveField field) {
//     if ((field == ActiveField.pickup && !pickupFocus.hasFocus) ||
//         (field == ActiveField.dropoff && !dropFocus.hasFocus)) {
//       return;
//     }
//
//     final q = field == ActiveField.pickup ? pickupCtrl.text : dropCtrl.text;
//
//     if (_debounce?.isActive ?? false) _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 400), () async {
//       if (q.trim().isEmpty) {
//         suggestions.clear();
//         return;
//       }
//       isLoading.value = true;
//       suggestions.assignAll(await places.autocomplete(q.trim()));
//       isLoading.value = false;
//       activeField.value = field;
//     });
//   }
//
//   Future<void> chooseOnMap() async {
//     final result = await Get.toNamed(
//       '/map-selection',
//       arguments: {
//         'activeField':
//         activeField.value == ActiveField.pickup ? 'pickup' : 'dropoff',
//       },
//     );
//
//     if (result is Map && result['lat'] != null && result['lng'] != null) {
//       final s = PlaceSuggestion(
//         placeId: 'map_${DateTime.now().millisecondsSinceEpoch}',
//         description: result['address'] ?? 'Selected on map',
//         latLng: LatLng(result['lat'], result['lng']),
//       );
//
//       setFieldValue(s);
//     }
//   }
//
//   Future<void> selectSuggestion(PlaceSuggestion s) async {
//     isLoading.value = true;
//
//     //  Get origin from RideHomeController (user’s current position)
//     final rideHome = Get.find<RideHomeController>();
//     final origin = rideHome.currentPosition.value;
//
//     final withLatLng = await places.placeDetails(s, origin: origin);
//     isLoading.value = false;
//
//     if (withLatLng != null) {
//       setFieldValue(withLatLng);
//     }
//
//     suggestions.clear();
//   }
//
//   void setFieldValue(PlaceSuggestion s) {
//     if (activeField.value == ActiveField.pickup) {
//       pickupCtrl.text = s.description;
//       lastPickupPlace = s;
//       dropFocus.requestFocus();
//       activeField.value = ActiveField.dropoff;
//     } else {
//       dropCtrl.text = s.description;
//       lastDropoffPlace = s;
//     }
//
//     StorageService.addRecent(s);
//     recent.assignAll(StorageService.getRecent());
//     suggestions.clear();
//   }
//
//   void toggleField(ActiveField field) {
//     activeField.value = field;
//     if (field == ActiveField.pickup) {
//       pickupFocus.requestFocus();
//     } else {
//       dropFocus.requestFocus();
//     }
//   }
//
//   void addStop() {
//     if (stops.length >= 3) {
//       Get.snackbar('Limit reached', 'You can add up to 3 stops only.');
//       return;
//     }
//     _openStopsManager();
//   }
//
//   void _openStopsManager() {
//     Get.bottomSheet(
//       Obx(
//             () => Container(
//           width: 350,
//           padding: const EdgeInsets.all(20),
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 40,
//                 height: 5,
//                 margin: const EdgeInsets.only(bottom: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade400,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               const Text(
//                 "Manage Stops",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               if (stops.isEmpty)
//                 const Text("No stops added yet",
//                     style: TextStyle(color: Colors.grey)),
//               ...List.generate(
//                 stops.length,
//                     (i) => Card(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     leading: const Icon(Icons.place, color: Colors.blue),
//                     title: Text(stops[i].description),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.redAccent),
//                       onPressed: () => stops.removeAt(i),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               ElevatedButton.icon(
//                 onPressed: () async {
//                   final result = await Get.toNamed(
//                     '/map-selection',
//                     arguments: {'activeField': 'dropoff'},
//                   );
//                   if (result is Map && result['lat'] != null) {
//                     final s = PlaceSuggestion(
//                       placeId: 'stop_${DateTime.now().millisecondsSinceEpoch}',
//                       description: result['address'] ?? 'Stop (map)',
//                       latLng: LatLng(result['lat'], result['lng']),
//                     );
//                     if (stops.length < 3) stops.add(s);
//                   }
//                 },
//                 icon: const Icon(Icons.add_location_alt_outlined),
//                 label: const Text("Add stop from map"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: FColors.secondaryColor,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                 ),
//               ),
//               const SizedBox(height: 8),
//             ],
//           ),
//         ),
//       ),
//       isScrollControlled: true,
//     );
//   }
//
//   // Updated confirmSelection -> pass selected vehicle model and lat/lng (if available)
//   void confirmSelection() {
//     if (pickupCtrl.text.trim().isEmpty || dropCtrl.text.trim().isEmpty) {
//       Get.snackbar('Missing fields', 'Pickup and Drop-off are required.');
//       return;
//     }
//
//     final home = Get.find<RideHomeController>();
//     final selectedVehicleModel = home.selectedVehicle.value;
//
//     // Build payload - include coordinates when available to avoid redundant geocoding
//     final payload = {
//       'pickup': pickupCtrl.text.trim(),
//       'dropoff': dropCtrl.text.trim(),
//       'stops': stops.map((e) => e.toJson()).toList(),
//       'rideType': selectedVehicleModel?.name ?? '',
//       'selectedRideIndex': home.selectedRideIndex.value,
//       'selectedVehicle': selectedVehicleModel != null ? {
//         'id': selectedVehicleModel.id,
//         'name': selectedVehicleModel.name,
//         'fareValue': selectedVehicleModel.fareValue,
//         'description': selectedVehicleModel.description,
//         'iconBase64': selectedVehicleModel.iconBase64,
//         'supportsRideType': selectedVehicleModel.supportsRideType,
//       } : null,
//     };
//
//     // include coordinates if available
//     if (lastPickupPlace?.latLng != null) {
//       payload['pickupLat'] = lastPickupPlace!.latLng!.latitude;
//       payload['pickupLng'] = lastPickupPlace!.latLng!.longitude;
//     }
//     if (lastDropoffPlace?.latLng != null) {
//       payload['dropoffLat'] = lastDropoffPlace!.latLng!.latitude;
//       payload['dropoffLng'] = lastDropoffPlace!.latLng!.longitude;
//     }
//
//     Get.toNamed(
//       '/ride-request',
//       arguments: payload,
//     );
//   }
//
//   @override
//   void onClose() {
//     _debounce?.cancel();
//     pickupCtrl.dispose();
//     dropCtrl.dispose();
//     pickupFocus.dispose();
//     dropFocus.dispose();
//     super.onClose();
//   }
// }
