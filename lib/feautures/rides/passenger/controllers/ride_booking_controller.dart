import 'package:doorcab/feautures/rides/passenger/controllers/widgets/comments_sheet.dart';
import 'package:doorcab/feautures/rides/passenger/controllers/widgets/payment_methods_sheet.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import '../../../../utils/http/http_client.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/services/pusher_beams.dart';
import '../../../shared/services/storage_service.dart';
import '../models/city_model.dart';
import '../models/ride_option_model.dart';
import '../models/ride_type_screen_model.dart';
import '../../../shared/services/enhanced_pusher_manager.dart';

class RideBookingController extends BaseController { // ✅ CHANGED: Extend BaseController
  // ======= State & Observables =======
  var autoAccept = false.obs;
  var pickupLocation = ''.obs;
  var dropoffLocation = ''.obs;
  var stops = <Map<String, dynamic>>[].obs;

  final bids = <Map<String, dynamic>>[].obs;

  var mapReady = false.obs;
  var selectedPassengers = 1.obs;
  var rideType = ''.obs;
  var selectedDate = Rx<DateTime?>(null);
  var selectedTime = Rx<TimeOfDay?>(null);
  final fareController = TextEditingController();

  final RxString selectedRideType = ''.obs;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? mapController;
  var markers = <Marker>[].obs;
  var polylines = <Polyline>[].obs;

  // Coordinates from params
  LatLng? pickupCoords;
  LatLng? dropoffCoords;
  List<LatLng> stopCoords = [];

  var selectedPaymentLabel = 'Cash'.obs;
  var comment = ''.obs;

  // API Data and fare calculation variables
  var cities = <dynamic>[].obs;
  var vehicles = <dynamic>[].obs;
  var service = Rx<dynamic>(null);
  var userLocation = Rx<Map<String, dynamic>?>(null);

  var distanceKm = 0.0.obs;
  var durationMinutes = 0.obs;
  var isCalculatingFare = false.obs;
  var userCityName = ''.obs;

  // Using dynamic ride options from API
  final rideOptions = <RideOption>[].obs;

  late final Map<String, RxInt> ridePassengers;
  late final Map<String, RxInt> rideFare;

  // Store calculated minimum fares
  final Map<String, double> _minimumFares = {};

  final EnhancedPusherManager _pusherManager = EnhancedPusherManager();

  var isRequestingRide = false.obs;
  var isCalculatingRoute = false.obs;
  var isLoadingRideOptions = false.obs;

  // Marker icons
  BitmapDescriptor? pickupBitmap;
  BitmapDescriptor? dropoffBitmap;
  BitmapDescriptor? stopBitmap;

