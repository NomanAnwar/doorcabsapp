import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:doorcab/feautures/rides/passenger/controllers/dropoff_controller.dart';
import 'package:doorcab/feautures/rides/passenger/controllers/ride_booking_controller.dart';
import 'package:doorcab/feautures/rides/passenger/controllers/ride_type_controller.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../../utils/http/http_client.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';
import '../../../shared/services/pusher_background_service.dart';
import '../../../shared/services/storage_service.dart';
import '../models/driver_ride_info.dart';
import '../screens/ride_type_screen.dart';
import 'available_bids_controller.dart';
import 'available_drivers_controller.dart';

class DriversWaitingController extends BaseController {
  // PUBLIC OBSERVABLES / CONTROLLERS FOR UI
  final currentPosition = Rxn<LatLng>();
  final driverMarkers = <String, Marker>{}.obs;
  final polylines = <Polyline>{}.obs;
  final fareController = TextEditingController();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // INTERNAL
  GoogleMapController? _mapController;
  Timer? _waitingTimer;

  final rideStarted = false.obs;
  final RxBool updateView = false.obs;
  var thisRideId;

  String? _rideId;
  String? _driverId;

  String? get rideId => _rideId;

  String? get driverId => _driverId;

  set rideId(String? id) => _rideId = id;

  set driverId(String? id) => _driverId = id;

  final rideInfo = Rxn<DriverRideInfo>();
  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
  late final Map<String, dynamic> rideArgs;
  final isCancelling = false.obs;

  // ✅ NEW: Other active rides from API
  final otherActiveRides = <Map<String, dynamic>>[].obs;
  final isLoadingOtherRides = false.obs;

  // Animation / camera control
  LatLng? _lastDriverPosition;
  bool _isCameraFollowing = true;
  bool _isAnimating = false;
  Timer? _animationTimer;
  bool _userMovedCamera = false;
  double? _lastUserZoom;

  // Icons
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _stopIcon;
  BitmapDescriptor? _dropIcon;

  // Route cache for progressive trimming
  List<LatLng> _currentRoute = [];

  // Directions API key
  static const String _googleDirectionsApiKey = "AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4";


  @override
  void onInit() async {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    rideArgs = Map<String, dynamic>.from(Get.arguments ?? {});
    print("📌 Ride args in Drivers Waiting Controller: ${rideArgs['rideType']}");
    print("📌 Ride args in Drivers Waiting Controller: ${rideArgs['status']}");

    if (args.isNotEmpty) {
      print("📦 Args received: $args");
      final bid = args['bid'] as Map<String, dynamic>?;
      rideInfo.value = DriverRideInfo.fromArgs({...args, ...?bid});
      rideId = args['rideId']?.toString();
      driverId = bid?['driver']?['id']?.toString();
      print("Driver id: $driverId");
    }

    thisRideId = rideInfo.value?.rideId;

    await _loadMarkerIcons();
    _placeStaticMarkersFromRideInfo();

    // ✅ NEW: Load other active rides from API
    _loadOtherActiveRidesFromApi();

    if (rideInfo.value?.pickup != null) {
      currentPosition.value = LatLng(
        (rideInfo.value!.pickup!['lat'] as num).toDouble(),
        (rideInfo.value!.pickup!['lng'] as num).toDouble(),
      );

      _updateDriverMarker(currentPosition.value!);
      _lastDriverPosition = currentPosition.value;
    } else {
      currentPosition.value = const LatLng(31.5204, 74.3587);
      _lastDriverPosition = currentPosition.value;
    }

    if (rideInfo.value != null && (rideInfo.value!.rideId?.isNotEmpty ?? false)) {
      _subscribeToDriverLocation(rideInfo.value!.rideId!);
    }
    _startBackgroundService();
  }

  // ✅ NEW: Load other active rides from API
  Future<void> _loadOtherActiveRidesFromApi() async {
    try {
      isLoadingOtherRides(true);
      print('🔄 Fetching other active rides from API...');

      final response = await FHttpHelper.post('passenger/active-rides', {});

      print('📦 Other active rides API response: $response');

      if (response['success'] == true) {
        final hasActiveRide = response['hasActiveRide'] == true;

        if (hasActiveRide) {
          final rideData = Map<String, dynamic>.from(response);
          final currentRideId = this.rideId;

          // If this is the same ride, don't add it to other rides
          if (rideData['rideId'] != currentRideId) {
            otherActiveRides.assignAll([rideData]);
            print('✅ Other active ride loaded: ${rideData['rideId']}');
          } else {
            print('ℹ️ Current ride, not adding to other rides');
            otherActiveRides.clear();
          }
        } else {
          print('ℹ️ No other active rides found in API');
          otherActiveRides.clear();
        }
      } else {
        print('❌ Other active rides API returned success: false');
        otherActiveRides.clear();
      }
    } catch (e) {
      print('❌ Error fetching other active rides from API: $e');
      otherActiveRides.clear();
    } finally {
      isLoadingOtherRides(false);
    }
  }

  // ✅ NEW: Check if user can request more rides
  bool get canRequestMoreRides {
    // Max 3 active rides allowed
    return (otherActiveRides.length + 1) < 3; // current ride + other rides
  }

  // ✅ NEW: Switch to different ride
  void switchToDifferentRide(Map<String, dynamic> rideData) {
    try {
      final newRideId = rideData['rideId'];
      final bid = rideData['bid'];
      final rideType = rideData['rideType'];

      if (newRideId == null || bid == null || rideType == null) {
        FSnackbar.show(
          title: 'Error',
          message: 'Could not load ride data',
          isError: true,
        );
        return;
      }

      print('🔄 Switching to ride: $newRideId');

      // Navigate to DriversWaitingScreen with the new ride data
      Get.offAllNamed("/drivers-waiting", arguments: {
        ...rideData,
        'bid': bid,
        'rideType': rideType,
      });

    } catch (e) {
      print('❌ Error switching to different ride: $e');
      FSnackbar.show(
        title: 'Error',
        message: 'Failed to switch ride',
        isError: true,
      );
    }
  }

  // ✅ NEW: Get driver phone from current ride
  String get driverPhone {
    final driver = rideInfo.value?.driver;
    return driver?['phone_no']?.toString() ?? '';
  }

  void _startBackgroundService() {
    try {
      final passengerId = StorageService.getSignUpResponse()?.userId;
      final rideId = rideInfo.value?.rideId;

      if (passengerId != null && rideId != null) {
        PusherBackgroundService().startBackgroundMode(
          passengerId,
          userType: 'passenger',
          rideId: rideId,
        );

        Timer(Duration(seconds: 3), () async {
          final isRunning = await PusherBackgroundService().isBackgroundServiceRunning();
          print('🎯 Background Service Status: $isRunning');
        });
      }
    } catch (e) {
      print('❌ Error starting background service: $e');
    }
  }

  void onCameraMoveStarted() {
    _userMovedCamera = true;
  }

  void onCameraIdle() {
    // keep userMovedCamera true
  }

