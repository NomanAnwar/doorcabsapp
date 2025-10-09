import 'package:doorcab/feautures/shared/services/enhanced_pusher_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import '../../../../main.dart'; // ✅ Import main to access global instances
import '../../../shared/controllers/base_controller.dart';
import '../models/request_model.dart';


class GoOnlineController extends BaseController {
  var isOnline = false.obs;
  var currentPosition = Rx<LatLng?>(null);
  var isLoadingLocation = true.obs;
  GoogleMapController? mapController;

  // ✅ FIXED: Use global instances from main.dart
  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
  final Set<String> _subscribedChannels = {};
  bool _hasReceivedFirstRequest = false;

  // Custom marker
  BitmapDescriptor? customMarker;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void onInit() {
    super.onInit();
    _loadCustomMarker().then((_) {
      getCurrentLocation();
    });

    // Restore online status
    _restoreOnlineStatus();
  }

  @override
  void onClose() {
    // Unsubscribe from channels when controller is closed
    _unsubscribeFromChannels();
    super.onClose();
  }

  void _restoreOnlineStatus() {
    final wasOnline = StorageService.getDriverOnlineStatus();
    if (wasOnline) {
      print('🔄 Restoring previous online status: $wasOnline');
      isOnline.value = true;
      _subscribeToChannels();
    }
  }

  // Load custom marker icon from assets
  Future<void> _loadCustomMarker() async {
    try {
      await executeWithRetry(() async {
        print('🎯 Loading custom marker...');

        final Uint8List markerIcon = await _loadAndResizeImage(
          'assets/images/position_marker2.png',
          120,
        );

        customMarker = BitmapDescriptor.fromBytes(markerIcon);
        print('✅ Custom marker loaded successfully');
      });
    } catch (e) {
      print('❌ Error loading custom marker: $e');
      customMarker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  // ✅ FIXED: Properly return Uint8List
  Future<Uint8List> _loadAndResizeImage(String assetPath, int targetSize) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetSize,
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ByteData? byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to convert image to bytes');
    }

    return byteData.buffer.asUint8List();
  }

  // Get current location
  Future<void> getCurrentLocation() async {
    try {
      isLoadingLocation(true);

      await executeWithRetry(() async {
        // Check permission
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled.');
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permissions are denied');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are permanently denied.');
        }

        // Get current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        currentPosition.value = LatLng(position.latitude, position.longitude);

        print('📍 Current location: ${position.latitude}, ${position.longitude}');
      });
    } catch (e) {
      print('❌ Error getting location: $e');
      showError('Failed to get current location: $e');
      currentPosition.value = null;
    } finally {
      isLoadingLocation(false);
    }
  }

  // Move camera to current location
  void moveToCurrentLocation() {
    if (currentPosition.value != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(currentPosition.value!),
      );
    } else {
      getCurrentLocation().then((_) {
        if (currentPosition.value != null && mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLng(currentPosition.value!),
          );
        }
      });
    }
  }

  void toggleOnline() async {
    final newStatus = !isOnline.value;
    isOnline.value = newStatus;

    // Save online status
    await StorageService.setDriverOnlineStatus(newStatus);

    if (newStatus) {
      // Going online - subscribe to channels
      await _subscribeToChannels();
      showSuccess('You are now online and receiving ride requests');
    } else {
      // Going offline - unsubscribe from channels
      await _unsubscribeFromChannels();
      _hasReceivedFirstRequest = false; // Reset flag
      showSuccess('You are now offline');
    }
  }

  Future<void> _subscribeToChannels() async {
    final driverId = StorageService.getSignUpResponse()!.userId;
    final privateChannel = "private-driver-$driverId";

    try {
      await executeWithRetry(() async {
        if (!_subscribedChannels.contains(privateChannel)) {
          await _pusherManager.subscribeOnce(
            privateChannel,
            events: {
              "ride-request": (data) {
                _handleNewRideRequest(data);
              },
            },
          );
          _subscribedChannels.add(privateChannel);
          print("✅ GoOnlineController subscribed to: $privateChannel");
        }
      });
    } catch (e) {
      print('❌ Error subscribing to channels in GoOnlineController: $e');
      showError('Failed to subscribe to ride requests');
    }
  }

  Future<void> _unsubscribeFromChannels() async {
    try {
      await executeWithRetry(() async {
        for (final channel in _subscribedChannels) {
          _pusherManager.unsubscribeSafely(channel);
          print("✅ GoOnlineController unsubscribed from: $channel");
        }
        _subscribedChannels.clear();
      });
    } catch (e) {
      print('❌ Error unsubscribing from channels in GoOnlineController: $e');
    }
  }

  void _handleNewRideRequest(Map<String, dynamic> data) {
    print("🚖 New ride request received in GoOnlineController: $data");

    try {
      final request = RequestModel.fromJson(data);

      if (isOnline.value) {
        // Driver is online - navigate to RideRequestListScreen with the request
        if (!_hasReceivedFirstRequest) {
          _hasReceivedFirstRequest = true;
          print("✅ First ride request - navigating to RideRequestListScreen");

          // Navigate to RideRequestListScreen with the request
          Get.offNamed('/ride-request-list', arguments: {
            'initialRequest': request,
            'isFromGoOnline': true
          });
        }
      } else {
        // Driver is offline - show snackbar
        print("ℹ️ Ride request received but driver is offline");
        Get.snackbar(
          'Ride Request Nearby',
          'Ride requests are coming near you! Go online to accept rides.',
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          margin: const EdgeInsets.all(10),
        );
      }
    } catch (e, s) {
      print("❌ Error handling ride request in GoOnlineController: $e");
      print(s);
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;

    if (currentPosition.value != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        moveToCurrentLocation();
      });
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (currentPosition.value != null) {
          moveToCurrentLocation();
        }
      });
    }
  }

  // Method to manually navigate to ride request list (if needed)
  void navigateToRideRequestList() {
    Get.toNamed('/ride-request-list');
  }
}