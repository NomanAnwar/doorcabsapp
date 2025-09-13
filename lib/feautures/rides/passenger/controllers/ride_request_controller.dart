import 'package:doorcab/feautures/rides/passenger/controllers/widgets/ride_request_reuseable_controllers/date_time_controller.dart';
import 'package:doorcab/feautures/rides/passenger/controllers/widgets/ride_request_reuseable_controllers/fare_calculator_controller.dart';
import 'package:doorcab/feautures/rides/passenger/controllers/widgets/ride_request_reuseable_controllers/map_controller.dart';
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

  // Add missing properties for the screen
  final List<String> passengerOptions = const ["1", "2", "3", "4", "More"];
  final List<TextInputFormatter> digitsOnly = [FilteringTextInputFormatter.digitsOnly];

  // Loading state
  final isLoading = false.obs;

  // Exposed getters
  TextEditingController get fareController => _fareController.fareController;
  RxString get userCity => _fareController.userCity;
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
  RxString get timeLabel => _dateTimeController.timeLabel;

  final PusherBeamsService _pusherBeams = PusherBeamsService();

  // Coordinates for API calls
  LatLng? pickupCoords;
  LatLng? dropoffCoords;
  List<Map<String, dynamic>> stopCoords = [];

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args is Map) {
      _initializeFromArgs(args);
    }

    ever(cities, (_) => _initializeData());
    ever(vehicleModels, (_) => _initializeData());

    _dateTimeController.initialize();

    _initializePushNotifications();
  }

  Future<void> _initializePushNotifications() async {
    await _pusherBeams.initialize();
    await _pusherBeams.registerDevice();
    // _pusherBeams.configureNotificationHandling();
  }

  void _initializeFromArgs(Map<dynamic, dynamic> args) {
    final stringArgs = args.map((key, value) => MapEntry(key.toString(), value));

    _mapController.initializeFromArgs(stringArgs);
    _fareController.initializeFromArgs(stringArgs);

    rideType.value = (args['rideType'] ?? '').toString();
    selectedRideIndexFromHome.value = args['selectedRideIndex'] ?? 0;

    if (args['selectedVehicle'] is Map) {
      selectedVehicleData.value = Map<String, dynamic>.from(
          args['selectedVehicle'] as Map<dynamic, dynamic>
      );
    } else {
      selectedVehicleData.value = null;
    }

    stops.clear();
    if (args['stops'] is List) {
      stops.assignAll((args['stops'] as List).map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
        }
        return <String, dynamic>{};
      }).toList());
    }

    // Store coordinates if provided
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
        _vehicleForRideTypeIndex
    );

    _mapController.determineUserCity(cities, pickupLocation.value);
    _calculateRouteAndFare();
  }

  Future<void> _calculateRouteAndFare() async {
    if (pickupLocation.value.isEmpty || dropoffLocation.value.isEmpty) return;

    try {
      final routeDetails = await _mapController.calculateRoute(
          pickupLocation.value,
          dropoffLocation.value,
          _geocodingService,
          stops
      );

      if (routeDetails != null) {
        _fareController.calculateAllFares(
            distanceKm.value,
            durationMinutes.value,
            cities,
            vehicleModels,
            userCity.value
        );
      }
    } catch (e) {
      print('❌ Error calculating route: $e');
    }
  }

  VehicleModel? _vehicleForRideTypeIndex(int index) {
    return _fareController.vehicleForRideTypeIndex(index, rideTypes, vehicleModels);
  }

  @override
  void onSelectRide(int index) {
    super.onSelectRide(index);
    _fareController.updateSelectedRide(index, rideTypes, vehicleModels, _vehicleForRideTypeIndex);
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
        _vehicleForRideTypeIndex
    );
  }

  void incrementFare() => _fareController.incrementFare();
  void decrementFare() => _fareController.decrementFare();

  Future<void> onRequestRide() async {
    if (pickupLocation.value.isEmpty || dropoffLocation.value.isEmpty) {
      Get.snackbar('Missing fields', 'Pickup and Drop-off are required.');
      return;
    }

    // Validate coordinates
    if (pickupCoords == null || dropoffCoords == null) {
      Get.snackbar('Error', 'Could not determine coordinates for locations.');
      return;
    }

    isLoading.value = true;

    try {
      // Prepare the request body
      final requestBody = await _prepareRideRequestBody();

      final token = StorageService.getAuthToken();

      if (token == null) {
        Get.snackbar("Error", "User token not found. Please login again.");
      }

      FHttpHelper.setAuthToken(token!, useBearer: true);


      // Call the ride request API
      final response = await FHttpHelper.post('ride/request', requestBody);

      print("Ride Request API Response : "+response.toString());

      // Handle successful response
      if (response['message'] == 'Ride requested successfully.') {
        final rideData = response['ride'];
        final rideId = rideData['_id'];

        // Send push notification to nearby drivers
        await _sendPushNotificationToDrivers(rideData);

        Get.snackbar('Success', 'Ride requested successfully!');

        // Navigate to available drivers screen with ride details
        Get.toNamed('/available-drivers', arguments: {
          'rideId': rideId,
          'rideData': rideData,
          'pickup': pickupLocation.value,
          'dropoff': dropoffLocation.value,
          'stops': stops.toList(),
          'rideType': selectedVehicle.value?.name ?? rideType.value,
          'fare': fareController.text,
          'passengers': selectedPassengers.value,
          'payment': selectedPaymentLabel.value,
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to request ride');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to request ride: ${e.toString()}');
      print('❌ Ride request error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> _prepareRideRequestBody() async {
    // Get coordinates for all stops
    final dropoffs = await _getStopCoordinates();

    // Get fare breakdown (you might need to calculate this based on your fare logic)
    final fareBreakdown = _calculateFareBreakdown();

    return {
      "pickup_lat": pickupCoords!.latitude,
      "pickup_lng": pickupCoords!.longitude,
      "dropoffs": dropoffs,
      "distance": distanceKm.value,
      "vehicle_type": selectedVehicle.value?.name ?? rideType.value,
      "requested_rideFare": double.parse(fareController.text),
      "fare": fareBreakdown,
      "payment_type": selectedPaymentLabel.value.toLowerCase(),
      "passengers_no": selectedPassengers.value,
      "request_datetime": selectedDate.value != null && selectedTime.value != null
          ? _formatDateTime(selectedDate.value!, selectedTime.value!)
          : DateTime.now().toIso8601String(),
    };
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

  Map<String, dynamic> _calculateFareBreakdown() {
    // This should be implemented based on your fare calculation logic
    // For now, using simplified breakdown
    final totalFare = double.parse(fareController.text);

    return {
      "baseFare": totalFare * 0.4, // 40% base fare
      "distanceCharges": totalFare * 0.5, // 50% distance charges
      "surgeCharges": totalFare * 0.1, // 10% surge charges
      "discount": 0,
      "waiting_charge_amount": 0
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

  Future<void> _sendPushNotificationToDrivers(Map<String, dynamic> rideData) async {
    try {
      final notificationBody = {
        "pickup": {
          "lat": pickupCoords!.latitude,
          "lng": pickupCoords!.longitude,
          "address": pickupLocation.value,
        },
        "dropoffs": await _getNotificationDropoffs(),
        "amount": double.parse(fareController.text),
      };

      // Call the push notification endpoint
      await FHttpHelper.post('ride/push-notification', notificationBody);

      print('✅ Push notification sent to drivers');
    } catch (e) {
      print('❌ Error sending push notification: $e');
      // Don't throw error here - ride request was successful, just notification failed
    }
  }

  Future<List<Map<String, dynamic>>> _getNotificationDropoffs() async {
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
}