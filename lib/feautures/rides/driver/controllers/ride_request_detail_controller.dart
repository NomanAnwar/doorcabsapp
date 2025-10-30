import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:doorcab/feautures/rides/driver/models/request_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';
import '../../../shared/services/storage_service.dart';

class RideRequestDetailController extends BaseController {
  final Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  final Rx<Polyline?> routePolyline = Rx<Polyline?>(null);
  final markers = <Marker>{}.obs;

  // Ride request model
  late final RequestModel request;

  final RxString passengerName = "".obs;
  final RxDouble passengerRating = 0.0.obs;
  final RxString pickupAddress = "".obs;
  final RxString dropoffAddress = "".obs;

  final RxString estimatedPickupTime = "".obs;
  final RxString estimatedDropoffTime = "".obs;
  final RxString distance = "".obs;

  // ✅ FIXED: Added originalFare to store the initial offer amount
  final RxInt originalFare = 0.obs;
  final RxInt fare = 0.obs;
  final RxBool isAccepting = false.obs;

  /// NEW: Track bid submission state
  final RxBool isBidSubmitted = false.obs;
  final RxString bidStatus = "".obs; // "submitted", "accepted", "rejected", "ignored"

  final RxBool isChipSelected = false.obs;
  final RxInt selectedChipAmount = 0.obs;

  /// Custom offer input
  final TextEditingController offerController = TextEditingController();

  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();

  // ---- NEW: map controller so we can move camera to bounds ----
  GoogleMapController? mapController;
  bool _mapReady = false;

  // keep your API key as in your code
  static const String apiKey = "AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4";

  @override
  void onInit() {
    super.onInit();

    // Add a safety check to ensure we have a valid request
    if (Get.arguments?['request'] == null) {
      print("❌ No request provided to RideRequestDetailController");
      Get.back();
      return;
    }

    request = Get.arguments['request'] as RequestModel;

    // ✅ DEBUG: Print all request data to see what's available
    print('🔍 REQUEST DATA DEBUG:');
    print('   Request ID: ${request.id}');
    print('   Passenger Name: ${request.passengerName}');
    print('   Pickup Address: ${request.pickupAddress.address}');
    print('   Dropoff Addresses: ${request.dropoffAddress.length}');
    print('   Full request object: $request');

    // Check if we have additional ride data in arguments
    final additionalData = Get.arguments;
    print('   All arguments keys: ${additionalData.keys}');

    // ✅ FIXED: Store original fare and set both fares
    final originalAmount = request.offerAmount.toInt();
    originalFare.value = originalAmount;
    fare.value = originalAmount; // Start with original amount

    // ✅ Bind request fields
    passengerName.value = request.passengerName;
    passengerRating.value = request.rating;
    pickupAddress.value = request.pickupAddress.address;
    dropoffAddress.value = request.dropoffAddress[0].address;
    distance.value = "${request.distanceKm.toStringAsFixed(2)} km";

    estimatedPickupTime.value = "${request.etaMinutes} min";
    estimatedDropoffTime.value = "${request.etaMinutes + 15} min"; // Example only

    // ✅ Setup map route (real implementation)
    _setMapData();

    // REMOVED: _startOfferCountdown();
  }

