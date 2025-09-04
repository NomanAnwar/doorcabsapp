
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/models/place_suggestion.dart';
import '../../../shared/services/places_service.dart';
import '../../../shared/services/storage_service.dart';


enum ActiveField { pickup, dropoff }

class DropOffController extends GetxController {
  DropOffController(this.apiKey);

  final String apiKey;
  late final PlacesService places;

  final pickupCtrl = TextEditingController();
  final dropCtrl   = TextEditingController();

  final pickupFocus = FocusNode();
  final dropFocus   = FocusNode();

  final activeField = ActiveField.dropoff.obs;

  final suggestions = <PlaceSuggestion>[].obs;
  final isLoading = false.obs;
  final recent      = <PlaceSuggestion>[].obs;

  final stops = <PlaceSuggestion>[].obs; // max 3

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    places = PlacesService(apiKey);

    final args = Get.arguments as Map?;
    pickupCtrl.text = args?['pickup']  ?? 'Your Current Location';
    dropCtrl.text   = args?['dropoff'] ?? '';

    if (args?['activeField'] == 'pickup') {
      activeField.value = ActiveField.pickup;
      pickupFocus.requestFocus();
    } else {
      activeField.value = ActiveField.dropoff;
      dropFocus.requestFocus();
    }

    recent.assignAll(StorageService.getRecent());

    pickupCtrl.addListener(() => _onQueryChanged(ActiveField.pickup));
    dropCtrl.addListener(() => _onQueryChanged(ActiveField.dropoff));
  }

  void _onQueryChanged(ActiveField field) {
    if ((field == ActiveField.pickup && !pickupFocus.hasFocus) ||
        (field == ActiveField.dropoff && !dropFocus.hasFocus)) {
      return;
    }

    final q = field == ActiveField.pickup ? pickupCtrl.text : dropCtrl.text;

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (q.trim().isEmpty) {
        suggestions.clear();
        return;
      }
      isLoading.value = true;
      suggestions.assignAll(await places.autocomplete(q.trim()));
      isLoading.value = false;
      activeField.value = field;
    });
  }

  Future<void> chooseOnMap() async {
    final result = await Get.toNamed('/map-selection', arguments: {
      'activeField': activeField.value == ActiveField.pickup ? 'pickup' : 'dropoff'
    });

    if (result is Map && result['lat'] != null && result['lng'] != null) {
      final s = PlaceSuggestion(
        placeId: 'map_${DateTime.now().millisecondsSinceEpoch}',
        description: result['address'] ?? 'Selected on map',
        latLng: LatLng(result['lat'], result['lng']),
      );

      if (activeField.value == ActiveField.pickup) {
        pickupCtrl.text = s.description;
      } else {
        dropCtrl.text = s.description;
      }

      StorageService.addRecent(s);
      recent.assignAll(StorageService.getRecent());
      suggestions.clear();
    }
  }

  Future<void> selectSuggestion(PlaceSuggestion s) async {
    isLoading.value = true;
    final withLatLng = await places.placeDetails(s) ?? s;
    isLoading.value = false;

    if (activeField.value == ActiveField.pickup) {
      pickupCtrl.text = withLatLng.description;
      dropFocus.requestFocus();
      activeField.value = ActiveField.dropoff;
    } else {
      dropCtrl.text = withLatLng.description;
    }

    StorageService.addRecent(withLatLng);
    recent.assignAll(StorageService.getRecent());
    suggestions.clear();
  }

  void toggleField(ActiveField field) {
    activeField.value = field;
    if (field == ActiveField.pickup) {
      pickupFocus.requestFocus();
    } else {
      dropFocus.requestFocus();
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
      Obx(() => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Stops", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (stops.isEmpty) const Text("No stops added yet"),
            ...List.generate(stops.length, (i) => ListTile(
              title: Text(stops[i].description),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => stops.removeAt(i),
              ),
            )),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final result = await Get.toNamed('/map-selection', arguments: {'activeField': 'dropoff'});
                if (result is Map && result['lat'] != null) {
                  final s = PlaceSuggestion(
                    placeId: 'stop_${DateTime.now().millisecondsSinceEpoch}',
                    description: result['address'] ?? 'Stop (map)',
                    latLng: LatLng(result['lat'], result['lng']),
                  );
                  if (stops.length < 3) stops.add(s);
                }
              },
              child: const Text("Add stop from map"),
            ),
            const SizedBox(height: 8),
          ],
        ),
      )),
      isScrollControlled: true,
    );
  }

  void confirmSelection() {
    if (pickupCtrl.text.trim().isEmpty || dropCtrl.text.trim().isEmpty) {
      Get.snackbar('Missing fields', 'Pickup and Drop-off are required.');
      return;
    }
    // Get.back(result: {
    //   'pickup': pickupCtrl.text.trim(),
    //   'dropoff': dropCtrl.text.trim(),
    //   'stops': stops.map((e) => e.toJson()).toList(),
    // });
    Get.toNamed('/ride-request', arguments: {
      'pickup': pickupCtrl.text.trim(),
      'dropoff': dropCtrl.text.trim(),
      'stops': stops.map((e) => e.toJson()).toList(),
    });
  }

  @override
  void onClose() {
    _debounce?.cancel();
    pickupCtrl.dispose();
    dropCtrl.dispose();
    pickupFocus.dispose();
    dropFocus.dispose();
    super.onClose();
  }
}
