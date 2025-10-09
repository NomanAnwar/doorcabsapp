// lib/features/profile_completion/bindings/vehicle_binding.dart
import 'package:get/get.dart';
import '../controllers/upload_vehicle_controller.dart';

class VehicleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UploadVehicleController>(() => UploadVehicleController(), fenix: true);
  }
}
