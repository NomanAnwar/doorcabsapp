// lib/features/rides/controllers/select_driver_type_controller.dart
import 'package:get/get.dart';

class SelectDriverTypeController extends GetxController {
  final selectedRole = RxString('');
  // call when role selected
  void selectRole(String v) {
    selectedRole.value = v;
  }
}