  /// NEW: fetch route & markers from Google Directions API (handles stops/waypoints)
  Future<void> _setMapData() async {
    try {
      await executeWithRetry(() async {
        // Robust parsing helper (handles num or String)
        double _toDouble(dynamic v) {
          if (v == null) return 0.0;
          if (v is num) return v.toDouble();
          if (v is String) return double.tryParse(v) ?? 0.0;
          return 0.0;
        }

        // Parse pickup
        final pickupLat = _toDouble(request.pickupAddress.lat);
        final pickupLng = _toDouble(request.pickupAddress.lng);
        final pickupLatLng = LatLng(pickupLat, pickupLng);

        // Parse stops (dropoffAddress based on your model, might contain multiple stops)
        final stops = request.dropoffAddress; // List<DropoffPoint> in your model
        if (stops.isEmpty) {
          // fallback: no stops provided — nothing to draw
          currentPosition.value = pickupLatLng;
          markers.value = {
            Marker(
              markerId: const MarkerId("pickup"),
              position: pickupLatLng,
              infoWindow: InfoWindow(title: pickupAddress.value),
            )
          };
          return;
        }

        // Destination is the last stop in list (common)
        final lastStop = stops.last;
        final dropoffLat = _toDouble(lastStop.lat);
        final dropoffLng = _toDouble(lastStop.lng);
        final dropoffLatLng = LatLng(dropoffLat, dropoffLng);

        // currentPosition (used as initial center) — set to pickup
        currentPosition.value = pickupLatLng;

        // Build waypoints string: Google expects waypoints=lat,lng|lat,lng (exclude final destination)
        String waypointParam = "";
        if (stops.length > 1) {
          final List<String> wpList = stops
              .sublist(0, stops.length - 1)
              .map((s) => "${_toDouble(s.lat)},${_toDouble(s.lng)}")
              .toList();
          if (wpList.isNotEmpty) waypointParam = "&waypoints=${wpList.join('|')}";
        }

        final url =
            "https://maps.googleapis.com/maps/api/directions/json?origin=${pickupLatLng.latitude},${pickupLatLng.longitude}&destination=${dropoffLatLng.latitude},${dropoffLatLng.longitude}$waypointParam&mode=driving&key=$apiKey";

        print("Directions URL: $url");

        final res = await http.get(Uri.parse(url));
        if (res.statusCode != 200) {
          print("❌ Directions API http error: ${res.statusCode}");
          // fallback to straight line
          routePolyline.value = Polyline(
            polylineId: const PolylineId("route"),
            color: const Color(0xFF003566),
            width: 5,
            points: [pickupLatLng, dropoffLatLng],
          );
          // set markers
          _setMarkers(pickupLatLng, stops);
          // try move camera (if map ready)
          _moveCameraToBounds();
          return;
        }

        final data = json.decode(res.body);
        if (data["status"] != "OK") {
          print("❌ Directions API failed: ${data["status"]} - ${data["error_message"] ?? ''}");
          // fallback to simple line
          routePolyline.value = Polyline(
            polylineId: const PolylineId("route"),
            color: const Color(0xFF003566),
            width: 5,
            points: [pickupLatLng, dropoffLatLng],
          );
          _setMarkers(pickupLatLng, stops);
          _moveCameraToBounds();
          return;
        }

        // decode overview polyline for whole route (includes waypoints)
        final encoded = data["routes"][0]["overview_polyline"]["points"] as String;
        final coords = _decodePolyline(encoded);
        routePolyline.value = Polyline(
          polylineId: const PolylineId("route"),
          color: const Color(0xFF003566),
          width: 5,
          points: coords,
        );

        // set markers (with correct sizes/icons)
        await _setMarkers(pickupLatLng, stops);

        // move camera to show full route
        _moveCameraToBounds();
      });
    } catch (e, s) {
      print("❌ _setMapData error: $e\n$s");
      // fallback: set simple line between pickup and first stop
      try {
        final pickupLat = request.pickupAddress.lat as double;
        final pickupLng = request.pickupAddress.lng as double;
        final pickup = LatLng(pickupLat, pickupLng);
        final stop = request.dropoffAddress.isNotEmpty
            ? LatLng(request.dropoffAddress.last.lat, request.dropoffAddress.last.lng)
            : pickup;
        routePolyline.value = Polyline(
          polylineId: const PolylineId("route"),
          color: const Color(0xFF003566),
          width: 5,
          points: [pickup, stop],
        );
        markers.value = {
          Marker(markerId: const MarkerId("pickup"), position: pickup),
          Marker(markerId: const MarkerId("dropoff"), position: stop),
        };
        _moveCameraToBounds();
      } catch (_) {}
    }
  }

