import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';
import '../../../../utils/http/http_client.dart';
import '../models/ride_info.dart';

class GoToPickupController extends BaseController {
  final currentPosition = Rxn<LatLng>();
  final driverMarkers = <String, Marker>{}.obs;
  final polylines = <Polyline>{}.obs;
  final fareController = TextEditingController();

  GoogleMapController? _mapController;

  // 🔄 InDrive Animation Control
  LatLng? _lastDriverPosition;
  bool _isCameraFollowing = true;
  bool _isAnimating = false;

  // Icons
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropoffIcon;

  // Ride info
  final RxString passengerId = ''.obs;
  final RxString passengerName = ''.obs;
  final RxString pickupAddress = ''.obs;
  final RxString dropoffAddress = ''.obs;
  final RxString estimatedArrivalTime = ''.obs;
  final RxString estimatedDropoffTime = ''.obs;
  final RxString estimatedDistance = ''.obs;
  final RxInt fare = 0.obs;
  final RxString phone = ''.obs;
  final RxString passengerProfileUrl = ''.obs;
  final RxString passengerRating = '0'.obs;

  final RxBool rideStarted = false.obs;
  final RxBool isStartingRide = false.obs;
  final RxBool isCompletingRide = false.obs;
  final RxBool isCancelingRide = false.obs;

  // Pusher
  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
  String? _rideId;
  bool _subscribedToRideChannel = false;

  // Parsed ride model
  RideInfo? rideInfo;

  @override
  void onInit() async {
    super.onInit();
    _parseArgs();
    await _loadMarkerIcons();
    _placeStaticMarkersFromRideInfo();
    _subscribeToRideIfNeeded();
    _getCurrentLocation();
  }

  @override
  void onClose() {
    if (_subscribedToRideChannel && _rideId != null) {
      _pusherManager.unsubscribeSafely('ride-$_rideId');
      _subscribedToRideChannel = false;
    }
    _mapController?.dispose();
    super.onClose();
  }

  void _parseArgs() {
    final raw = Get.arguments;
    print("Args received from previous screen: $raw");

    if (raw == null) return;

    Map<String, dynamic> args;
    if (raw is Map<String, dynamic>) {
      args = Map<String, dynamic>.from(raw);
    } else if (raw is Map) {
      args = Map<String, dynamic>.from(raw);
    } else {
      args = {};
    }

    if (args.isEmpty) return;

    final rideMap = args['rideData'] is Map
        ? Map<String, dynamic>.from(args['rideData'])
        : args;

    rideInfo = RideInfo.fromMap(rideMap);
    _rideId = rideInfo?.rideId;

    passengerId.value = rideInfo!.passengerId;
    passengerName.value = rideInfo?.passengerName ?? passengerName.value;
    pickupAddress.value = rideInfo?.pickupAddress ?? pickupAddress.value;
    phone.value = rideInfo?.phone ?? phone.value;
    passengerProfileUrl.value = rideInfo?.passengerProfileImage ?? '';
    passengerRating.value = rideInfo?.passengerRating ?? '0';

    estimatedArrivalTime.value = rideInfo?.estimatedArrivalTime ?? '';
    estimatedDropoffTime.value = rideInfo?.estimatedDropoffTime ?? '';
    estimatedDistance.value = rideInfo?.estimatedDistance ?? '';
    fare.value = (rideInfo?.fare != null) ? rideInfo!.fare!.toInt() : fare.value;
  }

