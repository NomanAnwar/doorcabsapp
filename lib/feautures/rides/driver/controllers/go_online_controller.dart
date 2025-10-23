import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:doorcab/feautures/shared/services/enhanced_pusher_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:doorcab/feautures/shared/services/storage_service.dart';
import '../../../../main.dart';
import '../../../../utils/http/http_client.dart';
import '../../../shared/controllers/base_controller.dart';
import '../models/request_model.dart';

class GoOnlineController extends BaseController {
  var isOnline = false.obs;
  var currentPosition = Rx<LatLng?>(null);
  var isLoadingLocation = true.obs;
  GoogleMapController? mapController;

  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();
  final Set<String> _subscribedChannels = {};
  bool _hasReceivedFirstRequest = false;

  BitmapDescriptor? customMarker;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();


  var flagPosition = Rx<LatLng?>(null);
  var isFlagSet = false.obs;
  var markers = <Marker>{}.obs;
  var flagMarkerId = const MarkerId('flag_marker');
  CameraPosition? _currentCameraPosition; // Track camera position
  var isMapRotated = false.obs;
  var currentBearing = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCustomMarker().then((_) {
      getCurrentLocation();
    });
    _restoreOnlineStatus();
  }

  @override
  void onClose() {
    // _unsubscribeFromChannels();
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

  Future<void> getCurrentLocation() async {
    try {
      isLoadingLocation(true);
      await executeWithRetry(() async {
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

  // ADD THIS METHOD FOR MOVE ICON
  Future<void> centerMapLocation() async {
    if (currentPosition.value != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentPosition.value!,
            zoom: 15.0,
          ),
        ),
      );
      print('🎯 Map centered to current location');
    } else {
      print('⚠️ Cannot center map: location or controller not available');
      // Try to get location first if not available
      await getCurrentLocation();
      if (currentPosition.value != null && mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentPosition.value!,
              zoom: 15.0,
            ),
          ),
        );
      }
    }
  }

  // void toggleOnline() async {
  //
  //   final body = {
  //     "is_online": !isOnline.value,
  //   };
  //
  //   final token = StorageService.getAuthToken();
  //   if (token == null) {
  //     print("Error" + "User token not found. Please login again.");
  //     return; // ✅ prevent crash
  //   }
  //
  //   FHttpHelper.setAuthToken(token, useBearer: true);
  //
  //   final response  = await FHttpHelper.post("driver/online", body);
  //
  //
  //   print("driver online response : "+ response['is_online'].toString());
  //   final newStatus = !isOnline.value;
  //   isOnline.value = newStatus;
  //   await StorageService.setDriverOnlineStatus(newStatus);
  //
  //   if (newStatus && response['is_online']) {
  //     await _subscribeToChannels();
  //     FSnackbar.show(title: "Online",message: 'You are now online and receiving ride requests');
  //   } else {
  //     // await _unsubscribeFromChannels();
  //     _hasReceivedFirstRequest = false;
  //     FSnackbar.show(title: 'You are now offline', message: "", isError: true);
  //   }
  // }


  Future<void> toggleOnline() async {
    final newStatus = !isOnline.value;
    final body = {"is_online": newStatus};

    final token = StorageService.getAuthToken();
    if (token == null) {
      FSnackbar.show(title: "Error", message: "User token not found. Please login again.", isError: true);
      return;
    }

    FHttpHelper.setAuthToken(token, useBearer: true);

    try {
      final response = await FHttpHelper.post("driver/online", body);
      print("Driver online API response: $response");

      final serverStatus = response['is_online'] ?? false;

      isOnline.value = serverStatus;
      await StorageService.setDriverOnlineStatus(serverStatus);

      if (serverStatus) {
        await _subscribeToChannels();
        FSnackbar.show(title: "Online", message: response['message'] ?? "You are now online");
      } else {
        _hasReceivedFirstRequest = false;
        FSnackbar.show(title: "Offline", message: response['message'] ?? "You are now offline", isError: true);
      }
    } catch (e, s) {
      print("❌ toggleOnline error: $e\n$s");
      FSnackbar.show(title: "Error", message: "Failed to toggle online status", isError: true);
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
                FSnackbar.show(title: "Ride Request", message: "New Ride Request is here.");
                _handleNewRideRequest(data);
              },
            },
          );
          _subscribedChannels.add(privateChannel);
          print("✅ GoOnlineController subscribed to: $privateChannel");
          FSnackbar.show(title: 'Request request', message: '$privateChannel');
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
        if (!_hasReceivedFirstRequest) {
          _hasReceivedFirstRequest = true;
          print("✅ First ride request - navigating to RideRequestListScreen");

          // Navigate to RideRequestListScreen with the request
          Get.toNamed('/ride-request-list', arguments: {
            'initialRequest': request,
            'isFromGoOnline': true
          });
        }
      } else {
        print("ℹ️ Ride request received but driver is offline");
        // Get.snackbar(
        //   'Ride Request Nearby',
        //   'Ride requests are coming near you! Go online to accept rides.',
        //   duration: const Duration(seconds: 2),
        //   snackPosition: SnackPosition.TOP,
        //   backgroundColor: Colors.orange,
        //   colorText: Colors.white,
        //   margin: const EdgeInsets.all(10),
        // );
        FSnackbar.show(title: 'Ride Request', message: 'Ride requests are coming near you! Go online to accept rides.');
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

  // COMPASS FUNCTIONALITY METHODS
  void toggleCompass() {
    if (isMapRotated.value) {
      // Reset to North-up
      resetMapToNorth();
    } else {
      // Show compass and current orientation
      showCompass();
    }
  }

  void resetMapToNorth() {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentCameraPosition?.target ?? currentPosition.value!,
            zoom: _currentCameraPosition?.zoom ?? 15.0,
            bearing: 0.0, // Reset to North
            tilt: 0.0,    // Reset to flat view
          ),
        ),
      );
      isMapRotated.value = false;
      currentBearing.value = 0.0;
      print('🧭 Map reset to North');
    }
  }

  void showCompass() {
    // This will show the built-in compass when map is rotated
    // The compass appears automatically when bearing != 0
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentCameraPosition?.target ?? currentPosition.value!,
            zoom: _currentCameraPosition?.zoom ?? 15.0,
            bearing: currentBearing.value,
            tilt: 45.0, // Slight tilt for 3D effect
          ),
        ),
      );
      print('🧭 Compass mode activated');
    }
  }

