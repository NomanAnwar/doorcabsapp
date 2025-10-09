import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui; // ✅ for resizing marker
import 'package:doorcab/utils/constants/image_strings.dart';
import 'package:flutter/services.dart'; // ✅ for rootBundle
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../../utils/http/http_client.dart';
import '../../../shared/models/place_suggestion.dart';
import '../../../shared/services/storage_service.dart';
import '../models/city_model.dart';
import '../models/ride_type_model.dart';
import '../models/vehicle_model.dart';

class RideHomeController extends GetxController {
  final mapController = Completer<GoogleMapController>();
  final currentPosition = Rx<LatLng?>(null);
  final markers = <Marker>{}.obs;

  /// Ride types shown in the UI (these are the simplified UI items)
  final rideTypes = <RideTypeModel>[].obs;

  /// Full vehicle models returned from API (contains fareValue etc.)
  final vehicleModels = <VehicleModel>[].obs;

  final selectedRideIndex = 0.obs;

  /// Selected vehicle model (full data) — kept in sync with selectedRideIndex
  final selectedVehicle = Rxn<VehicleModel>();

  final cities = <CityModel>[].obs;
  final isLoadingCities = true.obs;

  final pickupText = RxString('');
  final dropoffText = RxString('');
  final recent = <PlaceSuggestion>[].obs;

  final isLoadingLocation = true.obs;

  /// Loading state for ride types API
  final isLoadingRideTypes = true.obs;

  /// Fix: prevent repeated camera animation snaps
  bool _cameraMovedOnce = false;

