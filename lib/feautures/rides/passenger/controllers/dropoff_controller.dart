import 'dart:async';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/models/place_suggestion.dart';
import '../../../shared/services/places_service.dart';
import '../../../shared/services/storage_service.dart';
import '../models/location_model.dart';

enum ActiveField { pickup, dropoff }

class DropOffController extends BaseController {
  DropOffController(this.apiKey);

  final String apiKey;
  late final PlacesService places;

  final pickupCtrl = TextEditingController();
  final dropCtrl = TextEditingController();

  final pickupFocus = FocusNode();
  final dropFocus = FocusNode();

  final activeField = ActiveField.dropoff.obs;

  // Track selection states
  final isPickupSelected = false.obs;
  final isDropoffSelected = false.obs;
  final showSuggestions = false.obs;

  final suggestions = <PlaceSuggestion>[].obs;
  final recent = <PlaceSuggestion>[].obs;
  final stops = <PlaceSuggestion>[].obs;

  Timer? _debounce;

  // Store selected places with coordinates
  PlaceSuggestion? lastPickupPlace;
  PlaceSuggestion? lastDropoffPlace;

  // Store passed data from RideTypeScreen
  final Rx<UserLocation?> userLocation = Rx<UserLocation?>(null);
  final RxList<dynamic> vehicles = <dynamic>[].obs;
  final RxList<dynamic> cities = <dynamic>[].obs;
  final Rx<dynamic> service = Rx<dynamic>(null);

  @override
  void onInit() {
    super.onInit();
    places = PlacesService(apiKey);

    final args = Get.arguments as Map?;

    // Store all passed data
    if (args?['userLocation'] is Map) {
      userLocation.value = UserLocation.fromJson(args!['userLocation'] as Map<String, dynamic>);
    }
    if (args?['vehicles'] is List) {
      vehicles.assignAll(args!['vehicles'] as List);
    }
    if (args?['cities'] is List) {
      cities.assignAll(args!['cities'] as List);
    }
    if (args?['service'] != null) {
      service.value = args!['service'];
    }

    // Use user location address from params
    pickupCtrl.text = userLocation.value?.address ??
        args?['userCurrentAddress'] ??
        args?['pickup'] ??
        'Your Current Location';

    // Set pickup as selected since we have user location
    if (args?['pickupLatLng'] != null && args?['pickupLatLng'] is LatLng) {
      lastPickupPlace = PlaceSuggestion(
        placeId: 'arg_pickup_${DateTime.now().millisecondsSinceEpoch}',
        description: pickupCtrl.text,
        latLng: args!['pickupLatLng'],
      );
      isPickupSelected.value = true;
    }
    else if (args?['userCurrentLocation'] != null && args?['userCurrentLocation'] is LatLng) {
      lastPickupPlace = PlaceSuggestion(
        placeId: 'current_location_${DateTime.now().millisecondsSinceEpoch}',
        description: pickupCtrl.text,
        latLng: args!['userCurrentLocation'] as LatLng,
      );
      isPickupSelected.value = true;
    }
    else if (userLocation.value != null) {
      lastPickupPlace = PlaceSuggestion(
        placeId: 'current_location_${DateTime.now().millisecondsSinceEpoch}',
        description: pickupCtrl.text,
        latLng: userLocation.value!.toLatLng(),
      );
      isPickupSelected.value = true;
    }

    dropCtrl.text = args?['dropoff'] ?? '';

    // Focus on dropoff field initially
    activeField.value = ActiveField.dropoff;
    dropFocus.requestFocus();

    // Load recent locations
    recent.assignAll(StorageService.getRecent());

    // Set up text listeners with text change detection
    pickupCtrl.addListener(_onPickupTextChanged);
    dropCtrl.addListener(_onDropoffTextChanged);

    // Set up focus listeners to keep activeField in sync
    pickupFocus.addListener(_onPickupFocusChange);
    dropFocus.addListener(_onDropoffFocusChange);

    // Set up text selection on focus
    pickupFocus.addListener(() => _handleFocusSelection(pickupCtrl, pickupFocus));
    dropFocus.addListener(() => _handleFocusSelection(dropCtrl, dropFocus));

    // Check auto-navigation in case both are already set
    _checkAutoNavigate();
  }

  // NEW: Select all text when field gets focus
  void _handleFocusSelection(TextEditingController controller, FocusNode focusNode) {
    if (focusNode.hasFocus) {
      // Small delay to ensure the field is fully focused
      Future.delayed(const Duration(milliseconds: 50), () {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      });
    }
  }

  void _onPickupTextChanged() {
    _onQueryChanged(ActiveField.pickup);
    _checkFieldEmptied(ActiveField.pickup);
  }

