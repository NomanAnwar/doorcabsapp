import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';
import '../../../../utils/http/http_client.dart';
import '../models/ride_info.dart';

class GoToPickupController extends BaseController { // ✅ CHANGED: Extend BaseController

  final Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  final Rx<LatLng?> pickupPosition = Rx<LatLng?>(null);
  final RxList<LatLng> dropoffs = <LatLng>[].obs;
  final Rx<Polyline?> routePolyline = Rx<Polyline?>(null);
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxString passengerName = ''.obs;
  final RxString pickupAddress = ''.obs;
  final RxString dropoffAddress = ''.obs;
  final RxString estimatedArrivalTime = ''.obs;
  final RxString estimatedDropoffTime = ''.obs;
  final RxString estimatedDistance = ''.obs;
  final RxInt fare = 0.obs;
  final RxString phone = '03001234567'.obs;

  GoogleMapController? mapController;
  bool _mapReady = false;

  final RxBool rideStarted = false.obs;

  // Icons
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _pickupIcon;

  // Periodic GPS poll
  Timer? _locationTimer;

  // Pusher
  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
  String? _rideId;
  bool _subscribedToRideChannel = false;

  // Parsed ride model
  RideInfo? rideInfo;

  @override
  void onInit() {
    super.onInit();
    _parseArgs();
    _loadIcons();
    _startLocationPolling();
    _subscribeToRideIfNeeded();
  }

  @override
  void onClose() {
    _locationTimer?.cancel();
    if (_subscribedToRideChannel && _rideId != null) {
      _pusherManager.unsubscribeSafely('ride-$_rideId');
      _subscribedToRideChannel = false;
    }
    mapController?.dispose();
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

    passengerName.value = rideInfo?.passengerName ?? passengerName.value;
    pickupAddress.value = rideInfo?.pickupAddress ?? pickupAddress.value;

    if (rideInfo?.pickupLat != null && rideInfo?.pickupLng != null) {
      pickupPosition.value = LatLng(
        rideInfo!.pickupLat!,
        rideInfo!.pickupLng!,
      );
    }

    dropoffs.clear();
    for (final d in rideInfo?.dropoffs ?? []) {
      final lat = d['lat'];
      final lng = d['lng'];
      if (lat != null && lng != null) {
        dropoffs.add(
          LatLng(
            lat is num ? lat.toDouble() : double.parse(lat.toString()),
            lng is num ? lng.toDouble() : double.parse(lng.toString()),
          ),
        );
      }
    }

    dropoffAddress.value = (rideInfo?.dropoffs.isNotEmpty == true)
        ? (rideInfo?.dropoffs.first['address']?.toString() ?? '')
        : dropoffAddress.value;

    estimatedArrivalTime.value = rideInfo?.estimatedArrivalTime ?? '';
    estimatedDropoffTime.value = rideInfo?.estimatedDropoffTime ?? '';
    estimatedDistance.value = rideInfo?.estimatedDistance ?? '';
    fare.value =
    (rideInfo?.fare != null) ? rideInfo!.fare!.toInt() : fare.value;
    phone.value = rideInfo?.phone ?? phone.value;
  }

