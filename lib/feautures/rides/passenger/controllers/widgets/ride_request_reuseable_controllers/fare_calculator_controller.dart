import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/city_model.dart';
import '../../../models/ride_type_model.dart';
import '../../../models/vehicle_model.dart';
import '../../../screens/reusable_widgets/fare_calculator.dart';
import '../../ride_request_controller.dart';
import '../comments_sheet.dart';
import '../payment_methods_sheet.dart';


class FareCalculatorController extends GetxController {
  final fareController = TextEditingController(text: "250");
  final userCity = RxString('');
  final vehicleFares = <String, double>{}.obs;
  final selectedPassengers = "1".obs;
  final autoAccept = false.obs;
  final selectedPaymentLabel = "Cash".obs;

  final List<String> passengerOptions = const ["1", "2", "3", "4", "More"];
  final FareCalculator _fareCalculator = FareCalculator();

  @override
  void onClose() {
    fareController.dispose();
    super.onClose();
  }

  void initializeFromArgs(Map<String, dynamic> args) {
    // Can be extended if needed
  }

  void initializeVehicleSelection(
      Map<String, dynamic>? selectedVehicleData,
      int selectedRideIndexFromHome,
      List<RideTypeModel> rideTypes,
      List<VehicleModel> vehicleModels,
      List<CityModel> cities,
      VehicleModel? Function(int) vehicleForRideTypeIndex
      ) {
    if (selectedVehicleData != null) {
      final vid = selectedVehicleData['id']?.toString() ?? '';
      if (vid.isNotEmpty) {
        final idx = vehicleModels.indexWhere((v) => v.id == vid);
        if (idx >= 0) {
          Get.find<RideRequestController>().selectedRideIndex.value = idx;
          Get.find<RideRequestController>().selectedVehicle.value = vehicleModels[idx];
        }
      }
    } else if (selectedRideIndexFromHome < rideTypes.length) {
      Get.find<RideRequestController>().selectedRideIndex.value = selectedRideIndexFromHome;
      final v = vehicleForRideTypeIndex(selectedRideIndexFromHome);
      if (v != null) Get.find<RideRequestController>().selectedVehicle.value = v;
    } else if (Get.find<RideRequestController>().selectedVehicle.value == null && vehicleModels.isNotEmpty) {
      Get.find<RideRequestController>().selectedVehicle.value = vehicleModels.first;
    }

    if (cities.isNotEmpty) {
      userCity.value = cities.first.cityName;
    }
  }

  void calculateAllFares(
      double distanceKm,
      int durationMinutes,
      List<CityModel> cities,
      List<VehicleModel> vehicleModels,
      String userCityValue
      ) {
    if (cities.isEmpty || vehicleModels.isEmpty) return;

    final city = _findCity(cities, userCityValue);
    if (city == null) return;

    vehicleFares.clear();
    for (final v in vehicleModels) {
      final fare = _fareCalculator.calculateFare(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        city: city,
        vehicle: v,
      );
      vehicleFares[v.id] = fare;
    }

    _updateFareController(vehicleModels);
  }

  CityModel? _findCity(List<CityModel> cities, String userCityValue) {
    if (userCityValue.isNotEmpty) {
      try {
        return cities.firstWhere((c) => c.cityName.toLowerCase() == userCityValue.toLowerCase());
      } catch (e) {
        return cities.first;
      }
    }
    return cities.first;
  }

  void _updateFareController(List<VehicleModel> vehicleModels) {
    final controller = Get.find<RideRequestController>();
    final sel = controller.selectedVehicle.value ??
        (vehicleModels.isNotEmpty ? vehicleModels[controller.selectedRideIndex.value.clamp(0, vehicleModels.length - 1)] : null);

    if (sel != null && vehicleFares.containsKey(sel.id)) {
      fareController.text = vehicleFares[sel.id]!.toStringAsFixed(0);
    } else if (vehicleFares.isNotEmpty) {
      fareController.text = vehicleFares.values.first.toStringAsFixed(0);
    }
  }

  VehicleModel? vehicleForRideTypeIndex(int index, List<RideTypeModel> rideTypes, List<VehicleModel> vehicleModels) {
    if (index >= 0 && index < vehicleModels.length) return vehicleModels[index];

    if (index >= 0 && index < rideTypes.length) {
      final rt = rideTypes[index];
      final match = vehicleModels.firstWhereOrNull((v) => v.name.toLowerCase() == rt.title.toLowerCase());
      if (match != null) return match;
    }

    return vehicleModels.isNotEmpty ? vehicleModels.first : null;
  }

  void updateSelectedRide(int index, List<RideTypeModel> rideTypes, List<VehicleModel> vehicleModels, VehicleModel? Function(int) vehicleForRideTypeIndex) {
    final v = vehicleForRideTypeIndex(index);
    if (v != null) {
      Get.find<RideRequestController>().selectedVehicle.value = v;
      if (vehicleFares.containsKey(v.id)) {
        fareController.text = vehicleFares[v.id]!.toStringAsFixed(0);
      } else {
        calculateAllFares(
            Get.find<RideRequestController>().distanceKm.value,
            Get.find<RideRequestController>().durationMinutes.value,
            Get.find<RideRequestController>().cities,
            vehicleModels,
            userCity.value
        );
        if (vehicleFares.containsKey(v.id)) {
          fareController.text = vehicleFares[v.id]!.toStringAsFixed(0);
        }
      }
    }
  }

  String fareForCard(
      int i,
      int selectedRideIndex,
      double distanceKm,
      int durationMinutes,
      List<CityModel> cities,
      List<RideTypeModel> rideTypes,
      List<VehicleModel> vehicleModels,
      VehicleModel? Function(int) vehicleForRideTypeIndex
      ) {
    if (selectedRideIndex == i) {
      return "PKR ${fareController.text}";
    }

    final v = vehicleForRideTypeIndex(i);
    if (v != null) {
      final fare = vehicleFares[v.id];
      if (fare != null) return "PKR ${fare.toStringAsFixed(0)}";

      if (distanceKm > 0 && cities.isNotEmpty) {
        final city = cities.first;
        final calc = _fareCalculator.calculateFare(
          distanceKm: distanceKm,
          durationMinutes: durationMinutes,
          city: city,
          vehicle: v,
        );
        return "PKR ${calc.toStringAsFixed(0)}";
      }
    }

    return "PKR --";
  }

  void incrementFare() {
    final v = int.tryParse(fareController.text) ?? 0;
    fareController.text = (v + 5).toString();
  }

  void decrementFare() {
    final v = int.tryParse(fareController.text) ?? 0;
    if (v > 0) fareController.text = (v - 5).toString();
  }

  void openPaymentMethods() {
    PaymentBottomSheet.show();
  }

  void openComments() {
    CommentsBottomSheet.show();
  }
}