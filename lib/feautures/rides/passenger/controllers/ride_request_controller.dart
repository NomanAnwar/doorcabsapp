import 'dart:async';
import 'dart:ui' as ui; // ADDED: for resizing marker images
import 'package:doorcab/feautures/rides/passenger/controllers/widgets/ride_request_reuseable_controllers/date_time_controller.dart';
import 'package:doorcab/feautures/rides/passenger/controllers/widgets/ride_request_reuseable_controllers/fare_calculator_controller.dart';
import 'package:doorcab/feautures/rides/passenger/controllers/widgets/ride_request_reuseable_controllers/map_controller.dart';
import 'package:doorcab/feautures/shared/services/pusher_channels.dart';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/services/pusher_beams.dart';
import '../models/services/geocoding_service.dart';
import '../models/services/map_service.dart';
import '../models/vehicle_model.dart';
import 'ride_home_controller.dart';

class RideRequestController extends RideHomeController {
  final MapService _mapService = MapService();
  final GeocodingService _geocodingService = GeocodingService();
  final MapController _mapController = MapController();
  final FareCalculatorController _fareController = FareCalculatorController();
  final DateTimeController _dateTimeController = DateTimeController();

  // Incoming args
  final stops = <Map<String, dynamic>>[].obs;
  final rideType = RxString('');
  final selectedRideIndexFromHome = 0.obs;
  final selectedVehicleData = Rx<Map<String, dynamic>?>(null);

  final List<String> passengerOptions = const ["1", "2", "3", "4", "More"];
  final List<TextInputFormatter> digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  // Loading state
  final isLoading = false.obs;

  // ========== NEW FLAGS (ADDED) ==========
  /// true while route/fare are being calculated (UI should show spinner for ride-type selector)
  final isCalculatingFare = false.obs; // ADDED

  /// true when polyline + pickup + dropoff markers are present on the map
  final mapReady = false.obs; // ADDED

  // ========= marker icon cache (ADDED) ==========
  BitmapDescriptor? _pickupBitmap; // ADDED
  BitmapDescriptor? _dropBitmap; // ADDED
  BitmapDescriptor? _stopBitmap; // ADDED - for intermediate stops (optional)
  bool _loadingIcons = false; // ADDED - guard

  // FIXED: Add completer to ensure icons are loaded before marker placement
  final _iconsLoadedCompleter = Completer<void>();

  TextEditingController get fareController => _fareController.fareController;

  RxString get userCity =>
      _fareController
          .userCity; // CHANGED: keep getter names consistent with your original controllers
  RxString get pickupLocation => _mapController.pickupLocation;

  RxString get dropoffLocation => _mapController.dropoffLocation;

  Rx<Polyline?> get routePolyline => _mapController.routePolyline;

  RxDouble get distanceKm => _mapController.distanceKm;

  RxInt get durationMinutes => _mapController.durationMinutes;

  RxMap<String, double> get vehicleFares => _fareController.vehicleFares;

  RxString get selectedPassengers => _fareController.selectedPassengers;

  RxBool get autoAccept => _fareController.autoAccept;

  RxString get selectedPaymentLabel => _fareController.selectedPaymentLabel;

  Rx<DateTime?> get selectedDate => _dateTimeController.selectedDate;

  Rx<TimeOfDay?> get selectedTime => _dateTimeController.selectedTime;

  RxString get dateLabel => _dateTimeController.dateLabel;

  RxString get timeLabel =>
      _dateTimeController
          .timeLabel; // <--- CAREFUL: keep name consistent with your file

  final PusherBeamsService _pusherBeams = PusherBeamsService();
  final PusherChannelsService _pusherChannels = PusherChannelsService();

  final bids = <Map<String, dynamic>>[].obs;

  // Coordinates for API calls
  LatLng? pickupCoords;
  LatLng? dropoffCoords;
  List<Map<String, dynamic>> stopCoords = [];

  final a = StorageService.getRole();