  final String mapsApiKey = const String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4',
  );

  @override
  void onInit() {
    super.onInit();
    _initLoc();
    _loadRecents();

    _loadCachedRideTypesFirst(); // 1) show cached instantly if available
    _fetchRideTypes(); // 2) fetch fresh in background

    _loadCachedCitiesFirst(); // Load cached first
    _fetchCities(); // Fetch fresh in background
  }

  void _loadRecents() {
    recent.assignAll(StorageService.getRecent());
  }

  Future<void> _initLoc() async {
    try {
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
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      currentPosition.value = latLng;

      final address = await _getAddressFromLatLng(pos.latitude, pos.longitude);
      pickupText.value = address ?? "Your Current Location";

      // ✅ Fix: clear old markers before adding a fresh one
      markers.clear();

      final customIcon = await _getResizedMarker(
        "assets/images/position_marker.png",
        120,
      );

      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: latLng,
          icon: customIcon,
          infoWindow: InfoWindow(title: address ?? 'Your Location'),
        ),
      );

      // Animate camera when map controller is ready; only do it once to avoid snapping when user moves map
      mapController.future.then((controller) {
        try {
          if (!_cameraMovedOnce) {
            controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
            _cameraMovedOnce = true;
          }
        } catch (_) {}
      });

      isLoadingLocation.value = false;
    } catch (e) {
      print('Error initializing location: $e');
      pickupText.value = "Unable to fetch location"; // ✅ UX fallback
      isLoadingLocation.value = false;
    }
  }

  /// Helper that loads an asset image, resizes it, and returns a BitmapDescriptor
  /// so marker size actually affects how it looks on the map.
  Future<BitmapDescriptor> _getResizedMarker(String assetPath, int targetWidth) async {
    final ByteData data = await rootBundle.load(assetPath);
    // instantiate codec with targetWidth so the image is scaled
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetWidth,
    );
    final frameInfo = await codec.getNextFrame();
    final byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<String?> _getAddressFromLatLng(double lat, double lng) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$mapsApiKey";
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data["status"] == "OK" && (data["results"] as List).isNotEmpty) {
        return data["results"][0]["formatted_address"];
      }
    } catch (e) {
      print('Error reverse-geocoding: $e');
    }
    return null;
  }

  void onMapCreated(GoogleMapController c) {
    if (!mapController.isCompleted) mapController.complete(c);
  }

  void onSelectRide(int index) {
    selectedRideIndex.value = index;

    // Keep selectedVehicle in sync (if vehicleModels available)
    if (index >= 0 && index < vehicleModels.length) {
      selectedVehicle.value = vehicleModels[index];
    } else {
      selectedVehicle.value = null;
    }
  }

  Future<void> openDropoff() async {
    final result = await Get.toNamed(
      '/dropoff',
      arguments: {'pickup': pickupText.value, 'pickupLatLng': currentPosition.value, 'dropoff': dropoffText.value},
    );
    if (result is Map) {
      pickupText.value = result['pickup'] ?? pickupText.value;
      dropoffText.value = result['dropoff'] ?? dropoffText.value;

      if (result['pickupLatLng'] is LatLng) {
        currentPosition.value = result['pickupLatLng'];
      }

      _loadRecents();
    }
  }

  void onTapPickup() async {
    final result = await Get.toNamed(
      '/dropoff',
      arguments: {
        'activeField': 'pickup',
        'pickup': pickupText.value,
        'pickupLatLng': currentPosition.value,
        'dropoff': dropoffText.value,
      },
    );
    if (result is Map) {
      pickupText.value = result['pickup'] ?? pickupText.value;
      dropoffText.value = result['dropoff'] ?? dropoffText.value;

      // ✅ also update LatLng if returned
      if (result['pickupLatLng'] is LatLng) {
        currentPosition.value = result['pickupLatLng'];
      }

      _loadRecents();
    }
  }


  void selectRecent(PlaceSuggestion s) async {
    final result = await Get.toNamed(
      '/dropoff',
      arguments: {'pickup': pickupText.value, 'pickupLatLng': currentPosition.value, 'dropoff': s.description},
    );


    if (result is Map) {
      pickupText.value = result['pickup'] ?? pickupText.value;
      dropoffText.value = result['dropoff'] ?? dropoffText.value;

      if (result['pickupLatLng'] is LatLng) {
        currentPosition.value = result['pickupLatLng'];
      }

      _loadRecents();
    }
  }

  // ========= Ride Types (Cache + API) =========

  /// 1) Load cached ride types immediately (if any) to show something quickly
  void _loadCachedRideTypesFirst() {
    final cached = StorageService.getRideTypesCache();
    if (cached.isNotEmpty) {
      final cachedRideTypes =
      cached.map((m) {
        final name = (m['name'] ?? '').toString();
        final icon = (m['iconBase64'] ?? '').toString();
        return RideTypeModel(
          name,
          icon.isNotEmpty ? icon : FImages.ride_ac,
          isBase64: icon.isNotEmpty,
        );
      }).toList();

      rideTypes.assignAll(cachedRideTypes);

      // Keep selection logic same
      selectedRideIndex.value = 0;
      // selectedVehicle will be set when vehicleModels are loaded from API
      selectedVehicle.value = null;
    }
  }

  /// 2) Fetch from API, compare to cache, update if changed
  Future<void> _fetchRideTypes() async {
    // show spinner only if we have nothing to display yet
    if (rideTypes.isEmpty) isLoadingRideTypes.value = true;

    try {
      final res = await FHttpHelper.get("vehicle/list");
      final data = (res["data"] is List) ? (res["data"] as List) : const [];
      print("Vehicle API Response : " + res.toString());

      // Convert API data -> VehicleModel list
      final vehicles = data.map((e) {
        try {
          return VehicleModel.fromJson(e as Map<String, dynamic>);
        } catch (err) {
          print('Vehicle parsing error: $err');
          return VehicleModel(
            id: '',
            name: (e is Map && e['category_name'] != null) ? e['category_name'].toString() : '',
            fareValue: (e is Map && e['fare_value'] != null) ? (double.tryParse(e['fare_value'].toString()) ?? 0.0) : 0.0,
            description: (e is Map && e['category_description'] != null) ? e['category_description'].toString() : '',
            iconBase64: (e is Map && e['category_icon'] != null) ? e['category_icon'].toString() : '',
            supportsRideType: (e is Map && e['supports_ride_type'] is List) ? List<String>.from(e['supports_ride_type']) : [],
          );
        }
      }).toList();

      // Save full vehicle models into observable for later fare calculations
      vehicleModels.assignAll(vehicles);

      // Convert to simplified map list for caching & comparison
      final apiSimple =
      vehicles
          .map((v) => {"name": v.name, "iconBase64": v.iconBase64})
          .toList();

      // Normalize lists for comparison (sort by name)
      String _norm(List<Map<String, dynamic>> list) {
        final copy =
        list
            .map(
              (m) => {
            "name": (m["name"] ?? "").toString(),
            "iconBase64": (m["iconBase64"] ?? "").toString(),
          },
        )
            .toList();
        copy.sort(
              (a, b) => (a["name"] as String).compareTo(b["name"] as String),
        );
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

        final newRideTypes =
        apiSimple.map((m) {
          final name = (m['name'] ?? '').toString();
          final icon = (m['iconBase64'] ?? '').toString();
          return RideTypeModel(
            name,
            icon.isNotEmpty ? icon : FImages.ride_ac,
            isBase64: icon.isNotEmpty,
            // fareValue will be taken from vehicleModels during fare calculation
          );
        }).toList();

        rideTypes.assignAll(newRideTypes);

        // Keep selection logic same
        if (rideTypes.isNotEmpty) {
          selectedRideIndex.value = 0;
          selectedVehicle.value = vehicleModels.isNotEmpty ? vehicleModels[0] : null;
        } else {
          selectedVehicle.value = null;
        }
      } else {
        // No change: keep what's already shown (cached)
        // but ensure selectedVehicle is set if not yet
        if (selectedVehicle.value == null && vehicleModels.isNotEmpty) {
          selectedVehicle.value = vehicleModels.length > selectedRideIndex.value
              ? vehicleModels[selectedRideIndex.value]
              : vehicleModels.first;
        }
      }
    } catch (e) {
      // On error, do not show static fallback and do not clear UI.
      // Just keep whatever is currently displayed (cached or nothing).
      print("Error fetching ride types: $e");
    } finally {
      isLoadingRideTypes.value = false;
    }
  }

  /// 1) Load cached cities immediately (if any)
  void _loadCachedCitiesFirst() {
    final cached = StorageService.getCitiesCache();
    if (cached.isNotEmpty) {
      final cachedCities = cached.map((m) => CityModel.fromJson(m)).toList();
      cities.assignAll(cachedCities);
    }
  }

  /// 2) Fetch from API and compare with cache
  Future<void> _fetchCities() async {
    if (cities.isEmpty) isLoadingCities.value = true;

    try {
      final res = await FHttpHelper.get("city/list-cities");
      final data = (res["data"] is List) ? (res["data"] as List) : const [];

      final apiCities = data.map((e) => CityModel.fromJson(e)).toList();

      print("Cities API Response : " + res.toString());

      // Normalize for comparison
      String _norm(List<Map<String, dynamic>> list) {
        final copy =
        list
            .map(
              (m) => {
            "city_name": (m["city_name"] ?? "").toString(),
            "base_fare": m["base_fare"] ?? 0,
          },
        )
            .toList();
        copy.sort(
              (a, b) =>
              (a["city_name"] as String).compareTo(b["city_name"] as String),
        );
        return jsonEncode(copy);
      }

      final cached = StorageService.getCitiesCache();
      final changed = _norm(data.cast<Map<String, dynamic>>()) != _norm(cached);

      if (apiCities.isNotEmpty && changed) {
        await StorageService.saveCitiesCache(data.cast<Map<String, dynamic>>());
        cities.assignAll(apiCities);
      }
    } catch (e) {
      print("Error fetching cities: $e");
    } finally {
      isLoadingCities.value = false;
    }
  }

  @override
  void onClose() {
    // nothing to dispose specifically here (controllers / streams etc.)
    super.onClose();
  }
}