  Future<void> recenterCamera({double zoom = 17.0}) async {
    try {
      _userMovedCamera = false;
      _isCameraFollowing = true;
      final driver = driverMarkers['driver'];
      if (driver != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: driver.position, zoom: zoom),
          ),
        );
      } else if (currentPosition.value != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: currentPosition.value!, zoom: zoom),
          ),
        );
      }
    } catch (e) {
      print('❌ recenterCamera error: $e');
    }
  }

  void toggleCameraFollow() {
    _isCameraFollowing = !_isCameraFollowing;
    if (!_isCameraFollowing) _userMovedCamera = true;
  }

  void stopCameraFollow() {
    _isCameraFollowing = false;
    _userMovedCamera = true;
  }

  void resumeCameraFollow() {
    _userMovedCamera = false;
    _isCameraFollowing = true;
  }

  void onMapCreated(GoogleMapController c) {
    _mapController = c;

    try {
      _mapController?.setMapStyle(null);
    } catch (e) {
      print('❌ Failed to set map style: $e');
    }

    _moveCameraToBounds();
  }

  /// ===================== 🔔 DRIVER LOCATION SUBSCRIPTION =====================
  void _subscribeToDriverLocation(String rideId) {
    _pusherManager.subscribeOnce(
      "ride-$rideId",
      events: {
        "driver-location": (data) async {
          try {
            print("📨 Driver-location update: $data");

            double lat = 0.0;
            double lng = 0.0;
            try {
              lat = (data['lat'] as num).toDouble();
              lng = (data['lng'] as num).toDouble();
            } catch (e) {
              lat = double.tryParse(data['lat']?.toString() ?? '') ?? 0.0;
              lng = double.tryParse(data['lng']?.toString() ?? '') ?? 0.0;
            }

            if (lat == 0.0 || lng == 0.0) {
              print("❌ INVALID DRIVER COORDINATES");
              return;
            }

            final newPos = LatLng(lat, lng);
            print("📍 New driver position: $newPos");

            if (_lastDriverPosition == null) {
              _lastDriverPosition = newPos;
              _updateDriverMarker(newPos);
              await _calculateInitialRoute(newPos);
            } else {
              _animateDriverSmoothly(_lastDriverPosition!, newPos);
            }
            _lastDriverPosition = newPos;

            _updateCameraForNavigation(newPos);
            _updateRoutesForCurrentState(newPos);

          } catch (e) {
            print('❌ driver-location handler error: $e');
          }
        },

        "driver-arrived": (data) {
          print("📢 Driver has arrived at pickup: $data");
        },

        "ride-started": (data) async {
          print("🚦 Ride started: $data");
          rideStarted.value = true;
          updateView.value = true;
          _placeStaticMarkersFromRideInfo();

          final driverMarker = driverMarkers["driver"];
          if (driverMarker != null) {
            final origin = driverMarker.position;
            final List<LatLng> pts = [origin];
            final dropoffs = rideInfo.value?.dropoffs ?? [];
            for (var df in dropoffs) {
              pts.add(
                LatLng(
                  (df['lat'] as num).toDouble(),
                  (df['lng'] as num).toDouble(),
                ),
              );
            }
            if (pts.length >= 2) {
              final route = await _buildRouteThroughPointsWithRetry(pts);
              if (route.isNotEmpty) {
                _currentRoute = route;
                _setPolyline(route);
              }
            }
          }
        },

        "ride-ended": (data) {
          print("🏁 Ride ended: $data");

          final args = Get.arguments as Map<String, dynamic>? ?? {};
          final bid = args['bid'] as Map<String, dynamic>?;

          String driverName = 'Driver';
          String driverImage = '';

          if (bid?['driver'] != null) {
            final driver = bid!['driver'];
            final firstName = driver['name']?['firstName']?.toString() ?? '';
            final lastName = driver['name']?['lastName']?.toString() ?? '';
            driverName = '$firstName $lastName'.trim();
            driverImage = driver['profileImage']?.toString() ?? '';
          } else if (args['driver'] != null) {
            final driver = args['driver'];
            final firstName = driver['name']?['firstName']?.toString() ?? '';
            final lastName = driver['name']?['lastName']?.toString() ?? '';
            driverName = '$firstName $lastName'.trim();
            driverImage = driver['profileImage']?.toString() ?? '';
          } else if (data['driver'] != null) {
            final driver = data['driver'];
            final firstName = driver['name']?['firstName']?.toString() ?? '';
            final lastName = driver['name']?['lastName']?.toString() ?? '';
            driverName = '$firstName $lastName'.trim();
            driverImage = driver['profileImage']?.toString() ?? '';
          }

          if (driverName.isEmpty || driverName == ' ') {
            driverName = 'Driver';
          }

          print("👤 Navigating to rate screen with:");
          print("   - Name: $driverName");
          print("   - Image: $driverImage");

          PusherBackgroundService().stopBackgroundMode();

          Get.offAllNamed(
            '/rate',
            arguments: {
              'userId': driverId,
              'rideId': rideId,
              'name': driverName,
              'image': driverImage,
            },
          );
        },

        "ride-cancelled": (data) {
          print("❌ Ride cancelled: $data");
          PusherBackgroundService().stopBackgroundMode();
          Get.offAllNamed('/ride-type');
        },

        "new-message": (data) {
          print("💬 New message received: $data");
          if (StorageService.getSignUpResponse()!.userId == data['receiverId'])
            FSnackbar.show(
              title: "New Message",
              message: data['text'].toString(),
            );
        },
      },
    );
  }

  /// ===================== 🧭 SMOOTH DRIVER MARKER ANIMATION =====================
  void _animateDriverSmoothly(LatLng from, LatLng to) {
    if (_isAnimating) {
      return;
    }

    _isAnimating = true;
    const int totalSteps = 10;
    int currentStep = 0;

    _animationTimer?.cancel();

    _animationTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      currentStep++;

      if (currentStep > totalSteps) {
        timer.cancel();
        _isAnimating = false;
        _updateDriverMarker(to);
        return;
      }

      final progress = currentStep / totalSteps;
      final easedProgress = _easeInOutCubic(progress);

      final lat = from.latitude + (to.latitude - from.latitude) * easedProgress;
      final lng = from.longitude + (to.longitude - from.longitude) * easedProgress;
      final intermediate = LatLng(lat, lng);

      _updateDriverMarker(intermediate);
    });
  }

  double _easeInOutCubic(double x) {
    return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2;
  }

  void _updateDriverMarker(LatLng position) {
    double bearing = 0.0;
    if (_lastDriverPosition != null && position != _lastDriverPosition) {
      bearing = _calculateBearing(_lastDriverPosition!, position);
    }

    driverMarkers["driver"] = Marker(
      markerId: const MarkerId("driver"),
      position: position,
      rotation: bearing,
      zIndex: 2,
      flat: true,
      anchor: const Offset(0.5, 0.5),
      icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    driverMarkers.refresh();
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lon1 = from.longitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final lon2 = to.longitude * pi / 180;

    final dLon = lon2 - lon1;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double bearing = atan2(y, x);
    bearing = bearing * 180 / pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  void _updateCameraForNavigation(LatLng driverPosition) {
    if (_mapController == null || !_isCameraFollowing || _userMovedCamera) return;

    const double zoomLevel = 17.0;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(driverPosition, zoomLevel),
    );
  }

  void _updateRoutesForCurrentState(LatLng driverPosition) {
    final dropoffs = rideInfo.value?.dropoffs ?? [];

    if (!rideStarted.value) {
      if (rideInfo.value?.pickup != null) {
        final pickupPos = LatLng(
          (rideInfo.value!.pickup!['lat'] as num).toDouble(),
          (rideInfo.value!.pickup!['lng'] as num).toDouble(),
        );
        _updateRouteToDestination(driverPosition, pickupPos);
      }
    } else {
      if (dropoffs.isNotEmpty) {
        final stop = dropoffs[0];
        final stopPos = LatLng(
          (stop['lat'] as num).toDouble(),
          (stop['lng'] as num).toDouble(),
        );
        _updateRouteToDestination(driverPosition, stopPos);
      }
    }
  }

  Future<void> _updateRouteToDestination(LatLng from, LatLng to) async {
    try {
      final routePoints = await _fetchRoutePolylineWithRetry(from, to);
      if (routePoints.isNotEmpty) {
        _currentRoute = routePoints;
        _setPolyline(routePoints);
      }
    } catch (e) {
      print('❌ Error updating route: $e');
    }
  }

  Future<void> _moveCameraToBounds() async {
    if (_mapController == null) return;

    final driver = currentPosition.value;
    final pickup = rideInfo.value?.pickup != null
        ? LatLng(
      (rideInfo.value!.pickup!['lat'] as num).toDouble(),
      (rideInfo.value!.pickup!['lng'] as num).toDouble(),
    )
        : null;

    if (driver != null && pickup != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(driver, 14));
    } else if (driver != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(driver, 14));
    } else if (pickup != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pickup, 14));
    }
  }

  void _updatePolylineProgressively(
      List<LatLng> fullRoute,
      LatLng currentPosition,
      double progress,
      ) {
    if (fullRoute.isEmpty) return;

    int closestIndex = 0;
    double minDistance = double.maxFinite;

    for (int i = 0; i < fullRoute.length; i++) {
      final dist = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        fullRoute[i].latitude,
        fullRoute[i].longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }
    final remainingPoints = fullRoute.sublist(closestIndex);
    final updatedPoints = [currentPosition, ...remainingPoints];
    _setPolyline(updatedPoints);
  }

  Future<void> _updateRouteAfterMovement(LatLng currentPosition) async {
    final pickup = rideInfo.value?.pickup;
    final dropoffs = rideInfo.value?.dropoffs ?? [];

    if (!rideStarted.value) {
      if (pickup != null) {
        final pickupPos = LatLng(
          (pickup['lat'] as num).toDouble(),
          (pickup['lng'] as num).toDouble(),
        );
        if (_currentRoute.isEmpty) {
          final pts = await _buildRouteThroughPointsWithRetry([
            currentPosition,
            pickupPos,
          ]);
          if (pts.isNotEmpty) {
            _currentRoute = pts;
            _setPolyline(pts);
          }
        } else {
          if (!_isPositionOnRoute(
            currentPosition,
            _currentRoute,
            toleranceMeters: 50,
          )) {
            final pts = await _buildRouteThroughPointsWithRetry([
              currentPosition,
              pickupPos,
            ]);
            if (pts.isNotEmpty) {
              _currentRoute = pts;
              _setPolyline(pts);
            }
          }
        }
      }
    } else {
      if (dropoffs.isNotEmpty) {
        final firstDropoff = LatLng(
          (dropoffs.first['lat'] as num).toDouble(),
          (dropoffs.first['lng'] as num).toDouble(),
        );
        if (_currentRoute.isEmpty) {
          final pts = await _buildRouteThroughPointsWithRetry([
            currentPosition,
            firstDropoff,
          ]);
          if (pts.isNotEmpty) {
            _currentRoute = pts;
            _setPolyline(pts);
          }
        } else {
          if (!_isPositionOnRoute(
            currentPosition,
            _currentRoute,
            toleranceMeters: 50,
          )) {
            final pts = await _buildRouteThroughPointsWithRetry([
              currentPosition,
              firstDropoff,
            ]);
            if (pts.isNotEmpty) {
              _currentRoute = pts;
              _setPolyline(pts);
            }
          }
        }
      }
    }
  }

  bool _isPositionOnRoute(
      LatLng pos,
      List<LatLng> route, {
        double toleranceMeters = 40,
      }) {
    if (route.isEmpty) return false;
    for (var pt in route) {
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        pt.latitude,
        pt.longitude,
      );
      if (d <= toleranceMeters) return true;
    }
    return false;
  }

  Future<void> _showRouteLikeGoogleMaps(
      LatLng origin,
      LatLng destination,
      ) async {
    try {
      if (_mapController != null && !_userMovedCamera) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: origin, zoom: 17.0, bearing: 0, tilt: 0),
          ),
          duration: Duration(milliseconds: 800),
        );
      }

      final routeInfo = await _fetchDetailedRoute(origin, destination);
      final polylinePoints = routeInfo['polyline'] as List<LatLng>;

      _currentRoute = polylinePoints;
      _setPolyline(polylinePoints);

      await Future.delayed(Duration(milliseconds: 1000));
      if (!_userMovedCamera)
        await _fitMapToBoundsLikeGoogleMaps(polylinePoints);
    } catch (e) {
      print('❌ Error showing route: $e');
      final polyPoints = await _fetchRoutePolylineWithRetry(
        origin,
        destination,
      );
      if (polyPoints.isNotEmpty) {
        _currentRoute = polyPoints;
        _setPolyline(polyPoints);
        if (!_userMovedCamera) await _fitMapToBoundsLikeGoogleMaps(polyPoints);
      }
    }
  }

  Future<Map<String, dynamic>> _fetchDetailedRoute(
      LatLng origin,
      LatLng destination,
      ) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&mode=driving"
        "&key=$_googleDirectionsApiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Failed to fetch route');

    final data = jsonDecode(response.body);
    if (data == null || data['routes'] == null || data['routes'].isEmpty)
      throw Exception('No route found');

    final route = data['routes'][0];
    final legs = route['legs'][0];

    return {
      'polyline': _decodePolyline(route['overview_polyline']['points']),
      'distance': legs['distance']['text'],
      'duration': legs['duration']['text'],
      'steps': legs['steps'],
    };
  }

  Future<void> _fitMapToBoundsLikeGoogleMaps(List<LatLng> routePoints) async {
    if (_mapController == null || routePoints.isEmpty) return;
    final bounds = _boundsFromLatLngList(routePoints);
    if (bounds == null) return;

    final dist = Geolocator.distanceBetween(
      bounds.southwest.latitude,
      bounds.southwest.longitude,
      bounds.northeast.latitude,
      bounds.northeast.longitude,
    );
    final zoomLevel = _calculateOptimalZoom(dist, routePoints.length);
    final animationDuration = _calculateAnimationDuration(dist);

    final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
    final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;

    await Future.delayed(const Duration(milliseconds: 120));
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(centerLat, centerLng), zoom: zoomLevel),
      ),
      duration: Duration(milliseconds: animationDuration),
    );
  }

  double _calculateOptimalZoom(double distance, int pointCount) {
    if (distance < 1000) return 17.0;
    if (distance < 5000) return 14.0;
    if (distance < 20000) return 12.0;
    if (distance < 50000) return 10.0;
    return 8.0;
  }

  int _calculateAnimationDuration(double distance) {
    if (distance < 1000) return 500;
    if (distance < 5000) return 800;
    if (distance < 20000) return 1200;
    return 1500;
  }

  Future<List<LatLng>> _fetchRoutePolylineWithRetry(
      LatLng origin,
      LatLng destination,
      ) async {
    try {
      return await executeWithRetryAndReturn(
            () => _fetchRoutePolyline(origin, destination),
        maxRetries: 2,
      );
    } catch (e) {
      print('❌ Route fetch failed: $e');
      return [];
    }
  }

  Future<List<LatLng>> _buildRouteThroughPointsWithRetry(
      List<LatLng> pts,
      ) async {
    try {
      return await executeWithRetryAndReturn(
            () => _buildRouteThroughPoints(pts),
        maxRetries: 2,
      );
    } catch (e) {
      print('❌ Route build failed: $e');
      return [];
    }
  }

  Future<void> _calculateInitialRoute(LatLng driverLocation) async {
    try {
      if (rideStarted.value) return;

      final pickup = rideInfo.value?.pickup;
      if (pickup != null) {
        final pickupPos = LatLng(
          (pickup['lat'] as num).toDouble(),
          (pickup['lng'] as num).toDouble(),
        );

        final distance = Geolocator.distanceBetween(
          driverLocation.latitude,
          driverLocation.longitude,
          pickupPos.latitude,
          pickupPos.longitude,
        );

        print("📍 Driver-Pickup distance: ${distance.toStringAsFixed(2)} meters");

        if (distance > 50) {
          print("🛣️ Calculating route from driver to pickup...");
          final pts = await _buildRouteThroughPointsWithRetry([
            driverLocation,
            pickupPos,
          ]);
          if (pts.isNotEmpty) {
            _currentRoute = pts;
            _setPolyline(pts);
            if (!_userMovedCamera && _mapController != null) {
              await _fitMapToBoundsLikeGoogleMaps(pts);
            }
            print("✅ Route calculated with ${pts.length} points");
          }
        } else {
          print("📍 Driver is very close to pickup, no route needed");
          polylines.clear();
        }
      }
    } catch (e) {
      print('❌ _calculateInitialRoute error: $e');
    }
  }

  Future<List<LatLng>> _fetchRoutePolyline(
      LatLng origin,
      LatLng destination,
      ) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$_googleDirectionsApiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception("Directions API failed");

    final data = jsonDecode(response.body);
    if (data == null || data['routes'] == null || data['routes'].isEmpty)
      return [];
    final points = data['routes'][0]['overview_polyline']['points'];
    return _decodePolyline(points);
  }

  Future<List<LatLng>> _buildRouteThroughPoints(List<LatLng> pts) async {
    if (pts.length < 2) return [];
    final List<LatLng> full = [];
    for (int i = 0; i < pts.length - 1; i++) {
      try {
        final seg = await _fetchRoutePolyline(pts[i], pts[i + 1]);
        if (seg.isNotEmpty) {
          if (full.isNotEmpty && seg.isNotEmpty) {
            full.addAll(seg.skip(1));
          } else {
            full.addAll(seg);
          }
        }
      } catch (e) {
        print("❌ Error fetching segment $i -> ${i + 1}: $e");
      }
    }
    return full;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;
      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  void _setPolyline(List<LatLng> points) {
    if (points.isEmpty) {
      polylines.clear();
      return;
    }

    final shadow = Polyline(
      polylineId: const PolylineId("driver_route_shadow"),
      color: FColors.secondaryColor,
      width: 6,
      points: points,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );

    final main = Polyline(
      polylineId: const PolylineId("driver_route_main"),
      color: FColors.secondaryColor,
      width: 6,
      points: points,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );

    polylines.value = {shadow, main};
  }

  LatLngBounds? _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) return null;
    double x0 = list.first.latitude, x1 = list.first.latitude;
    double y0 = list.first.longitude, y1 = list.first.longitude;
    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  void _placeStaticMarkersFromRideInfo() {
    driverMarkers.removeWhere(
          (k, v) => k == 'pickup' || k.startsWith('stop_') || k == 'dropoff',
    );

    if (rideInfo.value == null) return;

    final pickup = rideInfo.value!.pickup;
    if (pickup != null) {
      final pickPos = LatLng(
        (pickup['lat'] as num).toDouble(),
        (pickup['lng'] as num).toDouble(),
      );
      driverMarkers['pickup'] = Marker(
        markerId: const MarkerId('pickup'),
        position: pickPos,
        icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: pickup['address']?.toString() ?? 'Pickup',
        ),
      );
    }

    final dropoffs = rideInfo.value!.dropoffs ?? [];
    for (int i = 0; i < dropoffs.length; i++) {
      final df = dropoffs[i];
      final pos = LatLng(
        (df['lat'] as num).toDouble(),
        (df['lng'] as num).toDouble(),
      );

      if (i == dropoffs.length - 1) {
        driverMarkers['dropoff'] = Marker(
          markerId: const MarkerId('dropoff'),
          position: pos,
          icon: _dropIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: df['address']?.toString() ?? 'Dropoff'),
        );
      } else {
        driverMarkers['stop_$i'] = Marker(
          markerId: MarkerId('stop_$i'),
          position: pos,
          icon: _stopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(
            title: df['address']?.toString() ?? 'Stop ${i + 1}',
          ),
        );
      }
    }
    driverMarkers.refresh();
  }

  Future<BitmapDescriptor> _bitmapFromAsset(
      String path, {
        int width = 100,
      }) async {
    try {
      final byteData = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        byteData.buffer.asUint8List(),
        targetWidth: width,
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
    } catch (e) {
      print('❌ Error loading marker icon: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _loadMarkerIcons() async {
    try {
      _driverIcon = await _bitmapFromAsset('assets/images/car.png', width: 80);
      _pickupIcon = await _bitmapFromAsset(
        'assets/images/position_marker2.png',
        width: 72,
      );
      _stopIcon = await _bitmapFromAsset('assets/images/place.png', width: 64);
      _dropIcon = await _bitmapFromAsset('assets/images/place.png', width: 72);
      print("✅ All icons loaded");
    } catch (e) {
      print('❌ Failed to load marker icons: $e');
    }
  }

  Future<void> showCancelReasons(BuildContext context) async {
    final screenWidth = Get.width;
    final baseWidth = 440.0;
    double sw(double w) => w * screenWidth / baseWidth;
    final cancellationReasons = [
      "Driver not responding",
      "Driver not at pickup",
      "Wrong pickup location",
      "Driver refused",
      "Change of plans",
      "Emergency",
      "Other reason",
    ];
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(sw(20)),
            topRight: Radius.circular(sw(20)),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: sw(20), vertical: sw(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Cancel Ride",
              style: TextStyle(
                fontSize: sw(18),
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: sw(10)),
            Text(
              "Please select a reason for cancellation:",
              style: TextStyle(fontSize: sw(14), color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: sw(20)),
            ...cancellationReasons
                .map(
                  (reason) => Column(
                children: [
                  ListTile(
                    title: Text(
                      reason,
                      style: TextStyle(
                        fontSize: sw(14),
                        color: Colors.black,
                      ),
                    ),
                    onTap: () {
                      Get.back();
                      _confirmCancellation(reason);
                    },
                  ),
                  Divider(height: sw(1), color: Colors.grey[300]),
                ],
              ),
            )
                .toList(),
            SizedBox(height: sw(20)),
            SizedBox(
              width: double.infinity,
              height: sw(48),
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(sw(14)),
                  ),
                ),
                child: Text(
                  "Continue Waiting",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: sw(14),
                  ),
                ),
              ),
            ),
            SizedBox(height: sw(10)),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmCancellation(String reason) => _getCurrentLocationAndCancel(reason);

  Future<void> _getCurrentLocationAndCancel(String reason) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLocation = LatLng(position.latitude, position.longitude);
      _cancelRide(reason, userLocation);
    } catch (e) {
      print('❌ Error getting current location: $e');
      final fallbackLocation = currentPosition.value ?? LatLng(0, 0);
      _cancelRide(reason, fallbackLocation);
    }
  }

  Future<void> _cancelRide(
      String cancellationReason,
      LatLng userLocation,
      ) async {
    try {
      if (thisRideId == null) {
        showError('Ride id missing');
        return;
      }
      if ((userLocation.latitude == 0.0 && userLocation.longitude == 0.0)) {
        showError(
          'Unable to get your current location. Please check location permissions.',
        );
        return;
      }
      isCancelling.value = true;
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final body = {
        'cancellationReason': cancellationReason,
        'location': {
          'lat': userLocation.latitude,
          'lng': userLocation.longitude,
        },
      };
      final res = await FHttpHelper.post(
        'ride/ride-cancelled/$thisRideId',
        body,
      );
      print('✅ ride-cancelled response: $res');
      showSuccess('Ride cancelled successfully');
      PusherBackgroundService().stopBackgroundMode();
      Get.back();
      isCancelling.value = false;
      Get.offAllNamed('/ride-type');
    } catch (e) {
      print('❌ ride-cancelled error: $e');
      Get.back();
      isCancelling.value = false;
      showError('Failed to cancel ride');
    }
  }

  @override
  void onClose() {
    _waitingTimer?.cancel();
    _animationTimer?.cancel();
    fareController.dispose();
    PusherBackgroundService().stopBackgroundMode();
    super.onClose();
  }
}




// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:ui' as ui;
// import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
// import 'package:doorcab/feautures/rides/passenger/controllers/dropoff_controller.dart';
// import 'package:doorcab/feautures/rides/passenger/controllers/ride_booking_controller.dart';
// import 'package:doorcab/feautures/rides/passenger/controllers/ride_type_controller.dart';
// import 'package:doorcab/utils/constants/colors.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import '../../../../utils/http/http_client.dart';
// import '../../../shared/controllers/base_controller.dart';
// import '../../../shared/services/enhanced_pusher_manager.dart';
// import '../../../shared/services/pusher_background_service.dart';
// import '../../../shared/services/storage_service.dart';
// import '../models/driver_ride_info.dart';
// import '../screens/ride_type_screen.dart';
// import 'available_bids_controller.dart';
// import 'available_drivers_controller.dart';
//
// class DriversWaitingController extends BaseController {
//   // PUBLIC OBSERVABLES / CONTROLLERS FOR UI
//   final currentPosition = Rxn<LatLng>();
//   final driverMarkers = <String, Marker>{}.obs;
//   final polylines = <Polyline>{}.obs;
//   final fareController = TextEditingController();
//   final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
//
//   // INTERNAL
//   GoogleMapController? _mapController;
//   Timer? _waitingTimer;
//
//   final rideStarted = false.obs;
//   final RxBool updateView = false.obs;
//   var thisRideId;
//
//   String? _rideId;
//   String? _driverId;
//
//   String? get rideId => _rideId;
//
//   String? get driverId => _driverId;
//
//   set rideId(String? id) => _rideId = id;
//
//   set driverId(String? id) => _driverId = id;
//
//   final rideInfo = Rxn<DriverRideInfo>();
//   final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
//   late final Map<String, dynamic> rideArgs;
//   final isCancelling = false.obs;
//
//   // Animation / camera control (UPDATED with GoToPickupController behavior)
//   LatLng? _lastDriverPosition;
//   bool _isCameraFollowing = true; // default: follow driver
//   bool _isAnimating = false;
//   Timer? _animationTimer; // NEW: Timer for smooth animation
//   bool _userMovedCamera =
//   false; // when true, don't auto-zoom/recenter while user interacting
//   double? _lastUserZoom; // to track zoom changes
//
//   // Icons
//   BitmapDescriptor? _driverIcon;
//   BitmapDescriptor? _pickupIcon;
//   BitmapDescriptor? _stopIcon;
//   BitmapDescriptor? _dropIcon;
//
//   // Route cache for progressive trimming
//   List<LatLng> _currentRoute = [];
//
//   // Active rides observable
//   final activeRides = <Map<String, dynamic>>[].obs;
//
//
//   // Directions API key (kept from your original). Consider moving to secure storage.
//   static const String _googleDirectionsApiKey =
//       "AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4";
//
//   // Map navigation style (left as-is)
//   final String _navigationMapStyle = '''
//   [
//     {"elementType":"geometry","stylers":[{"color":"#1f2937"}]},
//     {"elementType":"labels.text.fill","stylers":[{"color":"#9ca3af"}]},
//     {"elementType":"labels.text.stroke","stylers":[{"color":"#111827"}]},
//     {"featureType":"road","elementType":"geometry","stylers":[{"color":"#111827"}]},
//     {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#0b1220"}]},
//     {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#9ca3af"}]},
//     {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#0b1220"}]}
//   ]
//   ''';
//
//   @override
//   void onInit() async {
//     super.onInit();
//
//     final args = Get.arguments as Map<String, dynamic>? ?? {};
//     rideArgs = Map<String, dynamic>.from(Get.arguments ?? {});
//     print(
//       "📌 Ride args in Drivers Waiting Controller: ${rideArgs['rideType']}",
//     );
//
//     if (args.isNotEmpty) {
//       print("📦 Args received: $args");
//       final bid = args['bid'] as Map<String, dynamic>?;
//       rideInfo.value = DriverRideInfo.fromArgs({...args, ...?bid});
//       rideId = args['rideId']?.toString();
//       driverId = bid?['driver']?['id']?.toString();
//       print("Driver id: $driverId");
//     }
//
//     thisRideId = rideInfo.value?.rideId;
//
//     await _loadMarkerIcons();
//
//     // Place static markers: pickup, stops, dropoff
//     _placeStaticMarkersFromRideInfo();
//
//     // Initial current position - set as pickup location fallback
//     if (rideInfo.value?.pickup != null) {
//       currentPosition.value = LatLng(
//         (rideInfo.value!.pickup!['lat'] as num).toDouble(),
//         (rideInfo.value!.pickup!['lng'] as num).toDouble(),
//       );
//
//       // Create initial driver marker at pickup (temporary), UI will animate to real driver position when received
//       _updateDriverMarker(currentPosition.value!);
//       _lastDriverPosition = currentPosition.value;
//     } else {
//       currentPosition.value = const LatLng(31.5204, 74.3587);
//       _lastDriverPosition = currentPosition.value;
//     }
//
//     // Subscribe to driver events
//     if (rideInfo.value != null &&
//         (rideInfo.value!.rideId?.isNotEmpty ?? false)) {
//       _subscribeToDriverLocation(rideInfo.value!.rideId!);
//     }
//     _startBackgroundService();
//   }
//
//   // void _startBackgroundService() {
//   //   final passengerId = StorageService.getSignUpResponse()?.userId;
//   //   final rideId = rideInfo.value?.rideId;
//   //   if (passengerId != null && rideId != null) {
//   //     PusherBackgroundService().startBackgroundMode(
//   //       passengerId,
//   //       rideId: rideId,
//   //     );
//   //   }
//   // }
//
//   void _startBackgroundService() {
//     try {
//       final passengerId = StorageService.getSignUpResponse()?.userId;
//       final rideId = rideInfo.value?.rideId;
//
//       if (passengerId != null && rideId != null) {
//         PusherBackgroundService().startBackgroundMode(
//           passengerId,
//           userType: 'passenger', // ✅ Explicitly set user type
//           rideId: rideId,
//         );
//
//         // Check if service started successfully
//         Timer(Duration(seconds: 3), () async {
//           final isRunning = await PusherBackgroundService().isBackgroundServiceRunning();
//           print('🎯 Background Service Status: $isRunning');
//         });
//       }
//     } catch (e) {
//       print('❌ Error starting background service: $e');
//     }
//   }
//
//   /// --- Public helpers to be wired from map widget so controller knows when user interacted with camera ---
//   /// Call these from the GoogleMap widget:
//   /// onCameraMoveStarted: controller.onCameraMoveStarted()
//   /// onCameraIdle: controller.onCameraIdle()
//   void onCameraMoveStarted() {
//     _userMovedCamera = true;
//   }
//
//   void onCameraIdle() {
//     // keep userMovedCamera true for some time or until user taps a "recenter" control
//     // we keep true; user can toggle follow via toggleCameraFollow()
//   }
//
//   /// Allow UI to explicitly re-enable camera follow (e.g., user taps "center" button)
//   Future<void> recenterCamera({double zoom = 17.0}) async {
//     try {
//       _userMovedCamera = false;
//       _isCameraFollowing = true;
//       final driver = driverMarkers['driver'];
//       if (driver != null && _mapController != null) {
//         await _mapController!.animateCamera(
//           CameraUpdate.newCameraPosition(
//             CameraPosition(target: driver.position, zoom: zoom),
//           ),
//         );
//       } else if (currentPosition.value != null && _mapController != null) {
//         await _mapController!.animateCamera(
//           CameraUpdate.newCameraPosition(
//             CameraPosition(target: currentPosition.value!, zoom: zoom),
//           ),
//         );
//       }
//     } catch (e) {
//       print('❌ recenterCamera error: $e');
//     }
//   }
//
//   void toggleCameraFollow() {
//     _isCameraFollowing = !_isCameraFollowing;
//     if (!_isCameraFollowing) _userMovedCamera = true; // user wants no follow
//   }
//
//   void stopCameraFollow() {
//     _isCameraFollowing = false;
//     _userMovedCamera = true;
//   }
//
//   void resumeCameraFollow() {
//     _userMovedCamera = false;
//     _isCameraFollowing = true;
//   }
//
//   /// On map created — set style and build initial route (driver->pickup)
//   void onMapCreated(GoogleMapController c) {
//     _mapController = c;
//
//     try {
//       _mapController?.setMapStyle(null);
//     } catch (e) {
//       print('❌ Failed to set map style: $e');
//     }
//
//     // Initial camera positioning
//     _moveCameraToBounds();
//   }
//
//   /// ===================== 🔔 DRIVER LOCATION SUBSCRIPTION =====================
//   void _subscribeToDriverLocation(String rideId) {
//     _pusherManager.subscribeOnce(
//       "ride-$rideId",
//       events: {
//         "driver-location": (data) async {
//           try {
//             print("📨 Driver-location update: $data");
//
//             double lat = 0.0;
//             double lng = 0.0;
//             try {
//               lat = (data['lat'] as num).toDouble();
//               lng = (data['lng'] as num).toDouble();
//             } catch (e) {
//               lat = double.tryParse(data['lat']?.toString() ?? '') ?? 0.0;
//               lng = double.tryParse(data['lng']?.toString() ?? '') ?? 0.0;
//             }
//
//             if (lat == 0.0 || lng == 0.0) {
//               print("❌ INVALID DRIVER COORDINATES");
//               return;
//             }
//
//             final newPos = LatLng(lat, lng);
//             print("📍 New driver position: $newPos");
//
//             // ✅ UPDATED: Use smooth animation from GoToPickupController
//             if (_lastDriverPosition == null) {
//               _lastDriverPosition = newPos;
//               _updateDriverMarker(newPos);
//               await _calculateInitialRoute(newPos);
//             } else {
//               // 🧭 Smooth sliding animation between positions
//               _animateDriverSmoothly(_lastDriverPosition!, newPos);
//             }
//             _lastDriverPosition = newPos;
//
//             // ✅ UPDATED: Google Maps style camera following
//             _updateCameraForNavigation(newPos);
//
//             // ✅ UPDATED: Update routes based on current state
//             _updateRoutesForCurrentState(newPos);
//
//           } catch (e) {
//             print('❌ driver-location handler error: $e');
//           }
//         },
//
//         "driver-arrived": (data) {
//           print("📢 Driver has arrived at pickup: $data");
//           // FSnackbar.show(
//           //   title: 'Driver Arrived',
//           //   message: "Driver arrived at your pick up location.",
//           // );
//         },
//
//         "ride-started": (data) async {
//           print("🚦 Ride started: $data");
//           rideStarted.value = true;
//           // FSnackbar.show(title: "Ride Started", message: "Enjoy your trip!");
//           updateView.value = true;
//           _placeStaticMarkersFromRideInfo();
//
//           // Rebuild route for dropoffs using current driver marker as origin
//           final driverMarker = driverMarkers["driver"];
//           if (driverMarker != null) {
//             final origin = driverMarker.position;
//             final List<LatLng> pts = [origin];
//             final dropoffs = rideInfo.value?.dropoffs ?? [];
//             for (var df in dropoffs) {
//               pts.add(
//                 LatLng(
//                   (df['lat'] as num).toDouble(),
//                   (df['lng'] as num).toDouble(),
//                 ),
//               );
//             }
//             if (pts.length >= 2) {
//               final route = await _buildRouteThroughPointsWithRetry(pts);
//               if (route.isNotEmpty) {
//                 _currentRoute = route;
//                 _setPolyline(route);
//               }
//             }
//           }
//         },
//
//         "ride-ended": (data) {
//           print("🏁 Ride ended: $data");
//           // showSuccess('Ride completed successfully');
//
//           final args = Get.arguments as Map<String, dynamic>? ?? {};
//           final bid = args['bid'] as Map<String, dynamic>?;
//
//           String driverName = 'Driver';
//           String driverImage = '';
//
//           if (bid?['driver'] != null) {
//             final driver = bid!['driver'];
//             final firstName = driver['name']?['firstName']?.toString() ?? '';
//             final lastName = driver['name']?['lastName']?.toString() ?? '';
//             driverName = '$firstName $lastName'.trim();
//             driverImage = driver['profileImage']?.toString() ?? '';
//           } else if (args['driver'] != null) {
//             final driver = args['driver'];
//             final firstName = driver['name']?['firstName']?.toString() ?? '';
//             final lastName = driver['name']?['lastName']?.toString() ?? '';
//             driverName = '$firstName $lastName'.trim();
//             driverImage = driver['profileImage']?.toString() ?? '';
//           } else if (data['driver'] != null) {
//             final driver = data['driver'];
//             final firstName = driver['name']?['firstName']?.toString() ?? '';
//             final lastName = driver['name']?['lastName']?.toString() ?? '';
//             driverName = '$firstName $lastName'.trim();
//             driverImage = driver['profileImage']?.toString() ?? '';
//           }
//
//           if (driverName.isEmpty || driverName == ' ') {
//             driverName = 'Driver';
//           }
//
//           print("👤 Navigating to rate screen with:");
//           print("   - Name: $driverName");
//           print("   - Image: $driverImage");
//
//           PusherBackgroundService().stopBackgroundMode();
//
//           Get.offAllNamed(
//             '/rate',
//             arguments: {
//               'userId': driverId,
//               'rideId': rideId,
//               'name': driverName,
//               'image': driverImage,
//             },
//           );
//         },
//
//         "ride-cancelled": (data) {
//           print("❌ Ride cancelled: $data");
//           PusherBackgroundService().stopBackgroundMode();
//           Get.offAllNamed('/ride-type');
//         },
//
//         "new-message": (data) {
//           print("💬 New message received: $data");
//           if (StorageService.getSignUpResponse()!.userId == data['receiverId'])
//             FSnackbar.show(
//               title: "New Message",
//               message: data['text'].toString(),
//             );
//         },
//       },
//     );
//   }
//
//   /// ===================== 🧭 SMOOTH DRIVER MARKER ANIMATION (from GoToPickupController) =====================
//   void _animateDriverSmoothly(LatLng from, LatLng to) {
//     if (_isAnimating) {
//       return; // Skip if already animating
//     }
//
//     _isAnimating = true;
//     const int totalSteps = 10; // Steps for smoother animation
//     int currentStep = 0;
//
//     // Cancel any existing animation
//     _animationTimer?.cancel();
//
//     _animationTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
//       currentStep++;
//
//       if (currentStep > totalSteps) {
//         timer.cancel();
//         _isAnimating = false;
//         _updateDriverMarker(to); // Final position
//         return;
//       }
//
//       // Calculate intermediate position with easing for smoother movement
//       final progress = currentStep / totalSteps;
//       final easedProgress = _easeInOutCubic(progress);
//
//       final lat = from.latitude + (to.latitude - from.latitude) * easedProgress;
//       final lng = from.longitude + (to.longitude - from.longitude) * easedProgress;
//       final intermediate = LatLng(lat, lng);
//
//       _updateDriverMarker(intermediate);
//     });
//   }
//
//   // Easing function for smooth animation (from GoToPickupController)
//   double _easeInOutCubic(double x) {
//     return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2;
//   }
//
//   void _updateDriverMarker(LatLng position) {
//     // Calculate bearing for proper rotation
//     double bearing = 0.0;
//     if (_lastDriverPosition != null && position != _lastDriverPosition) {
//       bearing = _calculateBearing(_lastDriverPosition!, position);
//     }
//
//     driverMarkers["driver"] = Marker(
//       markerId: const MarkerId("driver"),
//       position: position,
//       rotation: bearing, // Smooth rotation based on movement direction
//       zIndex: 2,
//       flat: true,
//       anchor: const Offset(0.5, 0.5),
//       icon:
//       _driverIcon ??
//           BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//     );
//     driverMarkers.refresh();
//   }
//
//   double _calculateBearing(LatLng from, LatLng to) {
//     final lat1 = from.latitude * pi / 180;
//     final lon1 = from.longitude * pi / 180;
//     final lat2 = to.latitude * pi / 180;
//     final lon2 = to.longitude * pi / 180;
//
//     final dLon = lon2 - lon1;
//
//     final y = sin(dLon) * cos(lat2);
//     final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
//
//     double bearing = atan2(y, x);
//     bearing = bearing * 180 / pi;
//     bearing = (bearing + 360) % 360;
//
//     return bearing;
//   }
//
//   /// ===================== 🗺️ GOOGLE MAPS STYLE CAMERA (from GoToPickupController) =====================
//   void _updateCameraForNavigation(LatLng driverPosition) {
//     if (_mapController == null || !_isCameraFollowing || _userMovedCamera) return;
//
//     // ✅ Google Maps behavior: Show driver at zoom level 17 (like Google Maps navigation)
//     const double zoomLevel = 17.0; // Perfect for seeing turns and streets clearly
//
//     // ✅ Smooth camera follow (like Google Maps)
//     _mapController!.animateCamera(
//       CameraUpdate.newLatLngZoom(driverPosition, zoomLevel),
//     );
//   }
//
//   void _updateRoutesForCurrentState(LatLng driverPosition) {
//     final dropoffs = rideInfo.value?.dropoffs ?? [];
//
//     if (!rideStarted.value) {
//       // ✅ Driver to Pickup route - show full route but camera focuses on driver
//       if (rideInfo.value?.pickup != null) {
//         final pickupPos = LatLng(
//           (rideInfo.value!.pickup!['lat'] as num).toDouble(),
//           (rideInfo.value!.pickup!['lng'] as num).toDouble(),
//         );
//         _updateRouteToDestination(driverPosition, pickupPos);
//       }
//     } else {
//       // ✅ Driver to Dropoffs route - show full route but camera focuses on driver
//       if (dropoffs.isNotEmpty) {
//         final stop = dropoffs[0]; // First dropoff
//         final stopPos = LatLng(
//           (stop['lat'] as num).toDouble(),
//           (stop['lng'] as num).toDouble(),
//         );
//         _updateRouteToDestination(driverPosition, stopPos);
//       }
//     }
//   }
//
//   Future<void> _updateRouteToDestination(LatLng from, LatLng to) async {
//     try {
//       final routePoints = await _fetchRoutePolylineWithRetry(from, to);
//       if (routePoints.isNotEmpty) {
//         _currentRoute = routePoints;
//         _setPolyline(routePoints);
//       }
//     } catch (e) {
//       print('❌ Error updating route: $e');
//     }
//   }
//
//   /// ===================== LOCATION & CAMERA =====================
//   Future<void> _moveCameraToBounds() async {
//     if (_mapController == null) return;
//
//     final driver = currentPosition.value;
//     final pickup = rideInfo.value?.pickup != null
//         ? LatLng(
//       (rideInfo.value!.pickup!['lat'] as num).toDouble(),
//       (rideInfo.value!.pickup!['lng'] as num).toDouble(),
//     )
//         : null;
//
//     if (driver != null && pickup != null) {
//       // ✅ Show both driver and pickup initially, then let navigation take over
//       await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(driver, 14));
//     } else if (driver != null) {
//       await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(driver, 14));
//     } else if (pickup != null) {
//       await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pickup, 14));
//     }
//   }
//
//   // ===================== ALL YOUR ORIGINAL METHODS PRESERVED BELOW =====================
//
//   /// ===================== 🗺️ PROGRESSIVE POLYLINE UPDATING =====================
//   void _updatePolylineProgressively(
//       List<LatLng> fullRoute,
//       LatLng currentPosition,
//       double progress,
//       ) {
//     if (fullRoute.isEmpty) return;
//
//     // Find closest index on fullRoute to currentPosition
//     int closestIndex = 0;
//     double minDistance = double.maxFinite;
//
//     for (int i = 0; i < fullRoute.length; i++) {
//       final dist = Geolocator.distanceBetween(
//         currentPosition.latitude,
//         currentPosition.longitude,
//         fullRoute[i].latitude,
//         fullRoute[i].longitude,
//       );
//       if (dist < minDistance) {
//         minDistance = dist;
//         closestIndex = i;
//       }
//     }
//     final remainingPoints = fullRoute.sublist(closestIndex);
//     final updatedPoints = [currentPosition, ...remainingPoints];
//     _setPolyline(updatedPoints);
//   }
//
//   /// ===================== 🛣️ UPDATE ROUTE AFTER MOVEMENT (only when needed) =====================
//   Future<void> _updateRouteAfterMovement(LatLng currentPosition) async {
//     final pickup = rideInfo.value?.pickup;
//     final dropoffs = rideInfo.value?.dropoffs ?? [];
//
//     // If ride not started -> route driver->pickup (but only if we don't already have route or route is invalid)
//     if (!rideStarted.value) {
//       if (pickup != null) {
//         final pickupPos = LatLng(
//           (pickup['lat'] as num).toDouble(),
//           (pickup['lng'] as num).toDouble(),
//         );
//         // If current route is empty, or driver is off the route by > 50m, recompute
//         if (_currentRoute.isEmpty) {
//           final pts = await _buildRouteThroughPointsWithRetry([
//             currentPosition,
//             pickupPos,
//           ]);
//           if (pts.isNotEmpty) {
//             _currentRoute = pts;
//             _setPolyline(pts);
//           }
//         } else {
//           // check distance from currentPosition to closest point on route
//           if (!_isPositionOnRoute(
//             currentPosition,
//             _currentRoute,
//             toleranceMeters: 50,
//           )) {
//             final pts = await _buildRouteThroughPointsWithRetry([
//               currentPosition,
//               pickupPos,
//             ]);
//             if (pts.isNotEmpty) {
//               _currentRoute = pts;
//               _setPolyline(pts);
//             }
//           }
//         }
//       }
//     } else {
//       // ride started -> route driver -> first dropoff/stops
//       if (dropoffs.isNotEmpty) {
//         final firstDropoff = LatLng(
//           (dropoffs.first['lat'] as num).toDouble(),
//           (dropoffs.first['lng'] as num).toDouble(),
//         );
//         if (_currentRoute.isEmpty) {
//           final pts = await _buildRouteThroughPointsWithRetry([
//             currentPosition,
//             firstDropoff,
//           ]);
//           if (pts.isNotEmpty) {
//             _currentRoute = pts;
//             _setPolyline(pts);
//           }
//         } else {
//           if (!_isPositionOnRoute(
//             currentPosition,
//             _currentRoute,
//             toleranceMeters: 50,
//           )) {
//             final pts = await _buildRouteThroughPointsWithRetry([
//               currentPosition,
//               firstDropoff,
//             ]);
//             if (pts.isNotEmpty) {
//               _currentRoute = pts;
//               _setPolyline(pts);
//             }
//           }
//         }
//       }
//     }
//   }
//
//   bool _isPositionOnRoute(
//       LatLng pos,
//       List<LatLng> route, {
//         double toleranceMeters = 40,
//       }) {
//     if (route.isEmpty) return false;
//     for (var pt in route) {
//       final d = Geolocator.distanceBetween(
//         pos.latitude,
//         pos.longitude,
//         pt.latitude,
//         pt.longitude,
//       );
//       if (d <= toleranceMeters) return true;
//     }
//     return false;
//   }
//
//   /// ===================== 🗺️ GOOGLE MAPS-STYLE ROUTE DISPLAY (original behaviour) =====================
//   Future<void> _showRouteLikeGoogleMaps(
//       LatLng origin,
//       LatLng destination,
//       ) async {
//     try {
//       if (_mapController != null && !_userMovedCamera) {
//         await _mapController!.animateCamera(
//           CameraUpdate.newCameraPosition(
//             CameraPosition(target: origin, zoom: 17.0, bearing: 0, tilt: 0),
//           ),
//           duration: Duration(milliseconds: 800),
//         );
//       }
//
//       final routeInfo = await _fetchDetailedRoute(origin, destination);
//       final polylinePoints = routeInfo['polyline'] as List<LatLng>;
//
//       _currentRoute = polylinePoints;
//       _setPolyline(polylinePoints);
//
//       await Future.delayed(Duration(milliseconds: 1000));
//       if (!_userMovedCamera)
//         await _fitMapToBoundsLikeGoogleMaps(polylinePoints);
//     } catch (e) {
//       print('❌ Error showing route: $e');
//       final polyPoints = await _fetchRoutePolylineWithRetry(
//         origin,
//         destination,
//       );
//       if (polyPoints.isNotEmpty) {
//         _currentRoute = polyPoints;
//         _setPolyline(polyPoints);
//         if (!_userMovedCamera) await _fitMapToBoundsLikeGoogleMaps(polyPoints);
//       }
//     }
//   }
//
//   Future<Map<String, dynamic>> _fetchDetailedRoute(
//       LatLng origin,
//       LatLng destination,
//       ) async {
//     final url =
//         "https://maps.googleapis.com/maps/api/directions/json"
//         "?origin=${origin.latitude},${origin.longitude}"
//         "&destination=${destination.latitude},${destination.longitude}"
//         "&mode=driving"
//         "&key=$_googleDirectionsApiKey";
//
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode != 200) throw Exception('Failed to fetch route');
//
//     final data = jsonDecode(response.body);
//     if (data == null || data['routes'] == null || data['routes'].isEmpty)
//       throw Exception('No route found');
//
//     final route = data['routes'][0];
//     final legs = route['legs'][0];
//
//     return {
//       'polyline': _decodePolyline(route['overview_polyline']['points']),
//       'distance': legs['distance']['text'],
//       'duration': legs['duration']['text'],
//       'steps': legs['steps'],
//     };
//   }
//
//   Future<void> _fitMapToBoundsLikeGoogleMaps(List<LatLng> routePoints) async {
//     if (_mapController == null || routePoints.isEmpty) return;
//     final bounds = _boundsFromLatLngList(routePoints);
//     if (bounds == null) return;
//
//     final dist = Geolocator.distanceBetween(
//       bounds.southwest.latitude,
//       bounds.southwest.longitude,
//       bounds.northeast.latitude,
//       bounds.northeast.longitude,
//     );
//     final zoomLevel = _calculateOptimalZoom(dist, routePoints.length);
//     final animationDuration = _calculateAnimationDuration(dist);
//
//     final centerLat =
//         (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
//     final centerLng =
//         (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
//
//     await Future.delayed(const Duration(milliseconds: 120));
//     await _mapController!.animateCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(target: LatLng(centerLat, centerLng), zoom: zoomLevel),
//       ),
//       duration: Duration(milliseconds: animationDuration),
//     );
//   }
//
//   double _calculateOptimalZoom(double distance, int pointCount) {
//     if (distance < 1000) return 17.0;
//     if (distance < 5000) return 14.0;
//     if (distance < 20000) return 12.0;
//     if (distance < 50000) return 10.0;
//     return 8.0;
//   }
//
//   int _calculateAnimationDuration(double distance) {
//     if (distance < 1000) return 500;
//     if (distance < 5000) return 800;
//     if (distance < 20000) return 1200;
//     return 1500;
//   }
//
//   /// ===================== ROUTE/ POLYLINE HELPERS =====================
//   Future<List<LatLng>> _fetchRoutePolylineWithRetry(
//       LatLng origin,
//       LatLng destination,
//       ) async {
//     try {
//       return await executeWithRetryAndReturn(
//             () => _fetchRoutePolyline(origin, destination),
//         maxRetries: 2,
//       );
//     } catch (e) {
//       print('❌ Route fetch failed: $e');
//       return [];
//     }
//   }
//
//   Future<List<LatLng>> _buildRouteThroughPointsWithRetry(
//       List<LatLng> pts,
//       ) async {
//     try {
//       return await executeWithRetryAndReturn(
//             () => _buildRouteThroughPoints(pts),
//         maxRetries: 2,
//       );
//     } catch (e) {
//       print('❌ Route build failed: $e');
//       return [];
//     }
//   }
//
//   Future<void> _calculateInitialRoute(LatLng driverLocation) async {
//     try {
//       if (rideStarted.value) return; // Don't calculate if ride already started
//
//       final pickup = rideInfo.value?.pickup;
//       if (pickup != null) {
//         final pickupPos = LatLng(
//           (pickup['lat'] as num).toDouble(),
//           (pickup['lng'] as num).toDouble(),
//         );
//
//         // Calculate distance between driver and pickup
//         final distance = Geolocator.distanceBetween(
//           driverLocation.latitude,
//           driverLocation.longitude,
//           pickupPos.latitude,
//           pickupPos.longitude,
//         );
//
//         print(
//           "📍 Driver-Pickup distance: ${distance.toStringAsFixed(2)} meters",
//         );
//
//         // Only calculate route if locations are meaningfully different
//         if (distance > 50) {
//           // More than 50 meters apart
//           print("🛣️ Calculating route from driver to pickup...");
//           final pts = await _buildRouteThroughPointsWithRetry([
//             driverLocation,
//             pickupPos,
//           ]);
//           if (pts.isNotEmpty) {
//             _currentRoute = pts;
//             _setPolyline(pts);
//             if (!_userMovedCamera && _mapController != null) {
//               await _fitMapToBoundsLikeGoogleMaps(pts);
//             }
//             print("✅ Route calculated with ${pts.length} points");
//           }
//         } else {
//           print("📍 Driver is very close to pickup, no route needed");
//           // Clear any existing polyline
//           polylines.clear();
//         }
//       }
//     } catch (e) {
//       print('❌ _calculateInitialRoute error: $e');
//     }
//   }
//
//   Future<List<LatLng>> _fetchRoutePolyline(
//       LatLng origin,
//       LatLng destination,
//       ) async {
//     final url =
//         "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}"
//         "&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$_googleDirectionsApiKey";
//
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode != 200) throw Exception("Directions API failed");
//
//     final data = jsonDecode(response.body);
//     if (data == null || data['routes'] == null || data['routes'].isEmpty)
//       return [];
//     final points = data['routes'][0]['overview_polyline']['points'];
//     return _decodePolyline(points);
//   }
//
//   Future<List<LatLng>> _buildRouteThroughPoints(List<LatLng> pts) async {
//     if (pts.length < 2) return [];
//     final List<LatLng> full = [];
//     for (int i = 0; i < pts.length - 1; i++) {
//       try {
//         final seg = await _fetchRoutePolyline(pts[i], pts[i + 1]);
//         if (seg.isNotEmpty) {
//           if (full.isNotEmpty && seg.isNotEmpty) {
//             full.addAll(seg.skip(1));
//           } else {
//             full.addAll(seg);
//           }
//         }
//       } catch (e) {
//         print("❌ Error fetching segment $i -> ${i + 1}: $e");
//       }
//     }
//     return full;
//   }
//
//   List<LatLng> _decodePolyline(String encoded) {
//     List<LatLng> poly = [];
//     int index = 0, len = encoded.length;
//     int lat = 0, lng = 0;
//     while (index < len) {
//       int b, shift = 0, result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lat += dlat;
//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lng += dlng;
//       poly.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//     return poly;
//   }
//
//   void _setPolyline(List<LatLng> points) {
//     if (points.isEmpty) {
//       polylines.clear();
//       return;
//     }
//
//     // Draw shadow + main polyline for a nicer look
//     final shadow = Polyline(
//       polylineId: const PolylineId("driver_route_shadow"),
//       color: FColors.secondaryColor,
//       width: 6,
//       points: points,
//       startCap: Cap.roundCap,
//       endCap: Cap.roundCap,
//       jointType: JointType.round,
//     );
//
//     final main = Polyline(
//       polylineId: const PolylineId("driver_route_main"),
//       color: FColors.secondaryColor,
//       width: 6,
//       points: points,
//       startCap: Cap.roundCap,
//       endCap: Cap.roundCap,
//       jointType: JointType.round,
//     );
//
//     polylines.value = {shadow, main};
//   }
//
//   LatLngBounds? _boundsFromLatLngList(List<LatLng> list) {
//     if (list.isEmpty) return null;
//     double x0 = list.first.latitude, x1 = list.first.latitude;
//     double y0 = list.first.longitude, y1 = list.first.longitude;
//     for (LatLng latLng in list) {
//       if (latLng.latitude > x1) x1 = latLng.latitude;
//       if (latLng.latitude < x0) x0 = latLng.latitude;
//       if (latLng.longitude > y1) y1 = latLng.longitude;
//       if (latLng.longitude < y0) y0 = latLng.longitude;
//     }
//     return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
//   }
//
//   /// ===================== MARKERS AND STOPS =====================
//   void _placeStaticMarkersFromRideInfo() {
//     // Remove existing static markers first
//     driverMarkers.removeWhere(
//           (k, v) => k == 'pickup' || k.startsWith('stop_') || k == 'dropoff',
//     );
//
//     if (rideInfo.value == null) return;
//
//     final pickup = rideInfo.value!.pickup;
//     if (pickup != null) {
//       final pickPos = LatLng(
//         (pickup['lat'] as num).toDouble(),
//         (pickup['lng'] as num).toDouble(),
//       );
//       driverMarkers['pickup'] = Marker(
//         markerId: const MarkerId('pickup'),
//         position: pickPos,
//         icon:
//         _pickupIcon ??
//             BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//         infoWindow: InfoWindow(
//           title: pickup['address']?.toString() ?? 'Pickup',
//         ),
//       );
//     }
//
//     final dropoffs = rideInfo.value!.dropoffs ?? [];
//     for (int i = 0; i < dropoffs.length; i++) {
//       final df = dropoffs[i];
//       final pos = LatLng(
//         (df['lat'] as num).toDouble(),
//         (df['lng'] as num).toDouble(),
//       );
//
//       if (i == dropoffs.length - 1) {
//         driverMarkers['dropoff'] = Marker(
//           markerId: const MarkerId('dropoff'),
//           position: pos,
//           icon:
//           _dropIcon ??
//               BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//           infoWindow: InfoWindow(title: df['address']?.toString() ?? 'Dropoff'),
//         );
//       } else {
//         driverMarkers['stop_$i'] = Marker(
//           markerId: MarkerId('stop_$i'),
//           position: pos,
//           icon:
//           _stopIcon ??
//               BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
//           infoWindow: InfoWindow(
//             title: df['address']?.toString() ?? 'Stop ${i + 1}',
//           ),
//         );
//       }
//     }
//     driverMarkers.refresh();
//   }
//
//   /// ===================== MARKER ICON LOADING =====================
//   Future<BitmapDescriptor> _bitmapFromAsset(
//       String path, {
//         int width = 100,
//       }) async {
//     try {
//       final byteData = await rootBundle.load(path);
//       final codec = await ui.instantiateImageCodec(
//         byteData.buffer.asUint8List(),
//         targetWidth: width,
//       );
//       final frame = await codec.getNextFrame();
//       final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
//       return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
//     } catch (e) {
//       print('❌ Error loading marker icon: $e');
//       return BitmapDescriptor.defaultMarker;
//     }
//   }
//
//   Future<void> _loadMarkerIcons() async {
//     try {
//       _driverIcon = await _bitmapFromAsset('assets/images/car.png', width: 80);
//       _pickupIcon = await _bitmapFromAsset(
//         'assets/images/position_marker2.png',
//         width: 72,
//       );
//       _stopIcon = await _bitmapFromAsset('assets/images/place.png', width: 64);
//       _dropIcon = await _bitmapFromAsset('assets/images/place.png', width: 72);
//       print("✅ All icons loaded");
//     } catch (e) {
//       print('❌ Failed to load marker icons: $e');
//     }
//   }
//
//   /// ===================== CANCELLATION / UI HELPERS (UNCHANGED) =====================
//   Future<void> showCancelReasons(BuildContext context) async {
//     final screenWidth = Get.width;
//     final baseWidth = 440.0;
//     double sw(double w) => w * screenWidth / baseWidth;
//     final cancellationReasons = [
//       "Driver not responding",
//       "Driver not at pickup",
//       "Wrong pickup location",
//       "Driver refused",
//       "Change of plans",
//       "Emergency",
//       "Other reason",
//     ];
//     Get.bottomSheet(
//       Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(sw(20)),
//             topRight: Radius.circular(sw(20)),
//           ),
//         ),
//         padding: EdgeInsets.symmetric(horizontal: sw(20), vertical: sw(20)),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               "Cancel Ride",
//               style: TextStyle(
//                 fontSize: sw(18),
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             SizedBox(height: sw(10)),
//             Text(
//               "Please select a reason for cancellation:",
//               style: TextStyle(fontSize: sw(14), color: Colors.grey[600]),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: sw(20)),
//             ...cancellationReasons
//                 .map(
//                   (reason) => Column(
//                 children: [
//                   ListTile(
//                     title: Text(
//                       reason,
//                       style: TextStyle(
//                         fontSize: sw(14),
//                         color: Colors.black,
//                       ),
//                     ),
//                     onTap: () {
//                       Get.back();
//                       _confirmCancellation(reason);
//                     },
//                   ),
//                   Divider(height: sw(1), color: Colors.grey[300]),
//                 ],
//               ),
//             )
//                 .toList(),
//             SizedBox(height: sw(20)),
//             SizedBox(
//               width: double.infinity,
//               height: sw(48),
//               child: ElevatedButton(
//                 onPressed: () => Get.back(),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: FColors.primaryColor,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(sw(14)),
//                   ),
//                 ),
//                 child: Text(
//                   "Continue Waiting",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                     fontSize: sw(14),
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: sw(10)),
//           ],
//         ),
//       ),
//       isScrollControlled: true,
//     );
//   }
//
//   void _confirmCancellation(String reason) =>
//       _getCurrentLocationAndCancel(reason);
//
//   Future<void> _getCurrentLocationAndCancel(String reason) async {
//     try {
//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       final userLocation = LatLng(position.latitude, position.longitude);
//       _cancelRide(reason, userLocation);
//     } catch (e) {
//       print('❌ Error getting current location: $e');
//       final fallbackLocation = currentPosition.value ?? LatLng(0, 0);
//       _cancelRide(reason, fallbackLocation);
//     }
//   }
//
//   Future<void> _cancelRide(
//       String cancellationReason,
//       LatLng userLocation,
//       ) async {
//     try {
//       if (thisRideId == null) {
//         showError('Ride id missing');
//         return;
//       }
//       if ((userLocation.latitude == 0.0 && userLocation.longitude == 0.0)) {
//         showError(
//           'Unable to get your current location. Please check location permissions.',
//         );
//         return;
//       }
//       isCancelling.value = true;
//       Get.dialog(
//         const Center(child: CircularProgressIndicator()),
//         barrierDismissible: false,
//       );
//       final body = {
//         'cancellationReason': cancellationReason,
//         'location': {
//           'lat': userLocation.latitude,
//           'lng': userLocation.longitude,
//         },
//       };
//       final res = await FHttpHelper.post(
//         'ride/ride-cancelled/$thisRideId',
//         body,
//       );
//       print('✅ ride-cancelled response: $res');
//       showSuccess('Ride cancelled successfully');
//       PusherBackgroundService().stopBackgroundMode();
//       Get.back();
//       isCancelling.value = false;
//       Get.offAllNamed('/ride-type');
//     } catch (e) {
//       print('❌ ride-cancelled error: $e');
//       Get.back();
//       isCancelling.value = false;
//       showError('Failed to cancel ride');
//     }
//   }
//
//   @override
//   void onClose() {
//     _waitingTimer?.cancel();
//     _animationTimer?.cancel(); // NEW: Cancel animation timer
//     fareController.dispose();
//     PusherBackgroundService().stopBackgroundMode();
//     super.onClose();
//   }
//
// // ✅ IMPROVED: Save ride with proper data structure
//   void onNewRequest() async {
//     try {
//       // Check if user can add more rides
//       if (!StorageService.canAddMoreRides()) {
//         FSnackbar.show(
//           title: 'Limit Reached',
//           message: 'You can only have ${StorageService.kMaxActiveRides} active rides at a time',
//           isError: true,
//         );
//         return;
//       }
//
//       // Get current ride data with complete information
//       final currentRideData = {
//         'rideId': rideId,
//         'driverId': driverId,
//         'rideArgs': rideArgs,
//         'rideInfo': _rideInfoToMap(rideInfo.value!), // Convert to serializable map
//         'driver': rideInfo.value?.driver,
//         'pickup': rideInfo.value?.pickup,
//         'dropoffs': rideInfo.value?.dropoffs,
//         'fareOffered': rideInfo.value?.fareOffered,
//         'estimated_drop_time': rideInfo.value?.estimated_drop_time,
//         'eta': rideInfo.value?.eta,
//         'distance': rideInfo.value?.distance,
//         'savedFrom': 'DriversWaitingScreen',
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       };
//
//       // Save to active rides
//       await StorageService.saveActiveRide(rideId!, currentRideData);
//
//       // Show success message
//       FSnackbar.show(
//         title: 'Ride Saved',
//         message: 'You can now request another ride. Access active rides from the home screen.',
//       );
//
//       // Setup listener for this ride in RideTypeController
//       _setupRideListenerInBackground();
//
//       // Navigate back to RideTypeScreen
//       _navigateToRideType();
//
//     } catch (e) {
//       print('❌ Error saving active ride: $e');
//       FSnackbar.show(
//         title: 'Error',
//         message: 'Failed to save current ride',
//         isError: true,
//       );
//     }
//   }
//
// // ✅ NEW: Convert RideInfo to serializable map
//   Map<String, dynamic> _rideInfoToMap(DriverRideInfo rideInfo) {
//     return {
//       'rideId': rideInfo.rideId,
//       'driver': rideInfo.driver,
//       'pickup': rideInfo.pickup,
//       'dropoffs': rideInfo.dropoffs,
//       'fareOffered': rideInfo.fareOffered,
//       'estimated_drop_time': rideInfo.estimated_drop_time,
//       'eta': rideInfo.eta,
//       'distance': rideInfo.distance,
//       'passengerId': StorageService.getSignUpResponse()!.userId,
//     };
//   }
//
// // ✅ NEW: Setup ride listener in background
//   void _setupRideListenerInBackground() {
//     // This ensures the ride listener is set up even if RideTypeController isn't active
//     final rideTypeController = Get.isRegistered<RideTypeController>()
//         ? Get.find<RideTypeController>()
//         : null;
//
//     if (rideTypeController != null) {
//       rideTypeController.listenToActiveRideChannel(rideId!);
//     } else {
//       // If RideTypeController isn't active, the listener will be set up when it initializes
//       print('ℹ️ RideTypeController not active, listener will be setup on init');
//     }
//   }
// // ✅ NEW: Navigate to RideTypeScreen and clear previous controllers
//   void _navigateToRideType() {
//     try {
//       // Clear all previous ride controllers except this one
//       Get.delete<DropOffController>(force: true);
//       Get.delete<RideBookingController>(force: true);
//       Get.delete<AvailableDriversController>(force: true);
//       Get.delete<AvailableBidsController>(force: true);
//
//       print('🧹 Cleared previous ride controllers, keeping current DriversWaitingController');
//
//       // Navigate to RideTypeScreen
//       Get.to(() => RideTypeScreen());
//
//     } catch (e) {
//       print('❌ Navigation error: $e');
//       Get.offAll(() => RideTypeScreen());
//     }
//   }
//
//   void switchToRide(Map<String, dynamic> ride) {
//     final rideId = ride['rideId'];
//     final rideData = ride['rideData'];
//
//     // Update controller with new ride data
//     final c = Get.find<DriversWaitingController>();
//     c.rideId = rideId;
//     c.rideInfo.value = DriverRideInfo.fromArgs(rideData);
//     c.rideArgs = Map<String, dynamic>.from(rideData['rideArgs'] ?? {});
//
//     // Restart background service for this ride
//     final passengerId = StorageService.getSignUpResponse()?.userId;
//     if (passengerId != null) {
//       PusherBackgroundService().startBackgroundMode(
//         passengerId,
//         userType: 'passenger',
//         rideId: rideId,
//       );
//     }
//
//     // Refresh UI
//     c.updateView.value = !c.updateView.value;
//   }
//
//
// }