  // ADDED: prevent overlapping route/fare calculations
  bool _calcInProgress = false; // ADDED

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args is Map) {
      _initializeFromArgs(args);
    }

    // FIXED: Start icon loading immediately when controller initializes
    _preloadMarkerIcons().then((_) {
      _iconsLoadedCompleter.complete();
      print('✅ All marker icons loaded successfully');
    });

    // start in calculating state - UI will show spinner for ride-type until we finish.
    isCalculatingFare.value = true; // ADDED
    mapReady.value = false; // ADDED

    ever(cities, (_) => _initializeData());
    ever(vehicleModels, (_) => _initializeData());

    _dateTimeController.initialize();

    _initializePushNotifications();

    // ADDED: react to route / location updates from mapController to place markers + evaluate readiness
    ever(routePolyline, (_) => _onRoutePolylineUpdated()); // ADDED
    ever(pickupLocation, (_) => _onLocationTextChanged()); // ADDED
    ever(dropoffLocation, (_) => _onLocationTextChanged()); // ADDED
  }

  Future<void> _initializePushNotifications() async {
    // await _pusherBeams.initialize();
    await _pusherBeams.registerDevice();
    // _pusherBeams.configureNotificationHandling();
  }

  // FIXED: New method to preload icons with better error handling
  Future<void> _preloadMarkerIcons() async {
    if (_loadingIcons) return;
    _loadingIcons = true;

    try {
      print('🚀 Preloading marker icons...');

      // Load pickup icon
      final pickupData = await rootBundle.load('assets/images/position_marker.png');
      final pickupCodec = await ui.instantiateImageCodec(
        pickupData.buffer.asUint8List(),
        targetWidth: 120,
      );
      final pickupFrame = await pickupCodec.getNextFrame();
      final pickupBytes = await pickupFrame.image.toByteData(format: ui.ImageByteFormat.png);
      if (pickupBytes != null) {
        _pickupBitmap = BitmapDescriptor.fromBytes(pickupBytes.buffer.asUint8List());
        print('✅ Pickup icon loaded successfully');
      }

      // Load dropoff icon
      final dropoffData = await rootBundle.load('assets/images/place.png');
      final dropoffCodec = await ui.instantiateImageCodec(
        dropoffData.buffer.asUint8List(),
        targetWidth: 100,
      );
      final dropoffFrame = await dropoffCodec.getNextFrame();
      final dropoffBytes = await dropoffFrame.image.toByteData(format: ui.ImageByteFormat.png);
      if (dropoffBytes != null) {
        _dropBitmap = BitmapDescriptor.fromBytes(dropoffBytes.buffer.asUint8List());
        print('✅ Dropoff icon loaded successfully');
      }

      // Load stop icon
      final stopCodec = await ui.instantiateImageCodec(
        dropoffData.buffer.asUint8List(),
        targetWidth: 70,
      );
      final stopFrame = await stopCodec.getNextFrame();
      final stopBytes = await stopFrame.image.toByteData(format: ui.ImageByteFormat.png);
      if (stopBytes != null) {
        _stopBitmap = BitmapDescriptor.fromBytes(stopBytes.buffer.asUint8List());
        print('✅ Stop icon loaded successfully');
      }

    } catch (e) {
      print('❌ Error preloading icons: $e');
      // Set fallbacks
      _pickupBitmap = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      _dropBitmap = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      _stopBitmap = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      print('🔄 Using fallback marker icons');
    } finally {
      _loadingIcons = false;
    }
  }

  void _initializeFromArgs(Map<dynamic, dynamic> args) {
    final stringArgs = args.map(
          (key, value) => MapEntry(key.toString(), value),
    );

    _mapController.initializeFromArgs(stringArgs);
    _fareController.initializeFromArgs(stringArgs);

    rideType.value = (args['rideType'] ?? '').toString();
    selectedRideIndexFromHome.value = args['selectedRideIndex'] ?? 0;

    if (args['selectedVehicle'] is Map) {
      selectedVehicleData.value = Map<String, dynamic>.from(
        args['selectedVehicle'] as Map<dynamic, dynamic>,
      );
    } else {
      selectedVehicleData.value = null;
    }

    stops.clear();
    if (args['stops'] is List) {
      stops.assignAll(
        (args['stops'] as List).map((e) {
          if (e is Map) {
            return Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
          }
          return <String, dynamic>{};
        }).toList(),
      );
    }

    // Store coordinates if provided (unchanged)
    if (args['pickupLat'] != null && args['pickupLng'] != null) {
      pickupCoords = LatLng(
        (args['pickupLat'] as num).toDouble(),
        (args['pickupLng'] as num).toDouble(),
      );
    }
    if (args['dropoffLat'] != null && args['dropoffLng'] != null) {
      dropoffCoords = LatLng(
        (args['dropoffLat'] as num).toDouble(),
        (args['dropoffLng'] as num).toDouble(),
      );
    }
  }

  void _initializeData() {
    if (cities.isEmpty || vehicleModels.isEmpty) return;

    _fareController.initializeVehicleSelection(
      selectedVehicleData.value,
      selectedRideIndexFromHome.value,
      rideTypes,
      vehicleModels,
      cities,
      _vehicleForRideTypeIndex,
    );

    _mapController.determineUserCity(cities, pickupLocation.value);

    // CHANGED: start the route & fare calculation and set calculating flag
    _calculateRouteAndFare(); // CHANGED
  }

  /// Fetch route & calculate fares (FIXED)
  /// Fetch route & calculate fares (FIXED)
  Future<void> _calculateRouteAndFare() async {
    // Avoid overlapping calculations
    if (_calcInProgress) return;
    _calcInProgress = true;
    isCalculatingFare.value = true;
    mapReady.value = false;

    if (pickupLocation.value.isEmpty || dropoffLocation.value.isEmpty) {
      isCalculatingFare.value = false;
      _calcInProgress = false;
      return;
    }

    try {
      print('⏳ Waiting for marker icons to load...');
      await _iconsLoadedCompleter.future;
      print('✅ Icons ready, starting route calculation...');

      final routeDetails = await _mapController.calculateRoute(
        pickupLocation.value,
        dropoffLocation.value,
        _geocodingService,
        stops,
      );

      if (routeDetails != null) {
        // FIXED: Update coordinates from the calculated route
        pickupCoords = _mapController.lastPickupCoords;
        dropoffCoords = _mapController.lastDropoffCoords;

        // FIXED: Better stop coordinate synchronization
        print('🔄 Syncing stop coordinates...');
        for (int i = 0; i < stops.length; i++) {
          if (i < _mapController.stopCoords.length) {
            final stopCoord = _mapController.stopCoords[i];
            stops[i]['lat'] = stopCoord.latitude;
            stops[i]['lng'] = stopCoord.longitude;
            print('📍 Updated stop $i coordinates: $stopCoord');
          } else {
            print('⚠️ No coordinates available for stop $i');
          }
        }

        _fareController.calculateAllFares(
          distanceKm.value,
          durationMinutes.value,
          cities,
          vehicleModels,
          userCity.value,
        );
      }

      // FIXED: Place markers after all coordinates are set
      print('🔄 Placing markers after route calculation...');
      _placePickupDropoffMarkers();

      // FIXED: Small delay to ensure markers are rendered before evaluating
      await Future.delayed(Duration(milliseconds: 100));

      _evaluateMapReady();

      if (_mapController.routePolyline.value != null) {
        _animateCameraToRoute(
          _mapController.routePolyline.value!.points,
          pickupCoords,
          dropoffCoords,
        );
      }
    } catch (e) {
      print('Error calculating route: $e');
    } finally {
      isCalculatingFare.value = false;
      _calcInProgress = false;
    }
  }

  // FIXED: Add method to clear only route-related markers
  void _clearRouteMarkers() {
    markers.removeWhere((m) {
      final id = m.markerId.value;
      return id == 'pickup' || id == 'dropoff' || id.startsWith('stop_');
    });
  }

  // FIXED: Improved route polyline update handler
  void _onRoutePolylineUpdated() async {
    // if route arrived, derive coords if needed and re-place markers + evaluate readiness
    final poly = _mapController.routePolyline.value;
    if (poly != null) {
      try {
        // FIXED: Wait for icons to be loaded first
        await _iconsLoadedCompleter.future;

        if (pickupCoords == null && poly.points.isNotEmpty) {
          pickupCoords = poly.points.first;
        }
        if (dropoffCoords == null && poly.points.length > 1) {
          dropoffCoords = poly.points.last;
        }

        _placePickupDropoffMarkers();
        _evaluateMapReady();
        // Also center camera on route (we may want to animate when poly is updated)
        _animateCameraToRoute(poly.points, pickupCoords, dropoffCoords);
      } catch (e) {
        print('❌ Error in polyline update: $e');
      }
    }
  }

  // ADDED: if the pickup/dropoff text changes, re-run calculation (debounce would be better)
  void _onLocationTextChanged() {
    // If both fields present, attempt recalculation
    if (pickupLocation.value.isNotEmpty &&
        dropoffLocation.value.isNotEmpty &&
        !_calcInProgress) {
      _calculateRouteAndFare();
    }
  }

  // FIXED: Enhanced marker placement with better coordinate handling
  // FIXED: Enhanced marker placement with better coordinate handling
  void _placePickupDropoffMarkers() {
    try {
      print('🎯 Starting marker placement...');
      print('📍 Pickup coords: $pickupCoords');
      print('📍 Dropoff coords: $dropoffCoords');
      print('📍 Stops count: ${stops.length}');

      // DEBUG: Print all stops data
      for (int i = 0; i < stops.length; i++) {
        print('📍 Stop $i: ${stops[i]}');
      }

      // FIXED: Only clear route markers, not all markers
      markers.removeWhere((m) {
        final id = m.markerId.value;
        return id == 'pickup' || id == 'dropoff' || id.startsWith('stop_');
      });

      final List<Marker> newMarkers = [];

      // Add pickup marker
      if (pickupCoords != null) {
        newMarkers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickupCoords!,
            icon: _pickupBitmap ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: pickupLocation.value.isNotEmpty ? pickupLocation.value : 'Pickup',
            ),
            anchor: const Offset(0.5, 0.5),
          ),
        );
        print('📍 Placed pickup marker at $pickupCoords');
      } else {
        print('⚠️ Pickup coordinates are null');
      }

      // FIXED: Add intermediate stops with better validation
      for (int i = 0; i < stops.length; i++) {
        final s = stops[i];
        if (s['lat'] != null && s['lng'] != null) {
          try {
            final pos = LatLng(
              (s['lat'] as num).toDouble(),
              (s['lng'] as num).toDouble(),
            );
            final desc = s['description'] ?? 'Stop ${i + 1}';
            newMarkers.add(
              Marker(
                markerId: MarkerId('stop_$i'),
                position: pos,
                icon: _stopBitmap ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                infoWindow: InfoWindow(title: desc),
                anchor: const Offset(0.5, 0.5),
              ),
            );
            print('📍 Placed stop $i: "$desc" at $pos');
          } catch (e) {
            print('❌ Error creating stop marker $i: $e');
          }
        } else {
          print('⚠️ Stop $i missing coordinates: lat=${s['lat']}, lng=${s['lng']}');
        }
      }

      // Add dropoff marker
      if (dropoffCoords != null) {
        newMarkers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: dropoffCoords!,
            icon: _dropBitmap ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: dropoffLocation.value.isNotEmpty ? dropoffLocation.value : 'Dropoff',
            ),
            anchor: const Offset(0.5, 0.5),
          ),
        );
        print('📍 Placed dropoff marker at $dropoffCoords');
      } else {
        print('⚠️ Dropoff coordinates are null');
      }

      // FIXED: Use assign instead of addAll to ensure markers are properly updated
      markers.addAll(newMarkers);
      print('✅ Successfully placed ${newMarkers.length} markers total');
      print('📍 Total markers on map now: ${markers.length}');

    } catch (e) {
      print('❌ Error placing markers: $e');
    }
  }

  // ADDED: evaluate readiness for request button
  void _evaluateMapReady() {
    final hasPolyline = _mapController.routePolyline.value != null;
    final hasPickup = markers.any((m) => m.markerId.value == 'pickup');
    final hasDrop = markers.any((m) => m.markerId.value == 'dropoff');

    mapReady.value = hasPolyline && hasPickup && hasDrop;
    print('🗺️ Map ready status - Polyline: $hasPolyline, Pickup: $hasPickup, Dropoff: $hasDrop, Overall: $mapReady');
  }

  VehicleModel? _vehicleForRideTypeIndex(int index) {
    return _fareController.vehicleForRideTypeIndex(
      index,
      rideTypes,
      vehicleModels,
    );
  }

  @override
  void onSelectRide(int index) {
    super.onSelectRide(index);
    _fareController.updateSelectedRide(
      index,
      rideTypes,
      vehicleModels,
      _vehicleForRideTypeIndex,
    );
  }

  String fareForCard(int i) {
    return _fareController.fareForCard(
      i,
      selectedRideIndex.value,
      distanceKm.value,
      durationMinutes.value,
      cities,
      rideTypes,
      vehicleModels,
      _vehicleForRideTypeIndex,
    );
  }

  void incrementFare() => _fareController.incrementFare();

  void decrementFare() => _fareController.decrementFare();

  // In RideRequestController - update the onRequestRide method (CHANGED)
  @override
  Future<void> onRequestRide() async {
    if (pickupLocation.value.isEmpty || dropoffLocation.value.isEmpty) {
      Get.snackbar('Missing fields', 'Pickup and Drop-off are required.');
      return;
    }

    if (pickupCoords == null || dropoffCoords == null) {
      Get.snackbar('Error', 'Could not determine coordinates for locations.');
      return;
    }

    // ADDED: ensure map and fare calculation are ready before requesting
    if (!mapReady.value || isCalculatingFare.value) {
      Get.snackbar('Please wait', 'Route and fare are being prepared.');
      return;
    }

    isLoading.value = true;

    try {
      final requestBody = await _prepareRideRequestBody();
      final token = StorageService.getAuthToken();

      if (token == null) {
        Get.snackbar("Error", "User token not found. Please login again.");
        isLoading.value = false;
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);

      final response = await FHttpHelper.post('ride/request', requestBody);
      print("Ride Request API Response : " + response.toString());

      if (response['message'] == 'Ride requested successfully.') {
        final rideData = response;
        final rideId = rideData['rideId'];

        await _sendPushNotificationToDrivers(rideData);
        Get.snackbar('Success', 'Ride requested successfully!');

        // ✅ Subscribe passenger to pusher channel for bids
        final passengerId = StorageService.getSignUpResponse()!.userId;
        if (passengerId != null) {

          // ✅ NEW: Passenger subscribes after init
          // await _pusherChannels.initialize();

          await _pusherChannels.subscribe(
            "passenger-$passengerId",
            events: {
              "new-bid": (data) {
                print("📨 Passenger received new bid: $data");
                try {
                  bids.add(data);
                } catch (e) {
                  print("❌ Error storing bid: $e");
                }
              },
              "nearby-drivers": (data) {
                print("🗺️ Nearby drivers update: $data");

              },
            },
          );
        }

        Get.toNamed(
          '/available-drivers',
          arguments: {
            'rideId': rideId,
            'rideData': rideData,
            'pickup': {
              "lat": pickupCoords?.latitude,
              "lng": pickupCoords?.longitude,
              "address": pickupLocation.value,
            },
            'dropoffs': await _getNotification_dropoffs(),
            // includes main + stops with order
            'rideType': selectedVehicle.value?.name ?? rideType.value,
            'fare': fareController.text,
            'passengers': selectedPassengers.value,
            'payment': selectedPaymentLabel.value,
            'pickupLat': pickupCoords?.latitude,
            'pickupLng': pickupCoords?.longitude,
            'bids': bids,
            // RxList, updates in real-time
          },
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to request ride');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to request ride: ${e.toString()}');
      print(' Ride request error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> _prepareRideRequestBody() async {
    // Get coordinates for all stops
    final dropoffs = await _getStopCoordinates();

    // Get fare breakdown (you might need to calculate this based on your fare logic)
    final fareBreakdown = _calculateFare_breakdown();
    print("User City : "+userCity.value);

    return {
      "pickup_lat": pickupCoords!.latitude,
      "pickup_lng": pickupCoords!.longitude,
      "ride_city": "Lahore",
      // "ride_city": userCity.value,
      "dropoffs": dropoffs,
      "distance": distanceKm.value,
      "vehicle_type": selectedVehicle.value?.name ?? rideType.value,
      "requested_rideFare": double.parse(fareController.text),
      "fare": fareBreakdown,
      "payment_type": selectedPaymentLabel.value.toLowerCase(),
      "passengers_no": selectedPassengers.value,
      "request_datetime":
      selectedDate.value != null && selectedTime.value != null
          ? _formatDateTime(selectedDate.value!, selectedTime.value!)
          : DateTime.now().toIso8601String(),
    };
  }
  Future<void> _sendPushNotificationToDrivers(
      Map<String, dynamic> rideData,
      ) async
  {
    try {
      final notificationBody = {
        "rideId": rideData['rideId'],
        "pickup": {
          "lat": pickupCoords!.latitude,
          "lng": pickupCoords!.longitude,
          "address": pickupLocation.value,
        },
        "dropoffs": await _getNotification_dropoffs(),
        "amount": double.parse(fareController.text),
      };

      // Call the push notification endpoint
      await FHttpHelper.post('ride/push-notification', notificationBody);

      print(' Push notification sent to drivers');
    } catch (e) {
      print(' Error sending push notification: $e');
      // Don't throw error here - ride request was successful, just notification failed
    }
  }


  Future<List<Map<String, dynamic>>> _getStopCoordinates() async {
    final List<Map<String, dynamic>> dropoffs = [];

    // Add main dropoff
    if (dropoffCoords != null) {
      dropoffs.add({
        "lat": dropoffCoords!.latitude,
        "lng": dropoffCoords!.longitude,
        "stop_order": 1,
      });
    }

    // Add additional stops if any
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      if (stop['lat'] != null && stop['lng'] != null) {
        dropoffs.add({
          "lat": (stop['lat'] as num).toDouble(),
          "lng": (stop['lng'] as num).toDouble(),
          "stop_order": i + 2, // +2 because main dropoff is order 1
        });
      }
    }

    return dropoffs;
  }

  Map<String, dynamic> _calculateFare_breakdown() {
    // This should be implemented based on your fare calculation logic
    // For now, using simplified breakdown
    final totalFare = double.parse(fareController.text);

    return {
      "baseFare": totalFare * 0.4, // 40% base fare
      "distanceCharges": totalFare * 0.5, // 50% distance charges
      "surgeCharges": totalFare * 0.1, // 10% surge charges
      "discount": 0,
      "waiting_charge_amount": 0,
    };
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return dateTime.toIso8601String();
  }

  Future<List<Map<String, dynamic>>> _getNotification_dropoffs() async {
    final List<Map<String, dynamic>> dropoffs = [];

    // Add main dropoff
    if (dropoffCoords != null) {
      dropoffs.add({
        "lat": dropoffCoords!.latitude,
        "lng": dropoffCoords!.longitude,
        "stop_order": 1,
        "address": dropoffLocation.value,
      });
    }

    // Add additional stops
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      if (stop['lat'] != null && stop['lng'] != null) {
        dropoffs.add({
          "lat": (stop['lat'] as num).toDouble(),
          "lng": (stop['lng'] as num).toDouble(),
          "stop_order": i + 2,
          "address": stop['description'] ?? 'Stop ${i + 2}',
        });
      }
    }

    return dropoffs;
  }

  void openDateTimePopup() => _dateTimeController.openDateTimePopup();

  void openPaymentMethods() => _fareController.openPaymentMethods();

  void openComments() => _fareController.openComments();

  @override
  void onClose() {
    _fareController.dispose();
    super.onClose();
  }

  // ========== ADDED HELPER: animate camera to route bounds ==========
  Future<void> _animateCameraToRoute(
      List<LatLng>? pts,
      LatLng? pickup,
      LatLng? dropoff,
      ) async
  {
    if (pts == null || pts.isEmpty) {
      // fallback — if no polyline points use pickup/drop
      if (pickup == null && dropoff == null) return;
      final swLat =
      pickup == null
          ? dropoff!.latitude
          : (dropoff == null
          ? pickup.latitude
          : (pickup.latitude < dropoff.latitude
          ? pickup.latitude
          : dropoff.latitude));
      final swLng =
      pickup == null
          ? dropoff!.longitude
          : (dropoff == null
          ? pickup.longitude
          : (pickup.longitude < dropoff.longitude
          ? pickup.longitude
          : dropoff.longitude));
      final neLat =
      pickup == null
          ? dropoff!.latitude
          : (dropoff == null
          ? pickup.latitude
          : (pickup.latitude > dropoff.latitude
          ? pickup.latitude
          : dropoff.latitude));
      final neLng =
      pickup == null
          ? dropoff!.longitude
          : (dropoff == null
          ? pickup.longitude
          : (pickup.longitude > dropoff.longitude
          ? pickup.longitude
          : dropoff.longitude));
      final bounds = LatLngBounds(
        southwest: LatLng(swLat, swLng),
        northeast: LatLng(neLat, neLng),
      );
      if (mapController.isCompleted) {
        final ctrl = await mapController.future;
        try {
          ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        } catch (e) {
          print('Error animating camera fallback: $e');
        }
      }
      return;
    }

    try {
      double minLat = pts.first.latitude, minLng = pts.first.longitude;
      double maxLat = pts.first.latitude, maxLng = pts.first.longitude;
      for (final p in pts) {
        minLat = p.latitude < minLat ? p.latitude : minLat;
        minLng = p.longitude < minLng ? p.longitude : minLng;
        maxLat = p.latitude > maxLat ? p.latitude : maxLat;
        maxLng = p.longitude > maxLng ? p.longitude : maxLng;
      }
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      if (mapController.isCompleted) {
        final ctrl = await mapController.future;
        try {
          ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        } catch (e) {
          // sometimes animateCamera with bounds throws if map not ready; ignore gracefully
          print('Error animating camera to route: $e');
        }
      }
    } catch (e) {
      print('Error computing/animating camera to route: $e');
    }
  }

  // FIXED: Add debug method to help identify issues
  void debugCurrentState()
  {
    print('=== DEBUG CURRENT STATE ===');
    print('📍 Pickup: ${pickupLocation.value}');
    print('📍 Dropoff: ${dropoffLocation.value}');
    print('📍 Pickup Coords: $pickupCoords');
    print('📍 Dropoff Coords: $dropoffCoords');
    print('📍 Stops: ${stops.length}');
    print('📍 Route Polyline: ${routePolyline.value != null ? "Exists" : "Null"}');
    print('📍 Markers count: ${markers.length}');
    print('📍 Map Ready: ${mapReady.value}');
    print('📍 Calculating Fare: ${isCalculatingFare.value}');
    print('===========================');
  }
}