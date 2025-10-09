import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
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
import '../models/driver_ride_info.dart';

class DriversWaitingController extends BaseController { // ✅ CHANGED: Extend BaseController
  final currentPosition = Rxn<LatLng>();
  final driverMarkers = <String, Marker>{}.obs;
  final polylines = <Polyline>{}.obs;
  final fareController = TextEditingController();

  GoogleMapController? _mapController;
  Timer? _waitingTimer;

  final rideStarted = false.obs;
  final RxBool updateView = false.obs;
  var thisRideId;

  String? _rideId;
  String? _driverId;

  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _stopIcon;
  BitmapDescriptor? _dropIcon;

  String? get rideId => _rideId;

  String? get driverId => _driverId;

  set rideId(String? id) => _rideId = id;

  set driverId(String? id) => _driverId = id;

  final rideInfo = Rxn<DriverRideInfo>();

  // ✅ ADDED: Enhanced Pusher Manager
  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();

  @override
  void onInit() async {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
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

    if (rideInfo.value != null &&
        (rideInfo.value!.rideId?.isNotEmpty ?? false)) {
      _subscribeToDriverLocation(rideInfo.value!.rideId!);
    }

    if (rideInfo.value?.pickup != null) {
      currentPosition.value = LatLng(
        (rideInfo.value!.pickup!['lat'] as num).toDouble(),
        (rideInfo.value!.pickup!['lng'] as num).toDouble(),
      );
    } else {
      currentPosition.value = const LatLng(31.5204, 74.3587);
    }
  }

  /// ✅ UPDATED: Subscribe to driver location with enhanced pusher
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
          final pos = LatLng(lat, lng);

