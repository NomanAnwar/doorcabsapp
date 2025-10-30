import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
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
import '../../../shared/services/storage_service.dart';
import '../models/driver_ride_info.dart';

class DriversWaitingController extends BaseController {
  final currentPosition = Rxn<LatLng>();
  final driverMarkers = <String, Marker>{}.obs;
  final polylines = <Polyline>{}.obs;
  final fareController = TextEditingController();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

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

  // 🔄 InDrive Animation Control
  LatLng? _lastDriverPosition;
  bool _isCameraFollowing = true;
  bool _isAnimating = false;

  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _stopIcon;
  BitmapDescriptor? _dropIcon;


  @override
  void onInit() async {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    rideArgs = Map<String, dynamic>.from(Get.arguments ?? {});
    print("📌 Ride args in Drivers Waiting Controller: ${rideArgs['rideType']}");

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

    // ✅ FIXED: Create initial driver marker
    if (rideInfo.value?.pickup != null) {
      currentPosition.value = LatLng(
        (rideInfo.value!.pickup!['lat'] as num).toDouble(),
        (rideInfo.value!.pickup!['lng'] as num).toDouble(),
      );

      // Create initial driver marker at pickup location
      _updateDriverMarker(currentPosition.value!);
    } else {
      currentPosition.value = const LatLng(31.5204, 74.3587);
    }

    if (rideInfo.value != null && (rideInfo.value!.rideId?.isNotEmpty ?? false)) {
      _subscribeToDriverLocation(rideInfo.value!.rideId!);
    }
  }

  void onMapCreated(GoogleMapController c) {
    _mapController = c;

    // ✅ USE GOOGLE MAPS-STYLE BOUNDS FITTING
    final pickup = rideInfo.value?.pickup;
    if (currentPosition.value != null && pickup != null) {
      final pickupPos = LatLng(
        (pickup['lat'] as num).toDouble(),
        (pickup['lng'] as num).toDouble(),
      );
      _fitMapToBoundsLikeGoogleMaps([currentPosition.value!, pickupPos]);
    } else if (currentPosition.value != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          target: currentPosition.value!,
          zoom: 17.0, // Google Maps-style initial zoom
        )),
      );
    }
  }

  /// ===================== 🔔 DRIVER LOCATION SUBSCRIPTION =====================
  void _subscribeToDriverLocation(String rideId) {
    _pusherManager.subscribeOnce(
      "ride-$rideId",
      events: {
        "driver-location": (data) async {
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

          // ✅ FIXED: Google Maps-style smooth animation
          if (_lastDriverPosition == null) {
            _lastDriverPosition = newPos;
            _updateDriverMarker(newPos);
          } else {
            // 🧭 Smooth animation between positions
            _animateDriverMarker(_lastDriverPosition!, newPos);
          }
          _lastDriverPosition = newPos;

          final pickup = rideInfo.value?.pickup;
          final dropoffs = rideInfo.value?.dropoffs ?? [];

          // ✅ FIX: Define pickupPos here so it's available in both scopes
          LatLng? pickupPos;
          if (pickup != null) {
            pickupPos = LatLng(
              (pickup['lat'] as num).toDouble(),
              (pickup['lng'] as num).toDouble(),
            );
          }

          if (!rideStarted.value) {
            // ✅ Driver to Pickup route - Google Maps style
            if (pickupPos != null) {
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

          // ✅ Google Maps-style camera following
          if (_isCameraFollowing && _mapController != null) {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLng(newPos),
            );
          }
        },

        "driver-arrived": (data) {
          print("📢 Driver has arrived at pickup: $data");
          showSuccess("Driver arrived at your pick up location.");
        },

        "ride-started": (data) {
          print("🚦 Ride started: $data");
          rideStarted.value = true;

          showSuccess("Enjoy your trip!");

          updateView.value = true;

          _placeStaticMarkersFromRideInfo();

          // ✅ Rebuild route for dropoffs with Google Maps style
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
              _showRouteLikeGoogleMaps(pts.first, pts.last);
            }
          }
        },

        "ride-ended": (data) {
          print("🏁 Ride ended: $data");
          showSuccess('Ride completed successfully');

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

          Get.offAllNamed('/rate', arguments: {
            'userId': driverId,
            'rideId': rideId,
            'name': driverName,
            'image': driverImage,
          });
        },

        "ride-cancelled": (data) {
          print("❌ Ride cancelled: $data");
          Get.offAllNamed('/ride-type');
        },

        "new-message": (data) {
          print("💬 New message received: $data");
          if(StorageService.getSignUpResponse()!.userId == data['receiverId'])
            FSnackbar.show(title: "New Message", message: data['text'].toString());
        },
      },
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

  // ---------------- YOUR ORIGINAL ROUTE + MAP LOGIC (UPDATED) ----------------
  Future<List<LatLng>> _fetchRoutePolylineWithRetry(LatLng origin, LatLng destination) async {
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

  Future<List<LatLng>> _buildRouteThroughPointsWithRetry(List<LatLng> pts) async {
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
        _stopIcon = await _bitmapFromAsset('assets/images/place.png', width: 80);
        _dropIcon = await _bitmapFromAsset(
          'assets/images/place.png',
          width: 100,
        );
        print("✅ All icons loaded");
      });
    } catch (e) {
      print('❌ Failed to load marker icons: $e');
    }
  }

  Future<List<LatLng>> _fetchRoutePolyline(LatLng origin, LatLng destination) async {
    const apiKey = "AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4";
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception("Directions API failed");

    final data = jsonDecode(response.body);
    if (data == null || data['routes'] == null || data['routes'].isEmpty) {
      return [];
    }
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
    final polyline = Polyline(
      polylineId: const PolylineId("driver_route"),
      color: FColors.secondaryColor,
      width: 5,
      points: points,
    );
    polylines.value = {polyline};
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
        icon:
        _pickupIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
          icon:
          _dropIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: df['address']?.toString() ?? 'Dropoff'),
        );
      } else {
        driverMarkers['stop_$i'] = Marker(
          markerId: MarkerId('stop_$i'),
          position: pos,
          icon:
          _stopIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(
            title: df['address']?.toString() ?? 'Stop ${i + 1}',
          ),
        );
      }
    }

    driverMarkers.refresh();
  }

  // ✅ YOUR ORIGINAL CANCELLATION METHODS (UNCHANGED)
  Future<void> showCancelReasons(BuildContext context) async {
    final screenWidth = Get.width;
    final screenHeight = Get.height;
    final baseWidth = 440.0;

    double sw(double w) => w * screenWidth / baseWidth;

    final cancellationReasons = [
      "Driver not responding",
      "Driver not at pickup",
      "Wrong pickup location",
      "Driver refused",
      "Change of plans",
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
      _cancelRide(reason, userLocation);
    } catch (e) {
      print('❌ Error getting current location: $e');
      final fallbackLocation = currentPosition.value ?? LatLng(0, 0);
      _cancelRide(reason, fallbackLocation);
    }
  }

  Future<void> _cancelRide(String cancellationReason, LatLng userLocation) async {
    try {
      if (thisRideId == null) {
        showError('Ride id missing');
        return;
      }

      if ((userLocation.latitude == 0.0 && userLocation.longitude == 0.0)) {
        showError('Unable to get your current location. Please check location permissions.');
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
    fareController.dispose();
    super.onClose();
  }
}