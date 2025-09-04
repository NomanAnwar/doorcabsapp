import 'package:get/get.dart';
import '../../../shared/services/storage_service.dart';

class ProfileCompletionController extends GetxController {
  // Track each step
  var basicInfoDone = false.obs;
  var cnicDone = false.obs;
  var selfieDone = false.obs;
  var driverLicenceDone = false.obs;
  var vehicleInfoDone = false.obs;
  var referralDone = false.obs;

  // Privacy policy
  var acceptedPolicy = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load saved state
    basicInfoDone.value = StorageService.getDriverStep("basic");
    cnicDone.value = StorageService.getDriverStep("cnic");
    selfieDone.value = StorageService.getDriverStep("selfie");
    driverLicenceDone.value = StorageService.getDriverStep("licence");
    vehicleInfoDone.value = StorageService.getDriverStep("vehicle");
    referralDone.value = StorageService.getDriverStep("referral");
    acceptedPolicy.value = StorageService.getDriverStep("policy");
  }

  // Computed property → all steps done?
  bool get allStepsCompleted =>
      basicInfoDone.value &&
          cnicDone.value &&
          selfieDone.value &&
          driverLicenceDone.value &&
          vehicleInfoDone.value &&
          referralDone.value &&
          acceptedPolicy.value;

  // Mark a step as completed
  void completeStep(String step) {
    switch (step) {
      case "basic":
        basicInfoDone.value = true;
        break;
      case "cnic":
        cnicDone.value = true;
        break;
      case "selfie":
        selfieDone.value = true;
        break;
      case "licence":
        driverLicenceDone.value = true;
        break;
      case "vehicle":
        vehicleInfoDone.value = true;
        break;
      case "referral":
        referralDone.value = true;
        break;
      case "policy":
        acceptedPolicy.value = true;
        break;
    }
    StorageService.setDriverStep(step, true); // persist
  }
}
