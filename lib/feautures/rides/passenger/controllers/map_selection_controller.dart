import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../shared/controllers/base_controller.dart';
import '../../../shared/models/place_suggestion.dart';
import '../../../shared/services/places_service.dart';

class MapSelectionController extends BaseController {
  MapSelectionController(this.apiKey);
  final String apiKey;

  late final PlacesService places;

  final mapCtrl = Completer<GoogleMapController>();
  final center = const LatLng(0, 0).obs;
  final selectedPlace = Rxn<PlaceSuggestion>();
  final isLoadingLocation = false.obs;
  final isTyping = false.obs;
  final showSuggestions = false.obs;

  final suggestions = <PlaceSuggestion>[].obs;
  final queryCtrl = TextEditingController();
  final queryFocus = FocusNode();

  BitmapDescriptor? markerIcon;
  Timer? _debounce;

  final activeField = 'dropoff'.obs;

  bool _isProgrammaticChange = false;

  @override
  void onInit() {
    super.onInit();
    places = PlacesService(apiKey);

    final args = Get.arguments as Map?;
    activeField.value = args?['activeField'] ?? 'dropoff';
    _loadMarkerIcon();
    _initUserLocation();

    queryCtrl.addListener(_onQueryChanged);

    // ✅ Auto-select entire text when focus gained
    queryFocus.addListener(() {
      if (queryFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 60), () {
          queryCtrl.selection = TextSelection(
            baseOffset: 0,
            extentOffset: queryCtrl.text.length,
          );
        });
      }
    });
  }

  @override
  void onClose() {
    queryCtrl.dispose();
    queryFocus.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> _loadMarkerIcon() async {
    try {
      final data = await rootBundle.load('assets/images/position_marker2.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 130);
      final fi = await codec.getNextFrame();
      final bytes = (await fi.image.toByteData(format: ui.ImageByteFormat.png))!;
      markerIcon = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
    } catch (e) {
      markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<void> _initUserLocation() async {
    try {
      isLoadingLocation(true);
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      LatLng targetLatLng;
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
        targetLatLng = LatLng(pos.latitude, pos.longitude);
      } else {
        targetLatLng = const LatLng(24.8607, 67.0011); // Karachi default
      }

      center.value = targetLatLng;

      if (mapCtrl.isCompleted) {
        final controller = await mapCtrl.future;
        await controller.animateCamera(CameraUpdate.newLatLngZoom(targetLatLng, 15));
      }
    } catch (_) {
      center.value = const LatLng(24.8607, 67.0011);
    } finally {
      isLoadingLocation(false);
    }
  }

  void onMapCreated(GoogleMapController c) {
    if (!mapCtrl.isCompleted) mapCtrl.complete(c);
  }

  void onCameraMove(CameraPosition pos) {
    center.value = pos.target;
  }

  void _onQueryChanged() {
    if (!queryFocus.hasFocus || _isProgrammaticChange) return; // 👈 skip if programmatic change

    final text = queryCtrl.text.trim();
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (text.isEmpty) {
        suggestions.clear();
        showSuggestions.value = false;
        return;
      }

      isTyping(true);
      suggestions.assignAll(await places.autocomplete(text));
      showSuggestions.value = true;
      isTyping(false);
    });
  }

  // 🔹 Select a suggestion
  Future<void> selectSuggestion(PlaceSuggestion suggestion) async {
    showSuggestions.value = false;
    suggestions.clear();
    isTyping(false);
    queryFocus.unfocus();

    // 🚫 prevent listener trigger
    _isProgrammaticChange = true;
    queryCtrl.text = suggestion.description;
    await Future.delayed(const Duration(milliseconds: 100));
    _isProgrammaticChange = false;

    final detailed = await places.placeDetails(suggestion);
    if (detailed?.latLng != null) {
      selectedPlace.value = detailed;
      center.value = detailed!.latLng!;
      final controller = await mapCtrl.future;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(detailed.latLng!, 17));
    }
  }


  bool get canConfirm => selectedPlace.value != null;

  Future<void> confirm() async {
    if (!canConfirm) return;
    final p = selectedPlace.value!;
    Get.back(result: {
      'field': activeField.value,
      'lat': p.latLng!.latitude,
      'lng': p.latLng!.longitude,
      'address': p.description,
    });
  }

  Future<void> recenter() async {
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    final latLng = LatLng(pos.latitude, pos.longitude);
    center.value = latLng;
    final controller = await mapCtrl.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
  }
}