// Update camera movement to track rotation
  void onCameraMove(CameraPosition position) {
    _currentCameraPosition = position;
    currentBearing.value = position.bearing;
    isMapRotated.value = position.bearing != 0.0;
  }

  void navigateToRideRequestList() {
    Get.toNamed('/ride-request-list');
  }

  // ADD FLAG FUNCTIONALITY METHODS

  void onMapTap(LatLng position) {
    if (isFlagSet.value) {
      // Update existing flag position
      updateFlagPosition(position);
    } else {
      // Optionally: Set flag on first tap if not set
      // setFlagPosition(position);
    }
  }

  void toggleFlag() {
    if (isFlagSet.value) {
      // Remove flag
      removeFlag();
      showSuccess('Flag removed');
    } else {
      // Add flag at current map center or user's location
      addFlagAtCenter();
    }
  }

  Future<void> addFlagAtCenter() async {
    if (_currentCameraPosition != null) {
      // Use the last known camera position
      final currentCenter = _currentCameraPosition!.target;
      setFlagPosition(currentCenter);
      showSuccess('Flag set at current map center');
    } else if (currentPosition.value != null) {
      // Use current location if camera position not available
      setFlagPosition(currentPosition.value!);
      showSuccess('Flag set at your current location');
    } else {
      showError('Unable to set flag - no location available');
      // Try to get location
      await getCurrentLocation();
      if (currentPosition.value != null) {
        setFlagPosition(currentPosition.value!);
        showSuccess('Flag set at your current location');
      }
    }
  }

  void setFlagPosition(LatLng position) {
    flagPosition.value = position;
    isFlagSet.value = true;

    // Create flag marker
    final flagMarker = Marker(
      markerId: flagMarkerId,
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Destination', snippet: 'Tap to remove'),
      onTap: () {
        // Show options when flag is tapped
        showFlagOptionsDialog();
      },
    );

    markers.add(flagMarker);
    print('🚩 Flag set at: ${position.latitude}, ${position.longitude}');
  }

  void updateFlagPosition(LatLng newPosition) {
    flagPosition.value = newPosition;

    // Update existing marker
    markers.removeWhere((marker) => marker.markerId == flagMarkerId);

    final updatedMarker = Marker(
      markerId: flagMarkerId,
      position: newPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Destination', snippet: 'Tap to remove'),
      onTap: () {
        showFlagOptionsDialog();
      },
    );

    markers.add(updatedMarker);
    print('🚩 Flag moved to: ${newPosition.latitude}, ${newPosition.longitude}');
  }

  void removeFlag() {
    flagPosition.value = null;
    isFlagSet.value = false;
    markers.removeWhere((marker) => marker.markerId == flagMarkerId);
    print('🚩 Flag removed');
  }

  // Method to show options when flag is tapped
  void showFlagOptionsDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Flag Options'),
        content: const Text('What would you like to do with this flag?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              removeFlag();
              showSuccess('Flag removed');
            },
            child: const Text('Remove Flag'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              moveToFlag();
            },
            child: const Text('Center Map'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Method to move map to flag position
  void moveToFlag() {
    if (flagPosition.value != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: flagPosition.value!,
            zoom: 15.0,
          ),
        ),
      );
      print('🎯 Moving to flag position');
      showSuccess('Map centered on flag');
    } else {
      showError('No flag set to move to');
    }
  }

  // Method to get directions to flag
  void getDirectionsToFlag() {
    if (flagPosition.value != null && currentPosition.value != null) {
      print('📍 Getting directions from current location to flag');
      // You can integrate with Google Directions API here
      showSuccess('Directions to flag position requested');
    } else {
      showError('Please set a flag first');
    }
  }
}