import 'dart:async';
import 'package:doorcab/utils/constants/image_strings.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/storage_service.dart';
import '../../shared/models/place_suggestion.dart';

class RideType {
  final String title;
  final String image;
  RideType(this.title, this.image);
}

class RideHomeController extends GetxController {
  final mapController = Completer<GoogleMapController>();
  final currentPosition = Rx<LatLng?>(null);
  final markers = <Marker>{}.obs;

  final rideTypes = <RideType>[
    RideType("Bike", FImages.bike),
    RideType("Rickshaw", FImages.rickshaw),
    RideType("Car", FImages.ride_ac),
    RideType("Mini", FImages.ride_mini),
    RideType("City-To-City", FImages.city_to_city),
  ].obs;

  final selectedRideIndex = 0.obs;

  final pickupText = RxString('');
  final dropoffText = RxString('');

  /// Shared recent searches from StorageService (not in-memory custom class)
  final recent = <PlaceSuggestion>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initLoc();
    _loadRecents();
  }

  void _loadRecents() {
    recent.assignAll(StorageService.getRecent());
  }

  Future<void> _initLoc() async {
    final pos = await LocationService.currentPosition();
    if (pos != null) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      currentPosition.value = latLng;
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: latLng,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
      final controller = await mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      pickupText.value = "Your Current Location";
    }
  }

  void onMapCreated(GoogleMapController c) {
    if (!mapController.isCompleted) mapController.complete(c);
  }

  void onSelectRide(int index) {
    selectedRideIndex.value = index;
  }

  Future<void> openDropoff() async {
    final result = await Get.toNamed('/dropoff', arguments: {
      'pickup': pickupText.value,
      'dropoff': dropoffText.value,
    });

    if (result is Map) {
      pickupText.value  = result['pickup']  ?? pickupText.value;
      dropoffText.value = result['dropoff'] ?? dropoffText.value;

      /// reload shared recents (DropOff screen has saved them)
      _loadRecents();
    }
  }

  void onTapPickup() async {
    final result = await Get.toNamed('/dropoff', arguments: {
      'activeField': 'pickup',
      'pickup': pickupText.value,
      'dropoff': dropoffText.value,
    });

    if (result is Map) {
      pickupText.value  = result['pickup']  ?? pickupText.value;
      dropoffText.value = result['dropoff'] ?? dropoffText.value;
      _loadRecents();
    }
  }

  void selectRecent(PlaceSuggestion s) {
    dropoffText.value = s.description;
  }
}
