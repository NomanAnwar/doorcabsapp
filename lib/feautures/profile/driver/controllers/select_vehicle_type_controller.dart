// lib/features/rides/controllers/select_vehicle_type_controller.dart
import 'package:get/get.dart';

class SelectVehicleTypeController extends GetxController {
  final selectedVehicle = RxString('');

  void selectVehicle(String v) {
    selectedVehicle.value = v;
  }
}