  void _onDropoffTextChanged() {
    _onQueryChanged(ActiveField.dropoff);
    _checkFieldEmptied(ActiveField.dropoff);
  }

  // Sync activeField with actual focus
  void _onPickupFocusChange() {
    if (pickupFocus.hasFocus) {
      activeField.value = ActiveField.pickup;
      // Clear suggestions when focus changes
      suggestions.clear();
      showSuggestions.value = false;
    }
  }

  void _onDropoffFocusChange() {
    if (dropFocus.hasFocus) {
      activeField.value = ActiveField.dropoff;
      // Clear suggestions when focus changes
      suggestions.clear();
      showSuggestions.value = false;
    }
  }

  // Check if user emptied a previously selected field
  void _checkFieldEmptied(ActiveField field) {
    final text = field == ActiveField.pickup ? pickupCtrl.text : dropCtrl.text;
    final wasSelected = field == ActiveField.pickup ? isPickupSelected.value : isDropoffSelected.value;

    if (wasSelected && text.isEmpty) {
      // User emptied a previously selected field
      if (field == ActiveField.pickup) {
        isPickupSelected.value = false;
        lastPickupPlace = null;
      } else {
        isDropoffSelected.value = false;
        lastDropoffPlace = null;
      }
    }
  }

  void _onQueryChanged(ActiveField field) {
    // Only search if the field actually has focus
    final hasCorrectFocus = (field == ActiveField.pickup && pickupFocus.hasFocus) ||
        (field == ActiveField.dropoff && dropFocus.hasFocus);

    if (!hasCorrectFocus) {
      return;
    }

    final query = field == ActiveField.pickup ? pickupCtrl.text : dropCtrl.text;

    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.trim().isEmpty) {
        suggestions.clear();
        showSuggestions.value = false;
        return;
      }