  /// ===================== 🔔 DRIVER LOCATION SUBSCRIPTION =====================
  Future<void> _subscribeToRideChannel() async {
    if (_rideId == null) return;
    if (_subscribedToRideChannel) return;

    try {
      await executeWithRetry(() async {
        await _pusherManager.subscribeOnce(
          'ride-$_rideId',
          events: {
            'pusher:subscription_succeeded': (data) {
              print("✅ Successfully subscribed to ride-$_rideId");
            },

            'driver-location': (data) async {
              print("🚗 DRIVER LOCATION EVENT: $data");

              double lat = double.tryParse(data['lat'].toString()) ?? 0.0;
              double lng = double.tryParse(data['lng'].toString()) ?? 0.0;

              if (lat == 0.0 || lng == 0.0) {
                print("❌ INVALID DRIVER COORDINATES");
                return;
              }

              final newPos = LatLng(lat, lng);
              print("📍 New driver position: $newPos");

              // ✅ FIXED: InDrive-style smooth animation
              if (_lastDriverPosition == null) {
                _lastDriverPosition = newPos;
                _updateDriverMarker(newPos);
              } else {
                // 🧭 Smooth animation between positions
                _animateDriverMarker(_lastDriverPosition!, newPos);
              }
              _lastDriverPosition = newPos;

              final dropoffs = rideInfo?.dropoffs ?? [];

              if (!rideStarted.value) {
                // ✅ Driver to Pickup route - Google Maps style
                if (rideInfo?.pickupLat != null && rideInfo?.pickupLng != null) {
                  final pickupPos = LatLng(rideInfo!.pickupLat!, rideInfo!.pickupLng!);
                  await _showRouteLikeGoogleMaps(newPos, pickupPos);
                }
              } else {
                // ✅ Driver to Dropoffs route - Google Maps style
                if (dropoffs.isNotEmpty) {
                  final firstDropoff = dropoffs.first;
                  final dropoffPos = LatLng(
                    (firstDropoff['lat'] as num).toDouble(),
                    (firstDropoff['lng'] as num).toDouble(),
                  );
                  await _showRouteLikeGoogleMaps(newPos, dropoffPos);
                }
              }

              // ✅ InDrive-style camera following
              if (_isCameraFollowing && _mapController != null) {
                await _mapController!.animateCamera(
                  CameraUpdate.newLatLng(newPos),
                );
              }
            },

            "new-message": (data) {
              print("💬 New message received: $data");
              if(StorageService.getSignUpResponse()!.userId == data['receiverId'])
                FSnackbar.show(title: "New Message", message: data['text'].toString());
            },

            "ride-cancelled": (data) {
              print("❌ Ride cancelled: $data");
              showError('Ride cancelled');
              Get.offAllNamed('/go-online');
            },
          },
        );

        _subscribedToRideChannel = true;
      });
    } catch (e) {
      print('❌ Failed to subscribe to ride channel: $e');
      showError('Failed to subscribe to ride updates');
    }
  }

  /// ===================== 🧭 SMOOTH DRIVER MARKER MOVEMENT =====================
  Future<void> _animateDriverMarker(LatLng from, LatLng to) async {
    if (_isAnimating) return;
    _isAnimating = true;

    const int steps = 30;
    const Duration stepDuration = Duration(milliseconds: 50);

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      final lat = from.latitude + (to.latitude - from.latitude) * (i / steps);
      final lng = from.longitude + (to.longitude - from.longitude) * (i / steps);
      final intermediate = LatLng(lat, lng);

      _updateDriverMarker(intermediate);
    }

