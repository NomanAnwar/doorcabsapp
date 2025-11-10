import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangeCityController extends GetxController {
  var currentCity = "Islamabad".obs;
  var selectedCity = "".obs;

  final availableCities = [
    "Islamabad",
    "Lahore",
    "Karachi",
    "Rawalpindi",
    "Faisalabad",
    "Multan",
    "Peshawar",
    "Quetta",
    "Sialkot",
    "Hyderabad",
    "Bahawalpur",
    "Gujranwala",
    "Sukkur",
    "Mirpur",
    "Abbottabad",
  ];

  void saveCity() {
    final newCity = selectedCity.value;

    if (newCity.isEmpty) {
      _showSnackbar("Error", "Please select a city.", Colors.redAccent);
    } else {
      currentCity.value = newCity;
      _showSnackbar("Success", "City changed to $newCity.", Colors.green);
    }
  }

  void _showSnackbar(String title, String message, Color color) {
    Get.closeAllSnackbars();
    final overlayContext = Get.overlayContext ?? Get.context;
    if (overlayContext != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: color,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 8,
        isDismissible: true,
      );
    }
  }
}