      isLoading.value = true;
      suggestions.assignAll(await places.autocomplete(query.trim()));
      isLoading.value = false;
      // Keep activeField in sync with the field that actually has focus
      activeField.value = pickupFocus.hasFocus ? ActiveField.pickup : ActiveField.dropoff;
      showSuggestions.value = true;
    });
  }

  Future<void> chooseOnMap() async {
    final result = await Get.toNamed(
      '/map-selection',
      arguments: {
        'activeField': activeField.value == ActiveField.pickup ? 'pickup' : 'dropoff',
      },
    );

    if (result is Map && result['lat'] != null && result['lng'] != null) {
      final place = PlaceSuggestion(
        placeId: 'map_${DateTime.now().millisecondsSinceEpoch}',
        description: result['address'] ?? 'Selected on map',
        latLng: LatLng(result['lat'], result['lng']),
      );

      _setFieldValue(place);
    }
  }

  Future<void> selectSuggestion(PlaceSuggestion suggestion) async {
    isLoading.value = true;

    // Use origin from passed params
    LatLng? origin;
    if (lastPickupPlace?.latLng != null) {
      origin = lastPickupPlace!.latLng;
    } else if (userLocation.value != null) {
      origin = userLocation.value!.toLatLng();
    } else if (Get.arguments?['userCurrentLocation'] is LatLng) {
      origin = Get.arguments!['userCurrentLocation'] as LatLng;
    } else if (Get.arguments?['pickupLatLng'] is LatLng) {
      origin = Get.arguments!['pickupLatLng'] as LatLng;
    }

    final detailedPlace = await places.placeDetails(suggestion, origin: origin);
    isLoading.value = false;

    if (detailedPlace != null) {
      _setFieldValue(detailedPlace);
    }

    // Clear suggestions immediately
    suggestions.clear();
    showSuggestions.value = false;
  }

  void selectRecent(PlaceSuggestion suggestion) {
    _setFieldValue(suggestion);
    // Clear suggestions immediately
    suggestions.clear();
    showSuggestions.value = false;
  }

  void _setFieldValue(PlaceSuggestion suggestion) {
    // Determine target field based on CURRENT FOCUS, not activeField
    final hasPickupFocus = pickupFocus.hasFocus;
    final hasDropoffFocus = dropFocus.hasFocus;

    if (hasPickupFocus) {
      // User is actively focused on pickup field
      pickupCtrl.text = suggestion.description;
      lastPickupPlace = suggestion;
      isPickupSelected.value = true;

      // Clear focus and suggestions
      pickupFocus.unfocus();
      suggestions.clear();
      showSuggestions.value = false;

      // Only move to dropoff if it's not already selected
      if (!isDropoffSelected.value) {
        dropFocus.requestFocus();
        activeField.value = ActiveField.dropoff;
      }
    }
    else if (hasDropoffFocus) {
      // User is actively focused on dropoff field
      dropCtrl.text = suggestion.description;
      lastDropoffPlace = suggestion;
      isDropoffSelected.value = true;

      // Clear focus and suggestions
      dropFocus.unfocus();
      suggestions.clear();
      showSuggestions.value = false;
    }
    else {
      // Fallback: use activeField if no focus (shouldn't happen normally)
      if (activeField.value == ActiveField.pickup) {
        pickupCtrl.text = suggestion.description;
        lastPickupPlace = suggestion;
        isPickupSelected.value = true;
      } else {
        dropCtrl.text = suggestion.description;
        lastDropoffPlace = suggestion;
        isDropoffSelected.value = true;
      }

      suggestions.clear();
      showSuggestions.value = false;
    }

    // Store in recent and update list
    StorageService.addRecent(suggestion);
    recent.assignAll(StorageService.getRecent());

    // Check for auto-navigation
    _checkAutoNavigate();
  }

  void toggleField(ActiveField field) {
    activeField.value = field;
    if (field == ActiveField.pickup) {
      pickupFocus.requestFocus();
    } else {
      dropFocus.requestFocus();
    }
    // Clear suggestions when switching fields
    suggestions.clear();
    showSuggestions.value = false;
  }

  void _checkAutoNavigate() {
    if (isPickupSelected.value && isDropoffSelected.value) {
      // Small delay to ensure UI updates complete
      Future.delayed(const Duration(milliseconds: 300), () {
        _navigateToNextScreen();
      });
    }
  }

  void addStop() {
    if (stops.length >= 3) {
      Get.snackbar('Limit reached', 'You can add up to 3 stops only.');
      return;
    }
    _openStopsManager();
  }

  void _openStopsManager() {
    Get.bottomSheet(
      Obx(
            () => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                "Manage Stops",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (stops.isEmpty)
                const Text("No stops added yet",
                    style: TextStyle(color: Colors.grey)),
              ...List.generate(
                stops.length,
                    (i) => Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.place, color: FColors.secondaryColor),
                    title: Text(stops[i].description, style: FTextTheme
                        .lightTextTheme
                        .titleMedium),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: FColors.primaryColor),
                      onPressed: () => stops.removeAt(i),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Get.toNamed(
                    '/map-selection',
                    arguments: {'activeField': 'dropoff'},
                  );
                  if (result is Map && result['lat'] != null) {
                    final stop = PlaceSuggestion(
                      placeId: 'stop_${DateTime.now().millisecondsSinceEpoch}',
                      description: result['address'] ?? 'Stop (map)',
                      latLng: LatLng(result['lat'], result['lng']),
                    );
                    if (stops.length < 3) stops.add(stop);
                  }
                },
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text("Add stop from map"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FColors.secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void confirmSelection() {
    // This is now only used for manual confirmation
    if (!isPickupSelected.value || !isDropoffSelected.value) {
      showError('Please select both pickup and drop-off locations from suggestions.');
      return;
    }
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    // Clear any focus and hide suggestions
    pickupFocus.unfocus();
    dropFocus.unfocus();
    suggestions.clear();
    showSuggestions.value = false;

    // Build payload with ALL data
    final payload = {
      'pickup': pickupCtrl.text.trim(),
      'dropoff': dropCtrl.text.trim(),
      'stops': stops.map((e) => e.toJson()).toList(),
      'vehicles': vehicles.toList(),
      'cities': cities.toList(),
      'service': service.value,
      'userLocation': userLocation.value?.toJson(),
      'userCurrentAddress': userLocation.value?.address,
    };

    // Include coordinates if available
    if (lastPickupPlace?.latLng != null) {
      payload['pickupLat'] = lastPickupPlace!.latLng!.latitude;
      payload['pickupLng'] = lastPickupPlace!.latLng!.longitude;
    }
    if (lastDropoffPlace?.latLng != null) {
      payload['dropoffLat'] = lastDropoffPlace!.latLng!.latitude;
      payload['dropoffLng'] = lastDropoffPlace!.latLng!.longitude;
    }

    // Also include user location coordinates
    if (userLocation.value != null) {
      payload['userCurrentLocation'] = userLocation.value!.toLatLng();
    }

    Get.toNamed(
      '/ride-booking',
      arguments: payload,
    );
  }

  @override
  void onClose() {
    _debounce?.cancel();
    pickupCtrl.dispose();
    dropCtrl.dispose();
    pickupFocus.removeListener(_onPickupFocusChange);
    dropFocus.removeListener(_onDropoffFocusChange);
    pickupFocus.dispose();
    dropFocus.dispose();
    // Clear suggestions when screen closes
    suggestions.clear();
    showSuggestions.value = false;
    super.onClose();
  }
}