    _isAnimating = false;
  }

  void _updateDriverMarker(LatLng position) {
    driverMarkers["driver"] = Marker(
      markerId: const MarkerId("driver"),
      position: position,
      rotation: _calculateBearing(_lastDriverPosition, position),
      zIndex: 2,
      flat: true,
      anchor: const Offset(0.5, 0.5),
      icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    driverMarkers.refresh();
  }

  double _calculateBearing(LatLng? from, LatLng to) {
    if (from == null) return 0.0;
    return Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// ===================== 🗺️ GOOGLE MAPS-STYLE ROUTE DISPLAY =====================
  Future<void> _showRouteLikeGoogleMaps(LatLng origin, LatLng destination) async {
    try {
      // Step 1: Show close-up of starting point (Google Maps behavior)
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: origin,
              zoom: 17.0, // Close-up view
              bearing: 0,
              tilt: 0,
            ),
          ),
          duration: Duration(milliseconds: 800),
        );
      }

      // Step 2: Fetch detailed route information
      final routeInfo = await _fetchDetailedRoute(origin, destination);
      final polylinePoints = routeInfo['polyline'] as List<LatLng>;

      // Step 3: Set the polyline
      _setPolyline(polylinePoints);

      // Step 4: Show route overview after a brief delay (like Google Maps)
      await Future.delayed(Duration(milliseconds: 1000));

      // Step 5: Zoom out to show entire route
      await _fitMapToBoundsLikeGoogleMaps(polylinePoints);

      // Step 6: Update UI with route info
      estimatedDistance.value = routeInfo['distance'].toString();
      estimatedArrivalTime.value = routeInfo['duration'].toString();

    } catch (e) {
      print('❌ Error showing route: $e');
      // Fallback to basic route display
      final polyPoints = await _fetchRoutePolylineWithRetry(origin, destination);
      _setPolyline(polyPoints);
      _fitMapToBoundsLikeGoogleMaps(polyPoints);
    }
  }

  Future<Map<String, dynamic>> _fetchDetailedRoute(LatLng origin, LatLng destination) async {
    const apiKey = "AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4";
    final url = "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&mode=driving"
        "&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Failed to fetch route');

    final data = jsonDecode(response.body);
    if (data['routes'].isEmpty) throw Exception('No route found');

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

    final distance = Geolocator.distanceBetween(
      bounds.southwest.latitude, bounds.southwest.longitude,
      bounds.northeast.latitude, bounds.northeast.longitude,
    );

    // ✅ Google Maps-style zoom logic
    double zoomLevel = _calculateOptimalZoom(distance, routePoints.length);
    int animationDuration = _calculateAnimationDuration(distance);

    final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
    final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(centerLat, centerLng),
          zoom: zoomLevel,
        ),
      ),
      duration: Duration(milliseconds: animationDuration),
    );
  }

  double _calculateOptimalZoom(double distance, int pointCount) {
    // ✅ Smart zoom calculation based on distance and route complexity
    if (distance < 1000) return 17.0; // Very close - street detail
    if (distance < 5000) return 14.0; // Neighborhood level
    if (distance < 20000) return 12.0; // City level
    if (distance < 50000) return 10.0; // Regional level
    return 8.0; // Long distance - overview
  }

  int _calculateAnimationDuration(double distance) {
    // ✅ Smooth animations - longer distances get slower animations
    if (distance < 1000) return 500;
    if (distance < 5000) return 800;
    if (distance < 20000) return 1200;
    return 1500;
  }

  // ---------------- YOUR ORIGINAL ROUTE + MAP LOGIC (UPDATED) ----------------
  Future<List<LatLng>> _fetchRoutePolylineWithRetry(LatLng o, LatLng d) async {
    try {
      return await executeWithRetryAndReturn(() => _fetchRoutePolyline(o, d), maxRetries: 2);
    } catch (_) {
      return [];
    }
  }

  Future<List<LatLng>> _buildRouteThroughPointsWithRetry(List<LatLng> pts) async {
    try {
      return await executeWithRetryAndReturn(() => _buildRouteThroughPoints(pts), maxRetries: 2);
    } catch (_) {
      return [];
    }
  }

  Future<List<LatLng>> _fetchRoutePolyline(LatLng o, LatLng d) async {
    const apiKey = "AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4";
    final url = "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${o.latitude},${o.longitude}"
        "&destination=${d.latitude},${d.longitude}&mode=driving&key=$apiKey";
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) return [];
    final data = jsonDecode(r.body);
    if (data['routes'].isEmpty) return [];
    final pts = data['routes'][0]['overview_polyline']['points'];
    return _decodePolyline(pts);
  }

  Future<List<LatLng>> _buildRouteThroughPoints(List<LatLng> pts) async {
    if (pts.length < 2) return [];

    final List<LatLng> fullRoute = [];

    for (int i = 0; i < pts.length - 1; i++) {
      final segment = await _fetchRoutePolyline(pts[i], pts[i + 1]);
      if (segment.isNotEmpty) {
        if (fullRoute.isNotEmpty) {
          fullRoute.addAll(segment.skip(1));
        } else {
          fullRoute.addAll(segment);
        }
      }
    }

    return fullRoute;
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

  void _setPolyline(List<LatLng> pts) {
    if (pts.isEmpty) {
      polylines.clear();
      return;
    }
    polylines.value = {
      Polyline(
        polylineId: const PolylineId("driver_route"),
        color: FColors.secondaryColor,
        width: 5,
        points: pts,
      )
    };
  }

  LatLngBounds? _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) return null;
    double x0 = list.first.latitude, x1 = list.first.latitude;
    double y0 = list.first.longitude, y1 = list.first.longitude;
    for (var l in list) {
      if (l.latitude > x1) x1 = l.latitude;
      if (l.latitude < x0) x0 = l.latitude;
      if (l.longitude > y1) y1 = l.longitude;
      if (l.longitude < y0) y0 = l.longitude;
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  /// ===================== MARKER ICONS =====================
  Future<void> _loadMarkerIcons() async {
    try {
      await executeWithRetry(() async {
        _driverIcon = await _bitmapFromAsset(
          'assets/images/car.png',
          width: 100,
        );
        _pickupIcon = await _bitmapFromAsset(
          'assets/images/position_marker2.png',
          width: 100,
        );
        _dropoffIcon = await _bitmapFromAsset(
          'assets/images/place.png',
          width: 100,
        );
        print("✅ All icons loaded");
      });
    } catch (e) {
      print('❌ Failed to load marker icons: $e');
    }
  }

  Future<BitmapDescriptor> _bitmapFromAsset(String path, {int width = 100}) async {
    try {
      return await executeWithRetryAndReturn(() async {
        final byteData = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
          byteData.buffer.asUint8List(),
          targetWidth: width,
        );
        final frame = await codec.getNextFrame();
        final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
      });
    } catch (e) {
      print('❌ Error loading marker icon: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// ===================== STATIC MARKERS =====================
  void _placeStaticMarkersFromRideInfo() {
    driverMarkers.removeWhere((k, v) => k == 'pickup' || k.startsWith('stop_') || k == 'dropoff');

    if (rideInfo == null) return;

    // Pickup marker
    if (rideInfo!.pickupLat != null && rideInfo!.pickupLng != null) {
      final pickPos = LatLng(rideInfo!.pickupLat!, rideInfo!.pickupLng!);
      driverMarkers['pickup'] = Marker(
        markerId: const MarkerId('pickup'),
        position: pickPos,
        icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: pickupAddress.value.isNotEmpty ? pickupAddress.value : 'Pickup',
        ),
      );
    }

    // Dropoff markers
    final dropoffs = rideInfo!.dropoffs ?? [];
    for (int i = 0; i < dropoffs.length; i++) {
      final df = dropoffs[i];
      final pos = LatLng(
        (df['lat'] as num).toDouble(),
        (df['lng'] as num).toDouble(),
      );

      driverMarkers['dropoff_$i'] = Marker(
        markerId: MarkerId('dropoff_$i'),
        position: pos,
        icon: _dropoffIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Stop ${i + 1}'),
      );
    }

    driverMarkers.refresh();
    _moveCameraToBounds();
  }

  /// ===================== LOCATION & CAMERA =====================
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      currentPosition.value = LatLng(position.latitude, position.longitude);
      _lastDriverPosition = currentPosition.value;

      // ✅ Create initial driver marker
      _updateDriverMarker(currentPosition.value!);

      _moveCameraToBounds();
    } catch (e) {
      print('❌ Error getting current location: $e');
    }
  }

  void onMapCreated(GoogleMapController c) {
    _mapController = c;
    _moveCameraToBounds();
  }

  Future<void> _moveCameraToBounds() async {
    if (_mapController == null) return;

    final driver = currentPosition.value;
    final pickup = rideInfo?.pickupLat != null && rideInfo?.pickupLng != null
        ? LatLng(rideInfo!.pickupLat!, rideInfo!.pickupLng!)
        : null;

    if (driver != null && pickup != null) {
      await _fitMapToBoundsLikeGoogleMaps([driver, pickup]);
    } else if (driver != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(driver, 14));
    } else if (pickup != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pickup, 14));
    }
  }

  // ----------------- YOUR ORIGINAL API METHODS (UNCHANGED) -----------------
  Future<void> callPhone() async {
    final uri = Uri(scheme: 'tel', path: phone.value);
    if (await canLaunchUrl(uri)) {
      launchUrl(Uri(scheme: 'tel', path: phone.value));
    } else {
      showError('Your device cannot make calls.');
    }
  }

  Future<void> markDriverArrived() async {
    if (_rideId == null) {
      showError('Ride id missing');
      return;
    }
    try {
      await executeWithRetry(() async {
        final response = await FHttpHelper.post('ride/driver-arrived/$_rideId', {});
        print("Driver Arrived Api Response : "+response.toString());
        FSnackbar.show(title: 'Reported',message: 'Your arrival at location reported');
      });
    } catch (e) {
      print('❌ markDriverArrived error: $e');
      showError('Failed to report arrival');
    }
  }

  Future<void> markDriverStarted() async {
    if (_rideId == null) {
      showError('Ride id missing');
      return;
    }
    try {
      isStartingRide.value = true;
      await executeWithRetry(() async {
        final response = await FHttpHelper.post('ride/driver-started/$_rideId', {});
        print("Driver Started Api Response : "+response.toString());
        rideStarted.value = true;
        showSuccess('Ride started');

        // ✅ Rebuild route for dropoffs only when ride starts
        if (currentPosition.value != null) {
          final dropoffs = rideInfo?.dropoffs ?? [];
          if (dropoffs.isNotEmpty) {
            final List<LatLng> routePoints = [currentPosition.value!];
            for (var df in dropoffs) {
              routePoints.add(LatLng(
                (df['lat'] as num).toDouble(),
                (df['lng'] as num).toDouble(),
              ));
            }
            final multiStopRoute = await _buildRouteThroughPointsWithRetry(routePoints);
            _setPolyline(multiStopRoute);
            await _fitMapToBoundsLikeGoogleMaps(routePoints);
          }
        }
      });
    } catch (e) {
      print('❌ markDriverStarted error: $e');
      showError('Failed to start ride');
    } finally {
      isStartingRide.value = false;
    }
  }

  Future<void> markDriverEnded() async {
    if (_rideId == null) {
      showError('Ride id missing');
      return;
    }

    final body = {
      "onCompletionDistance": 23,
      "ride_duration": 11,
    };

    try {
      isCompletingRide.value = true;
      await executeWithRetry(() async {
        final response = await FHttpHelper.post('ride/driver-ended/$_rideId', body);
        print("Driver Ended Api Response: $response");
        showSuccess('Ride completed successfully');

        Get.offAllNamed('/rate', arguments: {
          'userId': passengerId.value,
          'rideId': _rideId,
          'name': passengerName.value,
          'image': passengerProfileUrl.value,
        });
      });
    } catch (e) {
      print('❌ markDriverEnded error: $e');
      showError('Failed to complete ride');
    } finally {
      isCompletingRide.value = false;
    }
  }

  Future<void> _subscribeToRideIfNeeded() async {
    if (_rideId != null) {
      await _subscribeToRideChannel();
    }
  }

  // ----------------- YOUR ORIGINAL CANCELLATION METHODS (UNCHANGED) -----------------
  Future<void> showCancelReasons(BuildContext context) async {
    final screenWidth = Get.width;
    final screenHeight = Get.height;
    final baseWidth = 440.0;

    double sw(double w) => w * screenWidth / baseWidth;

    final cancellationReasons = [
      "Passenger not responding",
      "Passenger not at pickup",
      "Wrong pickup location",
      "Passenger refused",
      "Emergency",
      "Other reason"
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
              style: TextStyle(
                fontSize: sw(14),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: sw(20)),
            ...cancellationReasons.map((reason) => Column(
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
            )).toList(),
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

  void _confirmCancellation(String reason) {
    _getCurrentLocationAndCancel(reason);
  }

  Future<void> _getCurrentLocationAndCancel(String reason) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLocation = LatLng(position.latitude, position.longitude);

      Future.delayed(Duration(milliseconds: 300), () {
        _cancelRide(reason, userLocation);
      });
    } catch (e) {
      print('❌ Error getting current location: $e');
      final fallbackLocation = currentPosition.value ?? LatLng(0, 0);
      _cancelRide(reason, fallbackLocation);
    }
  }

  Future<void> _cancelRide(String cancellationReason, LatLng userLocation) async {
    try {
      if (_rideId == null) {
        showError('Ride id missing');
        return;
      }

      final body = {
        'cancellationReason': cancellationReason,
        'location': {
          'lat': userLocation.latitude,
          'lng': userLocation.longitude,
        },
      };

      if ((userLocation.latitude == 0.0 && userLocation.longitude == 0.0)) {
        showError('Unable to get your current location. Please check location permissions.');
        return;
      }

      isCancelingRide.value = true;

      final res = await FHttpHelper.post(
        'ride/ride-cancelled/$_rideId',
        body,
      );

      print('✅ ride-cancelled response: $res');
      showSuccess('Ride cancelled successfully');

      Get.offAllNamed('/go-online');

    } catch (e) {
      print('❌ ride-cancelled error: $e');
      showError('Failed to cancel ride');
    } finally {
      isCancelingRide.value = false;
    }
  }
}