          driverMarkers["driver"] = Marker(
            markerId: const MarkerId("driver"),
            position: pos,
            icon:
            _driverIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: "Driver"),
          );
          driverMarkers.refresh();

          final pickup = rideInfo.value?.pickup;
          final dropoffs = rideInfo.value?.dropoffs ?? [];

          if (!rideStarted.value) {
            if (pickup != null) {
              final pickupPos = LatLng(
                (pickup['lat'] as num).toDouble(),
                (pickup['lng'] as num).toDouble(),
              );
              final polyPoints = await _fetchRoutePolylineWithRetry(pos, pickupPos);
              _setPolyline(polyPoints);
              _fitMapToBounds([pos, pickupPos]);
            }
          } else {
            final List<LatLng> routePoints = [pos];
            for (var df in dropoffs) {
              final latN = (df['lat'] as num).toDouble();
              final lngN = (df['lng'] as num).toDouble();
              routePoints.add(LatLng(latN, lngN));
            }
            if (routePoints.length == 1 && dropoffs.isNotEmpty) {
              final df = dropoffs[0];
              routePoints.add(
                LatLng(
                  (df['lat'] as num).toDouble(),
                  (df['lng'] as num).toDouble(),
                ),
              );
            }

            final fullPolylinePoints = await _buildRouteThroughPointsWithRetry(
              routePoints,
            );
            _setPolyline(fullPolylinePoints);
            _fitMapToBounds(routePoints);
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
            _buildRouteThroughPointsWithRetry(pts).then((polyPoints) {
              _setPolyline(polyPoints);
              _fitMapToBounds(pts);
            });
          }
        },

        "ride-ended": (data) {
          print("🏁 Ride ended: $data");
          rideStarted.value = false;
          polylines.clear();
          showSuccess('Ride completed successfully');
          Get.offAllNamed('/ride-type');
        },

        "ride-cancelled": (data) {
          print("❌ Ride cancelled: $data");
          showError('Ride Cancelled successfully');
          Get.offAllNamed('/ride-type');
        },

        "new-message": (data) {
          print("💬 New message received: $data");
        },
      },
    );
  }

  /// ✅ NEW: Fetch route polyline with retry
  Future<List<LatLng>> _fetchRoutePolylineWithRetry(
      LatLng origin,
      LatLng destination,
      ) async
  {
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

  /// ✅ NEW: Build route through points with retry
  Future<List<LatLng>> _buildRouteThroughPointsWithRetry(List<LatLng> pts) async
  {
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

  // ✅ EXISTING: Your original methods (unchanged)
  /// Resize and load marker icons
  Future<BitmapDescriptor> _bitmapFromAsset(
      String path, {
        int width = 100,
      }) async
  {
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
          width: 80,
        );
        _pickupIcon = await _bitmapFromAsset(
          'assets/images/position_marker2.png',
          width: 80,
        );
        _stopIcon = await _bitmapFromAsset('assets/images/place.png', width: 60);
        _dropIcon = await _bitmapFromAsset(
          'assets/images/place.png',
          width: 100,
        ); // double size
        print("✅ All icons loaded");
      });
    } catch (e) {
      print('❌ Failed to load marker icons: $e');
    }
  }

  void onMapCreated(GoogleMapController c) {
    _mapController = c;
  }

  Future<List<LatLng>> _fetchRoutePolyline(
      LatLng origin,
      LatLng destination,
      ) async {
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

  Future<void> _fitMapToBounds(List<LatLng> points) async {
    if (_mapController == null || points.isEmpty) return;
    final bounds = _boundsFromLatLngList(points);
    if (bounds != null) {
      try {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      } catch (e) {
        print('❌ animateCamera failed: $e');
      }
    }
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

  // ✅ EXISTING: Your original cancel method (unchanged)
  Future<void> showCancelReasons(BuildContext context) async {
    final List<String> reasons = [
      'Driver not responding',
      'Driver not at pickup',
      'Wrong pickup location',
      'Driver refused',
      'Other',
    ];

    String selected = reasons[0];
    final otherController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Cancel ride',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  ...reasons.map((r) {
                    return RadioListTile<String>(
                      title: Text(r),
                      value: r,
                      groupValue: selected,
                      onChanged:
                          (v) => setState(() => selected = v ?? selected),
                    );
                  }).toList(),
                  if (selected == 'Other') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: otherController,
                        decoration: const InputDecoration(
                          labelText: 'Enter reason',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final reason =
                      (selected == 'Other')
                          ? otherController.text.trim()
                          : selected;
                      if (reason.isEmpty) {
                        showError('Please enter a reason');
                        return;
                      }

                      LatLng? loc = currentPosition.value;
                      if (loc == null) {
                        try {
                          final p = await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high,
                          );
                          loc = LatLng(p.latitude, p.longitude);
                        } catch (e) {
                          print('❌ Could not obtain location: $e');
                        }
                      }

                      if (thisRideId == null) {
                        showError('Ride id missing');
                        return;
                      }

                      final body = {
                        'cancellationReason': reason,
                        'location': {
                          'lat': loc?.latitude ?? 0.0,
                          'lng': loc?.longitude ?? 0.0,
                        },
                      };

                      try {
                        final res = await FHttpHelper.post(
                          'ride/ride-cancelled/$thisRideId',
                          body,
                        );
                        print('✅ ride-cancelled response: $res');
                        Navigator.of(ctx).pop();
                        showSuccess('Ride cancelled successfully');
                        Get.offAllNamed('/ride-type');
                      } catch (e) {
                        print('❌ ride-cancelled error: $e');
                        showError('Failed to cancel ride');
                      }
                    },
                    child: const Text('Cancel Ride'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void onClose() {
    _waitingTimer?.cancel();
    fareController.dispose();
    super.onClose();
  }
}



