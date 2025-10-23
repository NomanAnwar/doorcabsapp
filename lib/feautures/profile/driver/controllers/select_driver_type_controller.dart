// lib/features/rides/controllers/select_driver_type_controller.dart
import 'package:get/get.dart';

import '../../../shared/services/storage_service.dart';

class SelectDriverTypeController extends GetxController {
  final selectedDriverType = RxString('');
  // call when role selected
  void selectRole(String v) {
    selectedDriverType.value = v;
    StorageService.saveDriverType(v);
  }
}
