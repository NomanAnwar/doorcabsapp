import 'dart:async';
import 'dart:convert';
import 'package:doorcab/utils/constants/image_strings.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;


import '../../../../utils/http/http_client.dart';
import '../../../shared/models/place_suggestion.dart';
import '../../../shared/services/storage_service.dart';
import '../models/ride_type.dart';
import '../models/vehicle_model.dart';

class RideHomeController extends GetxController {
  final mapController = Completer<GoogleMapController>();
  final currentPosition = Rx<LatLng?>(null);
  final markers = <Marker>{}.obs;

  /// Ride types shown in the UI
  final rideTypes = <RideType>[].obs;

  final selectedRideIndex = 0.obs;
  final selectedRideType = Rx<RideType?>(null);

  final pickupText = RxString('');
  final dropoffText = RxString('');
  final recent = <PlaceSuggestion>[].obs;

  final isLoadingLocation = true.obs;

  /// ✅ New: loading state for ride types API
  final isLoadingRideTypes = true.obs;

  final String mapsApiKey = const String.fromEnvironment('MAPS_API_KEY',
      defaultValue: 'AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4');

  @override
  void onInit() {
    super.onInit();
    _initLoc();
    _loadRecents();

    _loadCachedRideTypesFirst(); // 1) show cached instantly if available
    _fetchRideTypes();           // 2) fetch fresh in background
  }

  void _loadRecents() {
    recent.assignAll(StorageService.getRecent());
  }

  Future<void> _initLoc() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        pickupText.value = "Location permission denied";
        isLoadingLocation.value = false;
        return;
      }
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      pickupText.value = "Enable Location Services";
      isLoadingLocation.value = false;
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    final latLng = LatLng(pos.latitude, pos.longitude);
    currentPosition.value = latLng;

    final address = await _getAddressFromLatLng(pos.latitude, pos.longitude);
    pickupText.value = address ?? "Your Current Location";

    markers.add(
      Marker(
        markerId: const MarkerId('me'),
        position: latLng,
        infoWindow: InfoWindow(title: address ?? 'Your Location'),
      ),
    );

    final controller = await mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    isLoadingLocation.value = false;
  }

  Future<String?> _getAddressFromLatLng(double lat, double lng) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$mapsApiKey";
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    if (data["status"] == "OK" && data["results"].isNotEmpty) {
      return data["results"][0]["formatted_address"];
    }
    return null;
  }

  void onMapCreated(GoogleMapController c) {
    if (!mapController.isCompleted) mapController.complete(c);
  }

  void onSelectRide(int index) {
    selectedRideIndex.value = index;
    selectedRideType.value = rideTypes[index];
  }

  Future<void> openDropoff() async {
    final result = await Get.toNamed('/dropoff', arguments: {
      'pickup': pickupText.value,
      'dropoff': dropoffText.value,
    });
    if (result is Map) {
      pickupText.value = result['pickup'] ?? pickupText.value;
      dropoffText.value = result['dropoff'] ?? dropoffText.value;
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
      pickupText.value = result['pickup'] ?? pickupText.value;
      dropoffText.value = result['dropoff'] ?? dropoffText.value;
      _loadRecents();
    }
  }

  void selectRecent(PlaceSuggestion s) async {
    final result = await Get.toNamed('/dropoff', arguments: {
      'pickup': pickupText.value,
      'dropoff': s.description,
    });

    if (result is Map) {
      pickupText.value = result['pickup'] ?? pickupText.value;
      dropoffText.value = result['dropoff'] ?? dropoffText.value;
      _loadRecents();
    }
  }

  // ========= Ride Types (Cache + API) =========

  /// 1) Load cached ride types immediately (if any) to show something quickly
  void _loadCachedRideTypesFirst() {
    final cached = StorageService.getRideTypesCache();
    if (cached.isNotEmpty) {
      final cachedRideTypes = cached.map((m) {
        final name = (m['name'] ?? '').toString();
        final icon = (m['iconBase64'] ?? '').toString();
        return RideType(
          name,
          icon.isNotEmpty ? icon : FImages.ride_ac,
          isBase64: icon.isNotEmpty,
        );
      }).toList();

      rideTypes.assignAll(cachedRideTypes);

      // Keep selection logic same
      selectedRideIndex.value = 0;
      selectedRideType.value = rideTypes.isNotEmpty ? rideTypes[0] : null;
    }
  }

  /// 2) Fetch from API, compare to cache, update if changed
  Future<void> _fetchRideTypes() async {
    // show spinner only if we have nothing to display yet
    if (rideTypes.isEmpty) isLoadingRideTypes.value = true;

    try {
      final res = await FHttpHelper.get("vehicle/list");
      // Expecting res["data"] to be List
      final data = (res["data"] is List) ? (res["data"] as List) : const [];
      print("Vehicle API Response : "+res.toString());

      // Convert API data -> VehicleModel list
      final vehicles =
      data.map((e) => VehicleModel.fromJson(e)).toList();

      // Convert to simplified map list for caching & comparison
      final apiSimple = vehicles
          .map((v) => {
        "name": v.name,
        "iconBase64": v.iconBase64,
      })
          .toList();

      // Normalize lists for comparison (sort by name)
      String _norm(List<Map<String, dynamic>> list) {
        final copy = list
            .map((m) => {
          "name": (m["name"] ?? "").toString(),
          "iconBase64": (m["iconBase64"] ?? "").toString(),
        })
            .toList();
        copy.sort((a, b) => (a["name"] as String).compareTo(b["name"] as String));
        return jsonEncode(copy);
      }

      final cached = StorageService.getRideTypesCache();
      final changed = _norm(apiSimple) != _norm(cached);

      // If API returned nothing/invalid, do NOT clear current UI; just stop loading.
      if (apiSimple.isEmpty) {
        // nothing to show from server → keep whatever is on screen (cached or empty)
        return;
      }

      // If changed, update cache and UI immediately
      if (changed) {
        await StorageService.saveRideTypesCache(apiSimple);

        final newRideTypes = apiSimple.map((m) {
          final name = (m['name'] ?? '').toString();
          final icon = (m['iconBase64'] ?? '').toString();
          return RideType(
            name,
            icon.isNotEmpty ? icon : FImages.ride_ac,
            isBase64: icon.isNotEmpty,
          );
        }).toList();

        rideTypes.assignAll(newRideTypes);

        // Keep selection logic same
        if (rideTypes.isNotEmpty) {
          selectedRideIndex.value = 0;
          selectedRideType.value = rideTypes[0];
        } else {
          selectedRideType.value = null;
        }
      } else {
        // No change: keep what's already shown (cached)
      }
    } catch (e) {
      // On error, do not show static fallback and do not clear UI.
      // Just keep whatever is currently displayed (cached or nothing).
      print("Error fetching ride types: $e");
    } finally {
      isLoadingRideTypes.value = false;
    }
  }
}