  // Camera position
  final CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 16.0,
  );

  // ======= Lifecycle =======
  @override
  void onInit() {
    super.onInit();
    debugPrint('\n===== onInit START =====');

    final args = Get.arguments as Map?;
    debugPrint('onInit: Got arguments = ${args == null ? 'null' : args.keys.toList()}');

    _debugPrintArguments(args);

    _initializeFromArguments(args);
    _initializePassengerFareMaps();
    _preloadMarkerIcons();

    isLoadingRideOptions.value = true;

    debugPrint('===== onInit END =====\n');
  }

  // ======= Getters =======
  RideOption? get selectedVehicle {
    if (selectedRideType.value.isEmpty) return null;
    return rideOptions.firstWhereOrNull((r) => r.id == selectedRideType.value);
  }

  String get selectedVehicleName {
    return selectedVehicle?.name ?? '';
  }

  int get selectedVehicleFare {
    return rideFare[selectedRideType.value]?.value ?? 0;
  }

  String get userCity {
    return userCityName.value;
  }

  // ======= Helpers: Stop coords & notifications =======
  Future<List<Map<String, dynamic>>> _getStopCoordinates() async {
    debugPrint('===== _getStopCoordinates START =====');
    final List<Map<String, dynamic>> dropoffs = [];

    for (int i = 0; i < stopCoords.length; i++) {
      dropoffs.add({
        "lat": stopCoords[i].latitude,
        "lng": stopCoords[i].longitude,
        "address": stops[i]['description']?.toString() ?? "Stop ${i + 1}",
        "order": dropoffs.length + 1,
      });
      debugPrint('  added stop ${i + 1}: ${dropoffs.last}');
    }

    if (dropoffCoords != null) {
      dropoffs.add({
        "lat": dropoffCoords!.latitude,
        "lng": dropoffCoords!.longitude,
        "address": dropoffLocation.value,
        "order": dropoffs.length + 1,
      });
      debugPrint('  added main dropoff: ${dropoffs.last}');
    }

    debugPrint('===== _getStopCoordinates END, total=${dropoffs.length} =====');
    return dropoffs;
  }

  Future<List<Map<String, dynamic>>> _getNotification_dropoffs() async {
    debugPrint('Calling _getNotification_dropoffs');
    return await _getStopCoordinates();
  }

  // ======= Fare breakdown =======
  Map<String, dynamic> _calculateFareBreakdown() {
    debugPrint('===== _calculateFareBreakdown START =====');
    final selected = selectedVehicle;
    if (selected == null) {
      debugPrint('  No selected vehicle -> returning 0');
      return {"total_fare": 0.0};
    }

    final apiData = selected.apiData;
    final baseFare = (apiData?['base_fare'] as double?) ?? 0;
    final perKmCharge = (apiData?['per_km_charge'] as double?) ?? 0;
    final cityData = _getCityData(userCity);

    final distanceCharge = (distanceKm.value * perKmCharge).roundToDouble();
    final surgeMultiplier = (cityData?['is_surged'] == true)
        ? (cityData?['surge_value'] as num?)?.toDouble() ?? 1.0
        : 1.0;
    final totalFare = selectedVehicleFare.toDouble();

    final result = {
      "base_fare": baseFare,
      "distance_charge": distanceCharge,
      "surge_multiplier": surgeMultiplier,
      "total_fare": totalFare,
    };

    debugPrint('  Fare breakdown -> $result');
    debugPrint('===== _calculateFareBreakdown END =====');
    return result;
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return combined.toIso8601String();
  }

  // ======= Argument debug printing =======
  void _debugPrintArguments(Map? args) {
    debugPrint('\n===== _debugPrintArguments START =====');
    if (args == null) {
      debugPrint('  No arguments passed to RideBookingScreen');
      debugPrint('===== _debugPrintArguments END =====\n');
      return;
    }

    debugPrint('  All argument keys: ${args.keys.toList()}');

    if (args['service'] != null) {
      final service = args['service'];
      if (service is RideTypeScreenModel) {
        debugPrint('  Service: ${service.categoryName}, vehicles: ${service.vehicleList.length}');
      }
    }

    if (args['vehicles'] is List) {
      final v = args['vehicles'] as List;
      debugPrint('  vehicles length: ${v.length}');
    }

    if (args['cities'] is List) {
      final c = args['cities'] as List;
      debugPrint('  cities length: ${c.length}');
    }

    debugPrint('  pickup: ${args['pickup']}');
    debugPrint('  dropoff: ${args['dropoff']}');
    debugPrint('  stops count: ${args['stops'] is List ? (args['stops'] as List).length : 0}');
    debugPrint('===== _debugPrintArguments END =====\n');
  }

  // ======= Initialization from arguments =======
  void _initializeFromArguments(Map? args) {
    debugPrint('\n===== _initializeFromArguments START =====');

    if (args == null) {
      throw Exception('No arguments passed to RideBookingScreen');
    }

    pickupLocation.value = args['pickup']?.toString() ?? 'Pickup Location';
    dropoffLocation.value = args['dropoff']?.toString() ?? 'Dropoff Location';
    debugPrint('  pickupLocation set to: ${pickupLocation.value}');
    debugPrint('  dropoffLocation set to: ${dropoffLocation.value}');

    if (args['stops'] is List) {
      stops.assignAll((args['stops'] as List).cast<Map<String, dynamic>>());
      debugPrint('  stops assigned, count=${stops.length}');
    }

    if (args['cities'] is List) {
      cities.assignAll(args['cities'] as List);
      debugPrint('  cities assigned, count=${cities.length}');
    }

    if (args['vehicles'] is List) {
      vehicles.assignAll(args['vehicles'] as List);
      debugPrint('  vehicles assigned, count=${vehicles.length}');
      _buildRideOptionsFromApi();
    } else {
      throw Exception('No vehicles data received');
    }

    if (args['service'] != null) {
      service.value = args['service'];
      debugPrint('  service assigned');
    }

    if (args['userLocation'] is Map) {
      userLocation.value = Map<String, dynamic>.from(args['userLocation']);
      debugPrint('  userLocation assigned: ${userLocation.value}');
    }

    // Determine user city using pickup lat/lng if available, else address fallback
    if (args['pickupLat'] != null && args['pickupLng'] != null) {
      final pickupLatLng = LatLng((args['pickupLat'] as num).toDouble(), (args['pickupLng'] as num).toDouble());
      pickupCoords = pickupLatLng;
      debugPrint('  pickupCoords set from args: $pickupCoords');

      _determineUserCity(pickupLatLng);
    } else if (args['userCurrentAddress'] is String) {
      debugPrint('  fallback: userCurrentAddress available, calling _determineUserCity with address');
      _determineUserCity(args['userCurrentAddress'] as String);
    }

    if (args['dropoffLat'] != null && args['dropoffLng'] != null) {
      dropoffCoords = LatLng((args['dropoffLat'] as num).toDouble(), (args['dropoffLng'] as num).toDouble());
      debugPrint('  dropoffCoords set from args: $dropoffCoords');
    }

    _processStopCoordinates();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('  scheduling _calculateRouteAndUpdateMap');
      _calculateRouteAndUpdateMap();
    });

    debugPrint('===== _initializeFromArguments END =====\n');
  }

  // ======= Build ride options =======
  void _buildRideOptionsFromApi() {
    debugPrint('\n===== _buildRideOptionsFromApi START =====');
    final options = <RideOption>[];

    if (vehicles.isEmpty) {
      throw Exception('No vehicles data available');
    }

    debugPrint('  processing ${vehicles.length} vehicle items');

    for (final vehicle in vehicles) {
      if (vehicle is Vehicle) {
        final vehicleName = vehicle.vehicleName;
        final baseFare = double.tryParse(vehicle.baseFare) ?? 0;
        final perKmCharge = double.tryParse(vehicle.perKmCharge) ?? 0;
        final passengers = vehicle.noOfPassengers;
        final vehicleId = vehicle.id;

        debugPrint('   -> vehicle: $vehicleName, baseFare: $baseFare, perKm: $perKmCharge');

        options.add(RideOption(
          id : vehicleId,
          name : vehicleName,
          imageAsset : _getVehicleImage(vehicleName),
          subtitle : '$passengers passengers • Calculating...',
          description : _getVehicleDescription(vehicleName),
          fare : 'Calculating...',
          initialPassengers : int.tryParse(passengers)!,
          minPassengers : 1,
          maxPassengers : int.tryParse(passengers)!,
          initialFare : baseFare.toInt(),
          categoryIcon : vehicle.icon,
          isBase64Image : vehicle.icon.isNotEmpty,
          apiData : {
            'base_fare': baseFare,
            'per_km_charge': perKmCharge,
            'vehicle_name': vehicleName,
          },
        ));
      } else {
        debugPrint('  Unexpected vehicle type: ${vehicle.runtimeType}');
        throw Exception('Unknown vehicle type in vehicles list: ${vehicle.runtimeType}');
      }
    }

    rideOptions.assignAll(options);
    isLoadingRideOptions.value = false;
    debugPrint('  Built rideOptions count=${rideOptions.length}');
    debugPrint('===== _buildRideOptionsFromApi END =====\n');
  }

  void _initializePassengerFareMaps() {
    debugPrint('===== _initializePassengerFareMaps START =====');
    ridePassengers = {for (final ride in rideOptions) ride.id: RxInt(ride.initialPassengers)};
    rideFare = {for (final ride in rideOptions) ride.id: RxInt(ride.initialFare)};
    debugPrint('  Initialized passenger map and fare map');
    debugPrint('===== _initializePassengerFareMaps END =====\n');
  }

  // ======= City & city-data lookup =======
  Map<String, dynamic>? _getCityData(String cityName) {
    debugPrint('===== _getCityData START for "$cityName" =====');
    try {
      final city = cities.firstWhere((city) {
        if (city is CityModel) {
          return city.cityName.toLowerCase() == cityName.toLowerCase();
        } else if (city is Map<String, dynamic>) {
          return (city['city_name'] as String?)?.toLowerCase() == cityName.toLowerCase();
        }
        return false;
      });

      debugPrint('  matched city object: ${city.runtimeType}');

      if (city is CityModel) {
        final result = {
          'fare': city.fare,
          'is_surged': city.isSurged,
          'surge_value': city.surgeValue,
          'city_name': city.cityName,
        };
        debugPrint('===== _getCityData END -> $result =====');
        return result;
      } else if (city is Map<String, dynamic>) {
        debugPrint('===== _getCityData END -> Map returned =====');
        return city;
      }
    } catch (e) {
      debugPrint('  ❌ Error getting city data: $e');
    }

    debugPrint('===== _getCityData END -> null =====');
    return null;
  }

  // ======= Fare calculation per vehicle =======
  double _calculateFareForVehicle(RideOption vehicle, Map<String, dynamic>? cityData) {
    debugPrint('\n===== _calculateFareForVehicle START for vehicle=${vehicle.name} =====');
    final apiData = vehicle.apiData;
    if (apiData == null) {
      throw Exception('No API data for vehicle: ${vehicle.name}');
    }

    final baseFare = (apiData['base_fare'] as double?) ?? 0;
    final perKmCharge = (apiData['per_km_charge'] as double?) ?? 0;

    final cityBaseFare = (cityData?['fare'] as num?)?.toDouble() ?? 0;
    final surgeMultiplier = (cityData?['is_surged'] == true)
        ? (cityData?['surge_value'] as num?)?.toDouble() ?? 1.0
        : 1.0;

    final distance = distanceKm.value;
    if (distance <= 0) {
      throw Exception('Invalid distance for fare calculation: $distance');
    }

    debugPrint('  cityBaseFare: $cityBaseFare, baseFare(vehicle): $baseFare, perKm: $perKmCharge');
    debugPrint('  distance: $distance, surge: $surgeMultiplier');

    final basePrice = cityBaseFare > 0 ? cityBaseFare : baseFare;
    final distancePrice = distance * perKmCharge;
    final subtotal = basePrice + distancePrice;
    final totalFare = subtotal * surgeMultiplier;

    final minimumFare = baseFare > 0 ? baseFare : vehicle.initialFare.toDouble();
    final finalFare = totalFare < minimumFare ? minimumFare : totalFare;

    debugPrint('  computed basePrice: $basePrice');
    debugPrint('  distancePrice: $distancePrice');
    debugPrint('  subtotal: $subtotal');
    debugPrint('  totalFare (after surge): $totalFare');
    debugPrint('  minimumFare applied: $minimumFare');
    debugPrint('  finalFare: $finalFare');
    debugPrint('===== _calculateFareForVehicle END -> $finalFare =====\n');

    return finalFare.roundToDouble();
  }

  // ======= Calculate fares for all vehicles =======
  void calculateFaresForAllVehicles() {
    debugPrint('\n===== calculateFaresForAllVehicles START =====');

    debugPrint('  distanceKm currently: ${distanceKm.value}');
    if (distanceKm.value <= 0.0) {
      debugPrint('  ⚠️ Cannot calculate fares: distance is ${distanceKm.value}');
      return;
    }

    if (rideOptions.isEmpty) {
      debugPrint('  ⚠️ No ride options available for fare calculation');
      return;
    }

    isCalculatingFare.value = true;

    try {
      final cityData = _getCityData(userCityName.value);
      debugPrint('  cityData found: ${cityData ?? 'null'}');

      for (final option in rideOptions) {
        debugPrint('  -> calculating for option: ${option.name}');
        final calculatedFare = _calculateFareForVehicle(option, cityData);

        _minimumFares[option.id] = calculatedFare;

        if (rideFare.containsKey(option.id)) {
          rideFare[option.id]!.value = calculatedFare.round();
          debugPrint('    rideFare[${option.id}] updated to ${rideFare[option.id]!.value}');
        }

        if (selectedRideType.value == option.id) {
          fareController.text = calculatedFare.round().toString();
          debugPrint('    fareController.text updated for selected type: ${fareController.text}');
        }

        final etaText = '${durationMinutes.value} min';
        final index = rideOptions.indexWhere((r) => r.id == option.id);
        if (index != -1) {
          final updatedOption = rideOptions[index].copyWith(
            fare: '~PKR ${calculatedFare.round()}',
            subtitle: '${option.initialPassengers} passengers • $etaText',
          );
          rideOptions[index] = updatedOption;
          debugPrint('    rideOptions[${index}] updated with fare & subtitle');
        }
      }

      debugPrint('  💰 Successfully calculated fares for ${rideOptions.length} vehicles');
    } catch (e) {
      debugPrint('  ❌ Error calculating fares: $e');
    } finally {
      isCalculatingFare.value = false;
      debugPrint('===== calculateFaresForAllVehicles END =====\n');
    }
  }

  // ======= Select ride type =======
  void selectRideType(String type) {
    debugPrint('selectRideType called with: $type');
    selectedRideType.value = (selectedRideType.value == type) ? '' : type;
    if (selectedRideType.value.isNotEmpty) {
      rideType.value = selectedVehicleName;
      fareController.text = selectedVehicleFare.toString();
      selectedPassengers.value = ridePassengers[type]?.value ?? 1;
      debugPrint('  selectedRideType now: ${selectedRideType.value}, fareController: ${fareController.text}');
    }
  }

  // ======= Determine user city (address or coords) =======
  Future<void> _determineUserCity(dynamic input) async {
    debugPrint('\n===== _determineUserCity START (input=${input.runtimeType}) =====');
    try {
      if (input is String && input.isNotEmpty) {
        debugPrint('  input is String address: $input');
        final addressLower = input.toLowerCase();
        if (addressLower.contains('lahore')) {
          userCityName.value = 'Lahore';
        } else if (addressLower.contains('karachi')) {
          userCityName.value = 'Karachi';
        } else if (addressLower.contains('islamabad')) {
          userCityName.value = 'Islamabad';
        } else if (addressLower.contains('multan')) {
          userCityName.value = 'Multan';
        } else {
          debugPrint('  address fallback -> calling locationFromAddress');
          final locations = await locationFromAddress(input);
          if (locations.isNotEmpty) {
            await _reverseGeocodeCityFromCoords(LatLng(locations.first.latitude, locations.first.longitude));
          } else {
            debugPrint('  locationFromAddress returned empty');
          }
        }
      } else if (input is LatLng) {
        debugPrint('  input is LatLng: $input -> calling reverse geocode');
        await _reverseGeocodeCityFromCoords(input);
      } else {
        debugPrint('  input type not handled: ${input.runtimeType}');
      }

      debugPrint('  final userCityName: ${userCityName.value}');
    } catch (e) {
      debugPrint('  ❌ Error determining user city: $e');
    }
    debugPrint('===== _determineUserCity END =====\n');
  }

  // ======= Reverse geocode helper =======
  Future<void> _reverseGeocodeCityFromCoords(LatLng coords) async {
    debugPrint('===== _reverseGeocodeCityFromCoords START for $coords =====');
    try {
      final placemarks = await placemarkFromCoordinates(coords.latitude, coords.longitude);
      debugPrint('  placemarks length: ${placemarks.length}');
      if (placemarks.isNotEmpty) {
        final city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea;
        final country = placemarks.first.country ?? '';
        userCityName.value = city?.isNotEmpty == true ? city! : 'Unknown';
        debugPrint('  reverse geocoded -> city: ${userCityName.value}, country: $country');
      }
    } catch (e) {
      debugPrint('  ❌ Reverse geocode failed: $e');
    }
    debugPrint('===== _reverseGeocodeCityFromCoords END =====');
  }

  // ======= Vehicle helpers =======
  String _getVehicleImage(String vehicleName) {
    switch (vehicleName.toLowerCase()) {
      case 'bike':
        return 'assets/images/bike.png';
      case 'rickshaw':
        return 'assets/images/tuk.png';
      case 'ride mini':
      case 'ride ac':
      case 'premium':
        return 'assets/images/Accar.png';
      default:
        return 'assets/images/Accar.png';
    }
  }

  String _getVehicleDescription(String vehicleName) {
    switch (vehicleName.toLowerCase()) {
      case 'bike':
        return 'Quickest ride';
      case 'rickshaw':
        return 'Lower fare';
      case 'ride mini':
        return 'Compact car';
      case 'ride ac':
        return 'Cars with AC';
      case 'premium':
        return 'Premium service';
      default:
        return 'Standard ride';
    }
  }

  // ======= Stop processing =======
  void _processStopCoordinates() {
    debugPrint('===== _processStopCoordinates START =====');
    stopCoords.clear();
    for (final stop in stops) {
      if (stop['lat'] != null && stop['lng'] != null) {
        stopCoords.add(LatLng((stop['lat'] as num).toDouble(), (stop['lng'] as num).toDouble()));
      }
    }
    debugPrint('  processed stopCoords count=${stopCoords.length}');
    debugPrint('===== _processStopCoordinates END =====');
  }

  // ======= Marker icons preload =======
  Future<void> _preloadMarkerIcons() async {
    debugPrint('===== _preloadMarkerIcons START =====');
    try {
      await executeWithRetry(() async {
        final pickupData = await _loadAndResizeImage('assets/images/position_marker.png', 90);
        pickupBitmap = BitmapDescriptor.fromBytes(pickupData);

        final dropoffData = await _loadAndResizeImage('assets/images/place.png', 90);
        dropoffBitmap = BitmapDescriptor.fromBytes(dropoffData);

        final stopData = await _loadAndResizeImage('assets/images/place.png', 60);
        stopBitmap = BitmapDescriptor.fromBytes(stopData);

        debugPrint('  custom icons loaded');
      });
    } catch (e) {
      debugPrint('  ❌ Error loading marker icons: $e');
      pickupBitmap = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      dropoffBitmap = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      stopBitmap = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    }
    debugPrint('===== _preloadMarkerIcons END =====');
  }

  Future<Uint8List> _loadAndResizeImage(String assetPath, int size) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: size);
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ======= Route calculation & map updates =======
  Future<void> _calculateRouteAndUpdateMap() async {
    debugPrint('\n===== _calculateRouteAndUpdateMap START =====');
    isCalculatingRoute.value = true;

    try {
      await executeWithRetry(() async {
        if (pickupCoords == null || dropoffCoords == null) {
          debugPrint('  pickup/dropoff coords missing -> _geocodeAddresses');
          await _geocodeAddresses();
        }

        debugPrint('  after geocode pickup=$pickupCoords dropoff=$dropoffCoords');

        if (pickupCoords != null && dropoffCoords != null) {
          await _drawRoute();
          _placeMarkers();
          _fitMarkersInView();
        } else {
          throw Exception('Could not determine coordinates for route calculation');
        }
      }, maxRetries: 2);
    } catch (e) {
      debugPrint('❌ Route calculation failed after retries: $e');
      showError("Unable to calculate route");
    } finally {
      isCalculatingRoute.value = false;
      debugPrint('===== _calculateRouteAndUpdateMap END =====\n');
    }
  }

  Future<void> _geocodeAddresses() async {
    debugPrint('===== _geocodeAddresses START =====');
    try {
      if (pickupCoords == null && pickupLocation.value.isNotEmpty) {
        debugPrint('  geocoding pickup address: ${pickupLocation.value}');
        final pickupLocations = await locationFromAddress(pickupLocation.value);
        if (pickupLocations.isNotEmpty) {
          pickupCoords = LatLng(pickupLocations.first.latitude, pickupLocations.first.longitude);
          debugPrint('  pickupCoords from geocode: $pickupCoords');
        }
      }

      if (dropoffCoords == null && dropoffLocation.value.isNotEmpty) {
        debugPrint('  geocoding dropoff address: ${dropoffLocation.value}');
        final dropoffLocations = await locationFromAddress(dropoffLocation.value);
        if (dropoffLocations.isNotEmpty) {
          dropoffCoords = LatLng(dropoffLocations.first.latitude, dropoffLocations.first.longitude);
          debugPrint('  dropoffCoords from geocode: $dropoffCoords');
        }
      }

      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];
        final address = stop['description']?.toString() ?? '';
        if (address.isNotEmpty && (i >= stopCoords.length)) {
          debugPrint('  geocoding stop [$i] address: $address');
          final locations = await locationFromAddress(address);
          if (locations.isNotEmpty) {
            stopCoords.add(LatLng(locations.first.latitude, locations.first.longitude));
            debugPrint('  stopCoords[$i] = ${stopCoords.last}');
          }
        }
      }
    } catch (e) {
      debugPrint('  ❌ Geocoding error: $e');
    }
    debugPrint('===== _geocodeAddresses END =====');
  }

  Future<void> _drawRoute() async {
    debugPrint('===== _drawRoute START =====');
    if (pickupCoords == null || dropoffCoords == null) {
      debugPrint('  missing coords, returning');
      return;
    }

    if (stopCoords.isNotEmpty) {
      await _drawRouteWithStops();
    } else {
      await _drawRouteWithoutStops();
    }
    debugPrint('===== _drawRoute END =====');
  }

  Future<void> _drawRouteWithStops() async {
    debugPrint('===== _drawRouteWithStops START =====');
    try {
      final List<LatLng> allWaypoints = [pickupCoords!, ...stopCoords, dropoffCoords!];
      double totalDistance = 0.0;
      int totalDuration = 0;

      polylines.clear();

      for (int i = 0; i < allWaypoints.length - 1; i++) {
        final start = allWaypoints[i];
        final end = allWaypoints[i + 1];
        debugPrint('  drawing segment $i from $start to $end');
        final routeInfo = await _getRoutePointsWithDistance(start, end);

        if (routeInfo['points'].isNotEmpty) {
          totalDistance += routeInfo['distance'];
          totalDuration += (routeInfo['duration'] as int);

          polylines.add(Polyline(
            polylineId: PolylineId('route_segment_$i'),
            points: routeInfo['points'],
            color: FColors.secondaryColor,
            width: 5,
          ));

          debugPrint('    segment $i distance=${routeInfo['distance']} duration=${routeInfo['duration']}');
        } else {
          debugPrint('    segment $i returned empty points');
        }
      }

      distanceKm.value = totalDistance;
      durationMinutes.value = totalDuration;

      debugPrint('  total route distance: ${distanceKm.value} km, duration: ${durationMinutes.value} min');

      calculateFaresForAllVehicles();
    } catch (e) {
      debugPrint('  ❌ Error drawing route with stops: $e');
      await _drawRouteWithoutStops();
    }
    debugPrint('===== _drawRouteWithStops END =====');
  }

  Future<void> _drawRouteWithoutStops() async {
    debugPrint('===== _drawRouteWithoutStops START =====');

    try {
      await executeWithRetry(() async {
        final routeInfo = await _getRoutePointsWithDistance(pickupCoords!, dropoffCoords!);

        polylines.clear();
        if (routeInfo['points'].isNotEmpty) {
          polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            points: routeInfo['points'],
            color: FColors.secondaryColor,
            width: 5,
          ));

          distanceKm.value = routeInfo['distance'];
          durationMinutes.value = routeInfo['duration'];

          debugPrint('  route distance: ${distanceKm.value} km, duration: ${durationMinutes.value} min');

          calculateFaresForAllVehicles();
        } else {
          throw Exception('Could not calculate route');
        }
      }, maxRetries: 2);
    } catch (e) {
      debugPrint('  ❌ Could not calculate route');
      showError("Unable to calculate route");
    }

    debugPrint('===== _drawRouteWithoutStops END =====');
  }

  Future<Map<String, dynamic>> _getRoutePointsWithDistance(LatLng pickup, LatLng dropoff) async {
    debugPrint('===== _getRoutePointsWithDistance START from $pickup to $dropoff =====');
    const apiKey = "AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4";

    final url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${pickup.latitude},${pickup.longitude}&"
        "destination=${dropoff.latitude},${dropoff.longitude}&"
        "mode=driving&key=$apiKey";

    try {
      debugPrint('  calling Directions API: $url');
      final response = await http.get(Uri.parse(url));
      debugPrint('  Directions API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('  Directions API response status field: ${data['status']}');
        if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          String encoded = route['overview_polyline']['points'];
          final points = _decodePolyline(encoded);

          final distance = (leg['distance']['value'] as num).toDouble() / 1000;
          final duration = (leg['duration']['value'] as num).toDouble() / 60;

          debugPrint('  route leg distance(km): $distance, duration(min): ${duration.round()}');

          return {
            'points': points,
            'distance': distance,
            'duration': duration.round(),
          };
        }
      }
    } catch (e) {
      debugPrint("  ❌ Error getting route with distance: $e");
    }

    debugPrint('===== _getRoutePointsWithDistance END -> empty =====');
    return {'points': [], 'distance': 0.0, 'duration': 0};
  }

  void _placeMarkers() {
    debugPrint('===== _placeMarkers START =====');
    markers.clear();

    if (pickupCoords != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: pickupCoords!,
        icon: pickupBitmap!,
        infoWindow: InfoWindow(title: pickupLocation.value),
      ));
      debugPrint('  placed pickup marker at $pickupCoords');
    }

    for (int i = 0; i < stopCoords.length; i++) {
      markers.add(Marker(
        markerId: MarkerId('stop_$i'),
        position: stopCoords[i],
        icon: stopBitmap!,
        infoWindow: InfoWindow(title: "Stop ${i + 1}"),
      ));
      debugPrint('  placed stop marker $i at ${stopCoords[i]}');
    }

    if (dropoffCoords != null) {
      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: dropoffCoords!,
        icon: dropoffBitmap!,
        infoWindow: InfoWindow(title: dropoffLocation.value),
      ));
      debugPrint('  placed dropoff marker at $dropoffCoords');
    }

    debugPrint('===== _placeMarkers END, total markers=${markers.length} =====');
  }

  void _fitMarkersInView() {
    debugPrint('===== _fitMarkersInView START =====');
    if (markers.isEmpty || mapController == null) {
      debugPrint('  no markers or map not ready');
      return;
    }

    final bounds = _calculateBounds();
    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
    debugPrint('  animated camera to bounds: $bounds');
    debugPrint('===== _fitMarkersInView END =====');
  }

  LatLngBounds _calculateBounds() {
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    return LatLngBounds(southwest: LatLng(minLat - 0.01, minLng - 0.01), northeast: LatLng(maxLat + 0.01, maxLng + 0.01));
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  void onMapCreated(GoogleMapController controller) {
    debugPrint('onMapCreated called');
    mapController = controller;
    mapReady.value = true;
    Future.delayed(Duration(milliseconds: 500), () {
      _fitMarkersInView();
    });
  }

  // ======= Passenger & Fare helpers =======
  void incrementPassengers(String rideId) {
    final ride = rideOptions.firstWhere((r) => r.id == rideId);
    if (ridePassengers[rideId]!.value < ride.maxPassengers) {
      ridePassengers[rideId]!.value++;
      selectedPassengers.value = ridePassengers[rideId]!.value;
      debugPrint('incrementPassengers: $rideId -> ${ridePassengers[rideId]!.value}');
    }
  }

  void decrementPassengers(String rideId) {
    final ride = rideOptions.firstWhere((r) => r.id == rideId);
    if (ridePassengers[rideId]!.value > ride.minPassengers) {
      ridePassengers[rideId]!.value--;
      selectedPassengers.value = ridePassengers[rideId]!.value;
      debugPrint('decrementPassengers: $rideId -> ${ridePassengers[rideId]!.value}');
    }
  }

  void incrementFare(String rideId) {
    final currentFare = rideFare[rideId]!.value;
    rideFare[rideId]!.value = currentFare + 5;
    debugPrint('incrementFare: $rideId -> ${rideFare[rideId]!.value}');
  }

  void decrementFare(String rideId) {
    final currentFare = rideFare[rideId]!.value;
    final minimumFare = _minimumFares[rideId] ?? 0;

    if (currentFare - 5 >= minimumFare) {
      rideFare[rideId]!.value = currentFare - 5;
      debugPrint('decrementFare: $rideId -> ${rideFare[rideId]!.value}');
    } else {
      showError('You cannot set fare lower than PKR $minimumFare');
    }
  }

  void toggleAutoAccept(bool value) => autoAccept.value = value;

  // ======= Request ride =======
  Future<void> onRequestRide() async {
    debugPrint('\n===== onRequestRide START =====');

    if (pickupLocation.value.isEmpty || dropoffLocation.value.isEmpty) {
      showError('Pickup and Drop-off are required.');
      debugPrint('  Missing pickup/dropoff, aborting');
      return;
    }

    if (pickupCoords == null || dropoffCoords == null) {
      showError('Could not determine coordinates for locations.');
      debugPrint('  Missing coords, aborting');
      return;
    }

    if (!mapReady.value || isCalculatingFare.value) {
      showError('Route and fare are being prepared.');
      debugPrint('  map not ready or fare calculating, aborting');
      return;
    }

    isLoading.value = true;
    isRequestingRide.value = true;

    try {
      await executeWithRetry(() async {
        final requestBody = await _prepareRideRequestBody();
        debugPrint('  prepared request body');
        final token = StorageService.getAuthToken();

        if (token == null) {
          throw Exception("User token not found. Please login again.");
        }

        FHttpHelper.setAuthToken(token, useBearer: true);

        final response = await FHttpHelper.post('ride/request', requestBody);
        debugPrint("  Ride Request API Response : $response");

        if (response['message'] == 'Ride requested successfully.') {
          final rideData = response;
          final rideId = rideData['rideId'];

          await _sendPushNotificationToDrivers(rideData);
          showSuccess('Ride requested successfully!');

          final passengerId = StorageService.getSignUpResponse()!.userId;
          if (passengerId != null) {
            // ✅ UPDATED: Use enhanced pusher manager
            await _pusherManager.subscribeOnce(
              "passenger-$passengerId",
              events: {
                "new-bid": (data) {
                  debugPrint("📨 Passenger received new bid: $data");
                  try {
                    bids.add(data);
                  } catch (e) {
                    debugPrint("❌ Error storing bid: $e");
                  }
                },
                "nearby-drivers": (data) {
                  debugPrint("🗺️ Nearby drivers update: $data");
                },
              },
            );
          }

          Get.toNamed('/available-drivers', arguments: {
            'rideId': rideId,
            'rideData': rideData,
            'pickup': {"lat": pickupCoords?.latitude, "lng": pickupCoords?.longitude, "address": pickupLocation.value},
            'dropoffs': await _getNotification_dropoffs(),
            'rideType': selectedVehicleName,
            'fare': fareController.text,
            'passengers': selectedPassengers.value,
            'payment': selectedPaymentLabel.value,
            'pickupLat': pickupCoords?.latitude,
            'pickupLng': pickupCoords?.longitude,
            'bids': bids,
          });
        } else {
          throw Exception(response['message'] ?? 'Failed to request ride');
        }
      }, maxRetries: 2);
    } catch (e) {
      showError('Failed to request ride: ${e.toString()}');
      debugPrint('  onRequestRide error: $e');
    } finally {
      isLoading.value = false;
      isRequestingRide.value = false;
      debugPrint('===== onRequestRide END =====\n');
    }
  }

  Future<Map<String, dynamic>> _prepareRideRequestBody() async {
    debugPrint('===== _prepareRideRequestBody START =====');
    final dropoffs = await _getStopCoordinates();
    debugPrint('  dropoffs prepared: ${dropoffs.length}');

    final fareBreakdown = _calculateFareBreakdown();
    debugPrint('  fareBreakdown: $fareBreakdown');

    double requestedRideFare;
    try {
      requestedRideFare = double.parse(fareController.text.trim());
    } catch (e) {
      debugPrint('  ❌ Error parsing fare: ${fareController.text}');
      requestedRideFare = selectedVehicleFare.toDouble();
      fareController.text = requestedRideFare.toString();
    }

    if (requestedRideFare <= 0) {
      requestedRideFare = selectedVehicleFare.toDouble();
      fareController.text = requestedRideFare.toString();
    }

    final requestBody = {
      "pickup_lat": pickupCoords!.latitude,
      "pickup_lng": pickupCoords!.longitude,
      "ride_city": userCity,
      "dropoffs": dropoffs,
      "distance": distanceKm.value,
      "vehicle_type": selectedVehicleName,
      "requested_rideFare": requestedRideFare,
      "fare": fareBreakdown,
      "payment_type": selectedPaymentBackendValue,
      "passengers_no": selectedPassengers.value,
      "request_datetime": selectedDate.value != null && selectedTime.value != null
          ? _formatDateTime(selectedDate.value!, selectedTime.value!)
          : DateTime.now().toIso8601String(),
    };

    debugPrint('  Full Request Body:');
    _printFormattedJson(requestBody);
    debugPrint('===== _prepareRideRequestBody END =====');
    return requestBody;
  }

  void _printFormattedJson(Map<String, dynamic> json) {
    final encoder = JsonEncoder.withIndent('  ');
    final formattedJson = encoder.convert(json);
    debugPrint(formattedJson);
  }

  Future<void> _sendPushNotificationToDrivers(Map<String, dynamic> rideData) async {
    debugPrint('===== _sendPushNotificationToDrivers START =====');
    try {
      final notificationBody = {
        "rideId": rideData['rideId'],
        "pickup": {"lat": pickupCoords!.latitude, "lng": pickupCoords!.longitude, "address": pickupLocation.value},
        "dropoffs": await _getNotification_dropoffs(),
        "amount": double.parse(fareController.text),
        "vehicle_type": selectedVehicleName,
      };

      final response = await FHttpHelper.post('ride/push-notification', notificationBody);
      debugPrint('  Push notification response: $response');
    } catch (e) {
      debugPrint('  ❌ Error sending push notification: $e');
    }
    debugPrint('===== _sendPushNotificationToDrivers END =====');
  }

  void openPaymentMethods() {
    PaymentBottomSheet.show();
  }

  void setPaymentMethod(String method) {
    final paymentMap = {"Cash Payment": "cash", "Easypaisa": "easypaisa", "JazzCash": "jazzcash", "Debit/Credit Card": "card", "DoorCabs Wallet": "cash"};
    selectedPaymentLabel.value = method;
    debugPrint('Payment selected: $method -> ${paymentMap[method]}');
  }

  String get selectedPaymentBackendValue {
    final paymentMap = {"Cash Payment": "cash", "Easypaisa": "easypaisa", "JazzCash": "jazzcash", "Debit/Credit Card": "card", "DoorCabs Wallet": "cash"};
    return paymentMap[selectedPaymentLabel.value] ?? "cash";
  }

  void openComments() {
    CommentsBottomSheet.show();
  }

  void setComment(String newComment) {
    comment.value = newComment;
    debugPrint('Comment saved: ${newComment.isNotEmpty ? newComment : "No comment"}');
  }

  void clearComment() {
    comment.value = '';
  }

  bool get hasComment => comment.value.isNotEmpty;

  String get commentPreview {
    if (comment.value.isEmpty) return 'Add comment';
    if (comment.value.length <= 20) return comment.value;
    return '${comment.value.substring(0, 20)}...';
  }

  String get autoAcceptFareDisplay {
    if (selectedRideType.value.isEmpty) {
      return "00";
    }
    return selectedVehicleFare.toString();
  }

  @override
  void onClose() {
    debugPrint('onClose called - disposing map controller');
    mapController?.dispose();
    super.onClose();
  }
}