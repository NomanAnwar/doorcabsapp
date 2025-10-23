// lib/features/rides/controllers/select_vehicle_type_controller.dart
import 'package:get/get.dart';

import '../../../shared/services/storage_service.dart';

class SelectVehicleTypeController extends GetxController {
  final selectedVehicleType = RxString('');

  void selectVehicle(String v) {
    selectedVehicleType.value = v;
    StorageService.saveVehicleType(v);
  }
}