// import 'dart:async';
// import 'dart:convert';
// import 'dart:ui' as ui;
// import 'package:doorcab/utils/constants/colors.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import '../../../../utils/http/http_client.dart';
// import '../../../shared/services/pusher_channels.dart';
// import '../models/driver_ride_info.dart';
//
// class DriversWaitingController extends GetxController {
//   final currentPosition = Rxn<LatLng>();
//   final driverMarkers = <String, Marker>{}.obs;
//   final polylines = <Polyline>{}.obs;
//   final fareController = TextEditingController();
//
//
//
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
//   BitmapDescriptor? _driverIcon;
//   BitmapDescriptor? _pickupIcon;
//   BitmapDescriptor? _stopIcon;
//   BitmapDescriptor? _dropIcon;
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
//
//
//
//   @override
//   void onInit() async {
//     super.onInit();
//
//     final args = Get.arguments as Map<String, dynamic>? ?? {};
//     if (args.isNotEmpty) {
//       print("📦 Args received: $args");
//
//       final bid = args['bid'] as Map<String, dynamic>?;
//
//       rideInfo.value = DriverRideInfo.fromArgs({...args, ...?bid});
//
//       rideId = args['rideId']?.toString();
//       driverId = bid?['driver']?['id']?.toString();
//       print("Driver id: $driverId");
//     }
//
//     thisRideId = rideInfo.value?.rideId;
//
//     await _loadMarkerIcons();
//
//     _placeStaticMarkersFromRideInfo();
//
//     if (rideInfo.value != null &&
//         (rideInfo.value!.rideId?.isNotEmpty ?? false)) {
//       _subscribeToDriverLocation(rideInfo.value!.rideId);
//     }
//
//     if (rideInfo.value?.pickup != null) {
//       currentPosition.value = LatLng(
//         (rideInfo.value!.pickup!['lat'] as num).toDouble(),
//         (rideInfo.value!.pickup!['lng'] as num).toDouble(),
//       );
//     } else {
//       currentPosition.value = const LatLng(31.5204, 74.3587);
//     }
//   }
//
//   /// ✅ Resize and load marker icons
//   Future<BitmapDescriptor> _bitmapFromAsset(
//     String path, {
//     int width = 100,
//   }) async {
//     final byteData = await rootBundle.load(path);
//     final codec = await ui.instantiateImageCodec(
//       byteData.buffer.asUint8List(),
//       targetWidth: width,
//     );
//     final frame = await codec.getNextFrame();
//     final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
//     return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
//   }
//
//   Future<void> _loadMarkerIcons() async {
//     try {
//       _driverIcon = await _bitmapFromAsset(
//         'assets/images/car.png',
//         width: 80,
//       );
//       _pickupIcon = await _bitmapFromAsset(
//         'assets/images/position_marker2.png',
//         width: 80,
//       );
//       _stopIcon = await _bitmapFromAsset('assets/images/place.png', width: 60);
//       _dropIcon = await _bitmapFromAsset(
//         'assets/images/place.png',
//         width: 100,
//       ); // double size
//       print("✅ All icons loaded");
//     } catch (e) {
//       print('❌ Failed to load marker icons: $e');
//     }
//   }
//
//   void onMapCreated(GoogleMapController c) {
//     _mapController = c;
//   }
//
//   void _subscribeToDriverLocation(String rideId) {
//     PusherChannelsService().subscribe(
//       "ride-$rideId",
//       events: {
//         "driver-location": (data) async {
//           print("📨 Driver-location update: $data");
//
//           double lat = 0.0;
//           double lng = 0.0;
//           try {
//             lat = (data['lat'] as num).toDouble();
//             lng = (data['lng'] as num).toDouble();
//           } catch (e) {
//             lat = double.tryParse(data['lat']?.toString() ?? '') ?? 0.0;
//             lng = double.tryParse(data['lng']?.toString() ?? '') ?? 0.0;
//           }
//           final pos = LatLng(lat, lng);
//
//           driverMarkers["driver"] = Marker(
//             markerId: const MarkerId("driver"),
//             position: pos,
//             icon:
//                 _driverIcon ??
//                 BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//             infoWindow: const InfoWindow(title: "Driver"),
//           );
//           driverMarkers.refresh();
//
//           final pickup = rideInfo.value?.pickup;
//           final dropoffs = rideInfo.value?.dropoffs ?? [];
//
//           if (!rideStarted.value) {
//             if (pickup != null) {
//               final pickupPos = LatLng(
//                 (pickup['lat'] as num).toDouble(),
//                 (pickup['lng'] as num).toDouble(),
//               );
//               final polyPoints = await _fetchRoutePolyline(pos, pickupPos);
//               _setPolyline(polyPoints);
//               _fitMapToBounds([pos, pickupPos]);
//             }
//           } else {
//             final List<LatLng> routePoints = [pos];
//             for (var df in dropoffs) {
//               final latN = (df['lat'] as num).toDouble();
//               final lngN = (df['lng'] as num).toDouble();
//               routePoints.add(LatLng(latN, lngN));
//             }
//             if (routePoints.length == 1 && dropoffs.isNotEmpty) {
//               final df = dropoffs[0];
//               routePoints.add(
//                 LatLng(
//                   (df['lat'] as num).toDouble(),
//                   (df['lng'] as num).toDouble(),
//                 ),
//               );
//             }
//
//             final fullPolylinePoints = await _buildRouteThroughPoints(
//               routePoints,
//             );
//             _setPolyline(fullPolylinePoints);
//             _fitMapToBounds(routePoints);
//           }
//         },
//
//         "driver-arrived": (data) {
//           print("📢 Driver has arrived at pickup: $data");
//           Get.snackbar(
//             "Driver Arrived",
//             "Driver arrived at your pick up location.",
//           );
//         },
//
//         "ride-started": (data) {
//           print("🚦 Ride started: $data");
//           rideStarted.value = true;
//
//           Get.snackbar("Ride Started", "Enjoy your trip!");
//
//           updateView.value = true;
//
//           _placeStaticMarkersFromRideInfo();
//
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
//             _buildRouteThroughPoints(pts).then((polyPoints) {
//               _setPolyline(polyPoints);
//               _fitMapToBounds(pts);
//             });
//           }
//         },
//
//         "ride-ended": (data) {
//           print("🏁 Ride ended: $data");
//           rideStarted.value = false;
//           polylines.clear();
//           Get.snackbar('Completed', 'Ride completed successfully');
//           // Get.offAllNamed('/ride-home');
//           Get.offAllNamed('/ride-type');
//         },
//
//         "ride-cancelled": (data) {
//           print("❌ Ride cancelled: $data");
//           Get.snackbar('Ride cancelled', 'Ride Cancelled successfully');
//           Get.offAllNamed('/ride-type');
//           // Get.offAllNamed('/ride-home');
//         },
//
//         "new-message": (data) {
//           print("💬 New message received: $data");
//         },
//       },
//     );
//   }
//
//   Future<List<LatLng>> _fetchRoutePolyline(
//     LatLng origin,
//     LatLng destination,
//   ) async {
//     const apiKey = "AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4";
//     final url =
//         "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}"
//         "&destination=${destination.latitude},${destination.longitude}&key=$apiKey";
//
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode != 200) throw Exception("Directions API failed");
//
//     final data = jsonDecode(response.body);
//     if (data == null || data['routes'] == null || data['routes'].isEmpty) {
//       return [];
//     }
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
//
//     while (index < len) {
//       int b, shift = 0, result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lat += dlat;
//
//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lng += dlng;
//
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
//     final polyline = Polyline(
//       polylineId: const PolylineId("driver_route"),
//       color: FColors.secondaryColor,
//       width: 5,
//       points: points,
//     );
//     polylines.value = {polyline};
//   }
//
//   Future<void> _fitMapToBounds(List<LatLng> points) async {
//     if (_mapController == null || points.isEmpty) return;
//     final bounds = _boundsFromLatLngList(points);
//     if (bounds != null) {
//       try {
//         await _mapController!.animateCamera(
//           CameraUpdate.newLatLngBounds(bounds, 80),
//         );
//       } catch (e) {
//         print('❌ animateCamera failed: $e');
//       }
//     }
//   }
//
//   LatLngBounds? _boundsFromLatLngList(List<LatLng> list) {
//     if (list.isEmpty) return null;
//     double x0 = list.first.latitude, x1 = list.first.latitude;
//     double y0 = list.first.longitude, y1 = list.first.longitude;
//
//     for (LatLng latLng in list) {
//       if (latLng.latitude > x1) x1 = latLng.latitude;
//       if (latLng.latitude < x0) x0 = latLng.latitude;
//       if (latLng.longitude > y1) y1 = latLng.longitude;
//       if (latLng.longitude < y0) y0 = latLng.longitude;
//     }
//     return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
//   }
//
//   void _placeStaticMarkersFromRideInfo() {
//     driverMarkers.removeWhere(
//       (k, v) => k == 'pickup' || k.startsWith('stop_') || k == 'dropoff',
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
//             _pickupIcon ??
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
//               _dropIcon ??
//               BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//           infoWindow: InfoWindow(title: df['address']?.toString() ?? 'Dropoff'),
//         );
//       } else {
//         driverMarkers['stop_$i'] = Marker(
//           markerId: MarkerId('stop_$i'),
//           position: pos,
//           icon:
//               _stopIcon ??
//               BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
//           infoWindow: InfoWindow(
//             title: df['address']?.toString() ?? 'Stop ${i + 1}',
//           ),
//         );
//       }
//     }
//
//     driverMarkers.refresh();
//   }
//
//   Future<void> showCancelReasons(BuildContext context) async {
//     final List<String> reasons = [
//       'Driver not responding',
//       'Driver not at pickup',
//       'Wrong pickup location',
//       'Driver refused',
//       'Other',
//     ];
//
//     String selected = reasons[0];
//     final otherController = TextEditingController();
//
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (_) {
//         return StatefulBuilder(
//           builder: (ctx, setState) {
//             return Padding(
//               padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(ctx).viewInsets.bottom,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const SizedBox(height: 12),
//                   const Text(
//                     'Cancel ride',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   const Divider(),
//                   ...reasons.map((r) {
//                     return RadioListTile<String>(
//                       title: Text(r),
//                       value: r,
//                       groupValue: selected,
//                       onChanged:
//                           (v) => setState(() => selected = v ?? selected),
//                     );
//                   }).toList(),
//                   if (selected == 'Other') ...[
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                       child: TextField(
//                         controller: otherController,
//                         decoration: const InputDecoration(
//                           labelText: 'Enter reason',
//                         ),
//                       ),
//                     ),
//                   ],
//                   const SizedBox(height: 10),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final reason =
//                           (selected == 'Other')
//                               ? otherController.text.trim()
//                               : selected;
//                       if (reason.isEmpty) {
//                         Get.snackbar('Error', 'Please enter a reason');
//                         return;
//                       }
//
//                       LatLng? loc = currentPosition.value;
//                       if (loc == null) {
//                         try {
//                           final p = await Geolocator.getCurrentPosition(
//                             desiredAccuracy: LocationAccuracy.high,
//                           );
//                           loc = LatLng(p.latitude, p.longitude);
//                         } catch (e) {
//                           print('❌ Could not obtain location: $e');
//                         }
//                       }
//
//                       if (thisRideId == null) {
//                         Get.snackbar('Error', 'Ride id missing');
//                         return;
//                       }
//
//                       final body = {
//                         'cancellationReason': reason,
//                         'location': {
//                           'lat': loc?.latitude ?? 0.0,
//                           'lng': loc?.longitude ?? 0.0,
//                         },
//                       };
//
//                       try {
//                         final res = await FHttpHelper.post(
//                           'ride/ride-cancelled/$thisRideId',
//                           body,
//                         );
//                         print('✅ ride-cancelled response: $res');
//                         Navigator.of(ctx).pop();
//                         Get.snackbar(
//                           'Cancelled',
//                           'Ride cancelled successfully',
//                         );
//                         Get.offAllNamed('/ride-type');
//                         // Get.offAllNamed('/ride-home');
//                       } catch (e) {
//                         print('❌ ride-cancelled error: $e');
//                         Get.snackbar('Error', 'Failed to cancel ride');
//                       }
//                     },
//                     child: const Text('Cancel Ride'),
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   @override
//   void onClose() {
//     _waitingTimer?.cancel();
//     fareController.dispose();
//     super.onClose();
//   }
// }