  // ----------------- ICONS -----------------
  Future<void> _loadIcons() async {
    try {
      await executeWithRetry(() async {
        _driverIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(64, 64)),
          'assets/images/position_marker2.png',
        );
      });
    } catch (e) {
      print('❌ failed to load driver icon: $e');
      _driverIcon = null;
    }

    try {
      await executeWithRetry(() async {
        _pickupIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(64, 64)),
          'assets/images/place.png',
        );
      });
    } catch (e) {
      print('❌ failed to load pickup icon: $e');
      _pickupIcon = null;
    }

    _updateMarkersAndPolyline();
  }

  // ----------------- MAP HANDLERS -----------------
  void onMapCreated(GoogleMapController c) {
    mapController = c;
    _mapReady = true;
    _moveCameraToBounds();
  }

  Future<void> _moveCameraToBounds() async {
    if (!_mapReady || mapController == null) return;
    final driver = currentPosition.value;
    final pickup = pickupPosition.value;
    try {
      if (driver != null && pickup != null) {
        final bounds = LatLngBounds(
          southwest: LatLng(
            driver.latitude < pickup.latitude ? driver.latitude : pickup.latitude,
            driver.longitude < pickup.longitude ? driver.longitude : pickup.longitude,
          ),
          northeast: LatLng(
            driver.latitude > pickup.latitude ? driver.latitude : pickup.latitude,
            driver.longitude > pickup.longitude ? driver.longitude : pickup.longitude,
          ),
        );
        await mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
      } else if (pickup != null) {
        await mapController!.animateCamera(CameraUpdate.newLatLngZoom(pickup, 14));
      } else if (driver != null) {
        await mapController!.animateCamera(CameraUpdate.newLatLngZoom(driver, 14));
      }
    } catch (e) {
      print('⚠️ moveCameraToBounds error: $e');
    }
  }

  // ----------------- MAP HANDLERS -----------------
  void _updateMarkersAndPolyline() async {
    final Set<Marker> m = {};

    final driverPos = currentPosition.value;
    if (driverPos != null) {
      m.add(Marker(
        markerId: const MarkerId('driver_marker'),
        position: driverPos,
        icon: _driverIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(title: 'Driver'),
      ));
    }

    final p = pickupPosition.value;
    if (p != null) {
      m.add(Marker(
        markerId: const MarkerId('pickup_marker'),
        position: p,
        icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: pickupAddress.value.isNotEmpty ? pickupAddress.value : 'Pickup'),
      ));
    }

    if (dropoffs.isNotEmpty) {
      final df = dropoffs.first;
      m.add(Marker(
        markerId: const MarkerId('dropoff_marker'),
        position: df,
        infoWindow: InfoWindow(title: dropoffAddress.value.isNotEmpty ? dropoffAddress.value : 'Dropoff'),
      ));
    }

    markers.value = m;

    // ✅ Decide which polyline to draw
    if (driverPos != null) {
      if (!rideStarted.value && p != null) {
        // before ride → route to pickup
        await _fetchRoutePolyline(driverPos, p);
      } else if (rideStarted.value && dropoffs.isNotEmpty) {
        // after ride start → route to dropoff
        await _fetchRoutePolyline(driverPos, dropoffs.first);
      }
    } else {
      routePolyline.value = null;
    }

    _moveCameraToBounds();
  }

  // Fetch proper polyline from Google Directions API
  Future<void> _fetchRoutePolyline(LatLng origin, LatLng dest) async {
    const apiKey = "AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4";
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${dest.latitude},${dest.longitude}&mode=driving&key=$apiKey";

    try {
      await executeWithRetry(() async {
        final res = await http.get(Uri.parse(url));
        final data = json.decode(res.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final List<LatLng> coords = _decodePolyline(points);
          routePolyline.value = Polyline(
            polylineId: const PolylineId('driver_to_pickup_route'),
            width: 5,
            color: const Color(0xFF003566),
            points: coords,
          );
        } else {
          print("⚠️ No routes found from Directions API");
          routePolyline.value = null;
        }
      });
    } catch (e) {
      print("❌ Directions API error: $e");
      routePolyline.value = null;
    }
  }

  // Polyline decoder
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

  // ----------------- GPS Polling -----------------
  void _startLocationPolling() {
    _updateCurrentLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _updateCurrentLocation();
    });
  }

  Future<void> _updateCurrentLocation() async {
    try {
      await executeWithRetry(() async {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        currentPosition.value = LatLng(pos.latitude, pos.longitude);
        _updateMarkersAndPolyline();
      });
    } catch (e) {
      print('❌ updateCurrentLocation error: $e');
      showError('Failed to get current location');
    }
  }

  // ----------------- Phone -----------------
  Future<void> callPhone() async {
    final uri = Uri(scheme: 'tel', path: phone.value);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      showError('Your device cannot make calls.');
    }
  }

  // ----------------- API actions -----------------
  Future<void> markDriverArrived() async {
    if (_rideId == null) {
      showError('Ride id missing');
      return;
    }
    try {
      await executeWithRetry(() async {
        final response = await FHttpHelper.post('ride/driver-arrived/$_rideId', {});

        print("Driver Arrived Api Response : "+response.toString());
        showSuccess('Driver arrival reported');
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
      await executeWithRetry(() async {
        final response = await FHttpHelper.post('ride/driver-started/$_rideId', {});

        print("Driver Started Api Response : "+response.toString());
        // ✅ update state
        rideStarted.value = true;
        showSuccess('Ride started');
        _updateMarkersAndPolyline();
        // Get.offNamed('/ride-request-list');

        // ✅ fetch polyline from driver → dropoff
        if (currentPosition.value != null && dropoffs.isNotEmpty) {
          await _fetchRoutePolyline(currentPosition.value!, dropoffs.first);
        }
      });
    } catch (e) {
      print('❌ markDriverStarted error: $e');
      showError('Failed to start ride');
    }
  }

  // ----------------- End Ride -----------------
  Future<void> markDriverEnded() async {
    if (_rideId == null) {
      showError('Ride id missing');
      return;
    }

    final body = {
      "onCompletionDistance": 23, // dummy distance
      "ride_duration": 11,        // dummy duration
    };

    try {
      await executeWithRetry(() async {
        final response = await FHttpHelper.post('ride/driver-ended/$_rideId', body);
        print("Driver Ended Api Response : $response");

        showSuccess('Ride completed successfully');

        // ✅ navigate to next screen (replace with your real route later)
        Get.offAllNamed('/go-online');
        // Get.offAllNamed('/ride-request-list');
      });
    } catch (e) {
      print('❌ markDriverEnded error: $e');
      showError('Failed to complete ride');
    }
  }

  // ----------------- Pusher subscription -----------------
  Future<void> _subscribeToRideChannel() async {
    if (_rideId == null) return;
    if (_subscribedToRideChannel) return;

    try {
      await executeWithRetry(() async {
        await _pusherManager.subscribeOnce(
          'ride-$_rideId',
          events: {
            // ✅ FIX: handle subscription_succeeded to remove warning
            'pusher:subscription_succeeded': (data) {
              print("✅ Successfully subscribed to ride-$_rideId");
            },
            'driver-location': (data) {
              try {
                double? lat;
                double? lng;
                if (data['lat'] != null && data['lng'] != null) {
                  lat = (data['lat'] is num) ? (data['lat'] as num).toDouble() : double.tryParse(data['lat'].toString());
                  lng = (data['lng'] is num) ? (data['lng'] as num).toDouble() : double.tryParse(data['lng'].toString());
                } else if (data['location'] != null) {
                  final loc = data['location'];
                  lat = (loc['lat'] is num) ? (loc['lat'] as num).toDouble() : double.tryParse(loc['lat'].toString());
                  lng = (loc['lng'] is num) ? (loc['lng'] as num).toDouble() : double.tryParse(loc['lng'].toString());
                }

                if (lat != null && lng != null) {
                  currentPosition.value = LatLng(lat, lng);
                  _updateMarkersAndPolyline();
                }
              } catch (e) {
                print('❌ driver-location parse error: $e');
              }
            },
            "new-message": (data) {
              print(" New message received : $data");
              showSuccess("New Message: $data");
            },
            "ride-cancelled": (data) {
              print("❌ Ride cancelled: $data");
              showError('Ride cancelled');
              Get.offAllNamed('/go-online');
              // Get.offAllNamed('/ride-request-list');
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

  Future<void> _subscribeToRideIfNeeded() async {
    if (_rideId != null) {
      await _subscribeToRideChannel();
    }
  }

  Future<void> showCancelReasons(BuildContext context) async {
    final List<String> reasons = [
      'Passenger not responding',
      'Passenger not at pickup',
      'Wrong pickup location',
      'Passenger refused',
      'Other'
    ];

    String selected = reasons[0];
    final otherController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text('Cancel ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                ...reasons.map((r) {
                  return RadioListTile<String>(
                    title: Text(r),
                    value: r,
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v ?? selected),
                  );
                }).toList(),
                if (selected == 'Other') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: otherController,
                      decoration: const InputDecoration(labelText: 'Enter reason'),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final reason = (selected == 'Other') ? otherController.text.trim() : selected;
                    if (reason.isEmpty) {
                      showError('Please enter a reason');
                      return;
                    }

                    // get current location for body
                    LatLng? loc = currentPosition.value;
                    if (loc == null) {
                      try {
                        final p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                        loc = LatLng(p.latitude, p.longitude);
                      } catch (e) {
                        print('❌ Could not obtain location: $e');
                      }
                    }

                    if (_rideId == null) {
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
                      final res = await FHttpHelper.post('ride/ride-cancelled/$_rideId', body);
                      print('✅ ride-cancelled response: $res');
                      Navigator.of(ctx).pop(); // close bottom sheet
                      showSuccess('Ride cancelled successfully');
                      Get.offAllNamed('/go-online');
                      // Get.offAllNamed('/ride-request-list');
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
        });
      },
    );
  }
}