  /// Helper to load icons and set markers (clears previous markers)
  Future<void> _setMarkers(LatLng pickup, List stops) async {
    try {
      await executeWithRetry(() async {
        // Clear existing markers
        final Set<Marker> m = {};

        // Load custom icons with proper resizing
        BitmapDescriptor pickupIcon;
        BitmapDescriptor stopIcon;
        BitmapDescriptor dropoffIcon;

        try {
          // ✅ FIX: Use proper image resizing for pickup marker
          final pickupData = await rootBundle.load('assets/images/position_marker2.png');
          final pickupBytes = pickupData.buffer.asUint8List();
          final pickupCodec = await instantiateImageCodec(pickupBytes, targetWidth: 100); // Larger size
          final pickupFrame = await pickupCodec.getNextFrame();
          final pickupResizedData = await pickupFrame.image.toByteData(format: ImageByteFormat.png);
          pickupIcon = BitmapDescriptor.fromBytes(pickupResizedData!.buffer.asUint8List());
        } catch (e) {
          print("❌ pickupIcon load failed: $e");
          pickupIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        }

        try {
          // ✅ FIX: Use proper image resizing for stop marker
          final stopData = await rootBundle.load('assets/images/place.png');
          final stopBytes = stopData.buffer.asUint8List();
          final stopCodec = await instantiateImageCodec(stopBytes, targetWidth: 60); // Medium size
          final stopFrame = await stopCodec.getNextFrame();
          final stopResizedData = await stopFrame.image.toByteData(format: ImageByteFormat.png);
          stopIcon = BitmapDescriptor.fromBytes(stopResizedData!.buffer.asUint8List());
        } catch (e) {
          print("❌ stopIcon load failed: $e");
          stopIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        }

        try {
          // ✅ FIX: Use proper image resizing for dropoff marker
          final dropoffData = await rootBundle.load('assets/images/place.png');
          final dropoffBytes = dropoffData.buffer.asUint8List();
          final dropoffCodec = await instantiateImageCodec(dropoffBytes, targetWidth: 100); // Larger size
          final dropoffFrame = await dropoffCodec.getNextFrame();
          final dropoffResizedData = await dropoffFrame.image.toByteData(format: ImageByteFormat.png);
          dropoffIcon = BitmapDescriptor.fromBytes(dropoffResizedData!.buffer.asUint8List());
        } catch (e) {
          print("❌ dropoffIcon load failed: $e");
          dropoffIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
        }

        // pickup marker
        m.add(Marker(
          markerId: const MarkerId("pickup"),
          position: pickup,
          infoWindow: InfoWindow(title: pickupAddress.value),
          icon: pickupIcon,
          anchor: const Offset(0.5, 0.5), // ✅ Center the marker
        ));

        // stops (all except last) -> medium icon
        for (int i = 0; i < stops.length - 1; i++) {
          final s = stops[i];
          final lat = (s.lat is num) ? (s.lat as num).toDouble() : double.tryParse(s.lat.toString()) ?? 0.0;
          final lng = (s.lng is num) ? (s.lng as num).toDouble() : double.tryParse(s.lng.toString()) ?? 0.0;
          m.add(Marker(
            markerId: MarkerId("stop_$i"),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: s.address ?? ""),
            icon: stopIcon,
            anchor: const Offset(0.5, 0.5), // ✅ Center the marker
          ));
        }

        // dropoff (last) -> larger icon
        final last = stops.last;
        final lastLat = (last.lat is num) ? (last.lat as num).toDouble() : double.tryParse(last.lat.toString()) ?? 0.0;
        final lastLng = (last.lng is num) ? (last.lng as num).toDouble() : double.tryParse(last.lng.toString()) ?? 0.0;
        m.add(Marker(
          markerId: const MarkerId("dropoff"),
          position: LatLng(lastLat, lastLng),
          infoWindow: InfoWindow(title: dropoffAddress.value),
          icon: dropoffIcon,
          anchor: const Offset(0.5, 0.5), // ✅ Center the marker
        ));

        markers.value = m;

        print('✅ Markers loaded with sizes: Pickup(80px), Stops(60px), Dropoff(70px)');
      });
    } catch (e) {
      print("❌ _setMarkers error: $e");
    }
  }

  /// Decode Google encoded polyline
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
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  // ----------------------------------------------------------------
  // Map camera helpers
  // ----------------------------------------------------------------
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _mapReady = true;
    // If route already available, move camera to bounds
    _moveCameraToBounds();
  }

  Future<void> _moveCameraToBounds() async {
    if (!_mapReady || mapController == null) return;

    // prefer polyline points for bounds; if not present, use marker positions
    final List<LatLng> pts = (routePolyline.value?.points.isNotEmpty == true)
        ? routePolyline.value!.points
        : markers.map((m) => m.position).toList();

    if (pts.isEmpty) return;

    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;

    for (final p in pts) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }

    final southwest = LatLng(minLat, minLng);
    final northeast = LatLng(maxLat, maxLng);
    final bounds = LatLngBounds(southwest: southwest, northeast: northeast);

    try {
      await mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    } catch (e) {
      // If animateCamera with bounds fails (sometimes on small devices), fallback to center+zoom
      final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
      await mapController!.animateCamera(CameraUpdate.newLatLngZoom(center, 13));
    }
  }

  // REMOVED: _startOfferCountdown() method


  // ✅ UPDATED: Handle bid responses
  void _handleBidResponse(Map<String, dynamic> data, String eventType) {
    print("🎯 Bid $eventType received: $data");

    // Hide loading
    isLoading.value = false;
    isBidSubmitted.value = false;

    switch (eventType) {
      case "bid-accepted":
        bidStatus.value = "accepted";
        // showSuccess(data['message'] ?? "Your bid was accepted!");
        Future.delayed(Duration(seconds: 2), () {
          Get.offNamed('/go-to-pickup', arguments: {"rideData": data});
        });
        break;

      case "bid-rejected":
        bidStatus.value = "rejected";
        // showError(data['message'] ?? "Your bid was rejected by the passenger");
        break;

      case "bid-ignored":
        bidStatus.value = "ignored";
        showError("Passenger ignored your bid");
        Future.delayed(Duration(seconds: 1), () {
          Get.back(result: 'ignored');
        });
        break;
    }
  }


  // ✅ FIXED: Now accepts the current fare value (from chip or text field)
  // Future<void> acceptRide(String rideId, double fareOffered) async {
  //   try {
  //     // ✅ VALIDATION: Check if fare is at least original amount
  //     if (fareOffered < originalFare.value) {
  //       showError("Offer amount must be at least PKR ${originalFare.value}");
  //       return;
  //     }
  //
  //     isLoading.value = true;
  //
  //     await executeWithRetry(() async {
  //       // ✅ Ensure auth token is set
  //       final token = StorageService.getAuthToken();
  //       if (token == null) {
  //         throw Exception("User not authenticated. Please login again.");
  //       }
  //       FHttpHelper.setAuthToken(token, useBearer: true);
  //
  //       print("🚀 Submitting bid - Ride ID: $rideId, Fare: $fareOffered");
  //       final response = await FHttpHelper.post('ride/submit-bids', {
  //         "rideId": rideId,
  //         "fareOffered": fareOffered,
  //       });
  //
  //       print("🚀 Ride bid response: $response");
  //
  //       if (response['message'] == "Bid submitted") {
  //         final bid = response['bid'];
  //         String? driverId;
  //         if (bid != null) {
  //           final driverRaw = bid['driverId'] ?? bid['driver'] ?? response['driverId'];
  //           if (driverRaw is Map && driverRaw.containsKey('_id')) {
  //             driverId = driverRaw['_id']?.toString();
  //           } else if (driverRaw is String) {
  //             driverId = driverRaw;
  //           }
  //         }
  //         final submittedRideId = bid?['rideId']?.toString() ?? response['rideId']?.toString();
  //
  //         final subs = <Future>[];
  //
  //         if (driverId != null) {
  //           subs.add(_pusherManager.subscribeOnce(
  //             "driver-$driverId",
  //             events: {
  //               "bid-accepted": (data) {
  //                 print("🎉 (detail) Bid accepted event for driver-$driverId: $data");
  //                 showSuccess(data['message'] ?? "Your bid was accepted!");
  //               },
  //               "bid-ignored": (eventData) {
  //                 FSnackbar.show(title: "bid ignored", message: eventData.toString());
  //                 // _handleBidAccepted(eventData);
  //               },
  //               "bid-rejected": (eventData) {
  //                 FSnackbar.show(title: "bid rejected", message: eventData.toString());
  //                 // _handleBidAccepted(eventData);
  //               },
  //             },
  //           ));
  //         } else {
  //           print("⚠️ driverId not found in submit-bids response");
  //         }
  //
  //         if (submittedRideId != null) {
  //           subs.add(_pusherManager.subscribeOnce(
  //             "ride-$submittedRideId",
  //             events: {
  //               "driver-location": (data) {
  //                 print("📍 (detail) driver-location: $data");
  //                 try {
  //                   final lat = (data['lat'] != null) ? double.tryParse(data['lat'].toString()) : null;
  //                   final lng = (data['lng'] != null) ? double.tryParse(data['lng'].toString()) : null;
  //                   if (lat != null && lng != null) {
  //                     currentPosition.value = LatLng(lat, lng);
  //                   }
  //                 } catch (e) {
  //                   print("❌ Error parsing driver-location in detail controller: $e");
  //                 }
  //               },
  //             },
  //           ));
  //         } else {
  //           print("⚠️ rideId not found in API response");
  //         }
  //
  //         if (subs.isNotEmpty) {
  //           await Future.wait(subs);
  //         }
  //
  //         // Notify list screen the request was accepted
  //         Get.back(result: 'accepted');
  //       } else {
  //         throw Exception(response['message'] ?? 'Failed to submit bid');
  //       }
  //
  //       showSuccess("Your bid of PKR $fareOffered was submitted successfully!");
  //     }, maxRetries: 2);
  //   } catch (e) {
  //     print("❌ Failed to submit bid: $e");
  //     showError("Failed to submit ride bid. Please try again.");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  // ✅ UPDATED: Now stays on screen and waits for events
  Future<void> acceptRide(String rideId, double fareOffered) async {
    try {
      // ✅ VALIDATION: Check if fare is at least original amount
      if (fareOffered < originalFare.value) {
        showError("Offer amount must be at least PKR ${originalFare.value}");
        return;
      }

      // Set loading and bid submission state
      isLoading.value = true;
      isBidSubmitted.value = true;
      bidStatus.value = "submitted";

      await executeWithRetry(() async {
        // ✅ Ensure auth token is set
        final token = StorageService.getAuthToken();
        if (token == null) {
          throw Exception("User not authenticated. Please login again.");
        }
        FHttpHelper.setAuthToken(token, useBearer: true);

        print("🚀 Submitting bid - Ride ID: $rideId, Fare: $fareOffered");
        final response = await FHttpHelper.post('ride/submit-bids', {
          "rideId": rideId,
          "fareOffered": fareOffered,
        });

        print("🚀 Ride bid response: $response");

        if (response['message'] == "Bid submitted") {
          final bid = response['bid'];
          String? driverId;
          if (bid != null) {
            final driverRaw = bid['driverId'] ?? bid['driver'] ?? response['driverId'];
            if (driverRaw is Map && driverRaw.containsKey('_id')) {
              driverId = driverRaw['_id']?.toString();
            } else if (driverRaw is String) {
              driverId = driverRaw;
            }
          }
          final submittedRideId = bid?['rideId']?.toString() ?? response['rideId']?.toString();

          final subs = <Future>[];

          if (driverId != null) {
            // Subscribe to driver channel for bid responses
            subs.add(_pusherManager.subscribeOnce(
              "driver-$driverId",
              events: {
                "bid-accepted": (data) => _handleBidResponse(data, "bid-accepted"),
                "bid-rejected": (data) => _handleBidResponse(data, "bid-rejected"),
                "bid-ignored": (data) => _handleBidResponse(data, "bid-ignored"),
              },
            ));
          } else {
            print("⚠️ driverId not found in submit-bids response");
          }

          if (submittedRideId != null) {
            subs.add(_pusherManager.subscribeOnce(
              "ride-$submittedRideId",
              events: {
                "driver-location": (data) {
                  print("📍 (detail) driver-location: $data");
                  try {
                    final lat = (data['lat'] != null) ? double.tryParse(data['lat'].toString()) : null;
                    final lng = (data['lng'] != null) ? double.tryParse(data['lng'].toString()) : null;
                    if (lat != null && lng != null) {
                      currentPosition.value = LatLng(lat, lng);
                    }
                  } catch (e) {
                    print("❌ Error parsing driver-location in detail controller: $e");
                  }
                },
              },
            ));
          } else {
            print("⚠️ rideId not found in API response");
          }

          if (subs.isNotEmpty) {
            await Future.wait(subs);
          }

          showSuccess("Your bid of PKR $fareOffered was submitted successfully! Waiting for response...");

          // REMOVED: Get.back(result: 'accepted'); - Now we stay on screen

        } else {
          throw Exception(response['message'] ?? 'Failed to submit bid');
        }
      }, maxRetries: 2);
    } catch (e) {
      print("❌ Failed to submit bid: $e");
      showError("Failed to submit ride bid. Please try again.");
      isLoading.value = false;
      isBidSubmitted.value = false;
    }
    // Note: We don't set isLoading to false here because we're waiting for events
  }

  void onSubmitOffer() {
    final entered = int.tryParse(offerController.text);
    if (entered == null) {
      showError("Enter a valid fare");
      return;
    }

    // ✅ VALIDATION: Check if entered amount is at least original fare
    if (entered < originalFare.value) {
      showError("Offer amount must be at least PKR ${originalFare.value}");
      return;
    }

    fare.value = entered;
    // Get.back();
  }

  void selectChip(int amount) {
    if (isChipSelected.value && selectedChipAmount.value == amount) {
      // Deselect if same chip is clicked again
      isChipSelected.value = false;
      selectedChipAmount.value = 0;
      fare.value = originalFare.value;
      offerController.clear();
    } else {
      // Select new chip
      isChipSelected.value = true;
      selectedChipAmount.value = amount;
      fare.value = amount;
      offerController.clear(); // Clear text field when chip is selected
    }
  }

  // ✅ NEW: Handle text field input
  void onOfferTextChanged(String value) {
    if (value.isNotEmpty) {
      // When user types, clear chip selection
      isChipSelected.value = false;
      selectedChipAmount.value = 0;

      final enteredAmount = int.tryParse(value);
      if (enteredAmount != null) {
        if (enteredAmount >= originalFare.value) {
          fare.value = enteredAmount;
        } else {
          // If amount is less than original, keep it but button will be disabled
          fare.value = enteredAmount;
        }
      }
    } else {
      // If text field is cleared, revert to original fare
      fare.value = originalFare.value;
    }
  }

  // ✅ NEW: Check if accept button should be enabled
  bool get isAcceptButtonEnabled {
    return fare.value >= originalFare.value && !isBidSubmitted.value;
  }

  // ✅ UPDATED: Close screen method with back button check
  void closeScreen() {
    if (isBidSubmitted.value) {
      FSnackbar.show(
          title: "Please Wait",
          message: "Cannot close while waiting for bid response",
          isError: true
      );
      return;
    }
    Get.back(result: isBidSubmitted.value ? 'submitted' : 'cancelled');
  }

  @override
  void onClose() {
    offerController.dispose();
    mapController = null;
    super.onClose();
  }
}