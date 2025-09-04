// lib/features/rides/screens/select_vehicle_type_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../controllers/select_vehicle_type_controller.dart';

class SelectVehicleTypeScreen extends StatelessWidget {
  const SelectVehicleTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final role = args['role'] ?? 'driver';
    final c = Get.put(SelectVehicleTypeController());

    Widget _vehicleTile({
      required String keyName,
      required IconData icon,
      required String label,
      required double top,
      required double left,
      required double width,
      required double height,
      required VoidCallback onTap,
    }) {
      return PositionedScaled(
        top: top,
        left: left,
        width: width,
        height: height,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: (height - 30) / 2,
                  left: 8,
                  child: SizedBox(
                    width: 40,
                    height: 30,
                    child: Icon(icon, size: 26),
                  ),
                ),
                Positioned(
                  top: (height / 2) - 10,
                  left: 102 - left,
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Positioned(
                  top: (height / 2) - 10,
                  right: 12,
                  child: Obx(() {
                    final sel = c.selectedVehicle.value == keyName;
                    return Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 22, color: sel ? Colors.black : Colors.black54);
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // row with back and title
          PositionedScaled(
            top: 48,
            left: 29,
            right: 29,
            child: SizedBox(
              height: 60,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 12,
                    child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        "Vehicle",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // "Select your vehicle" at top 123 left 24
          PositionedScaled(
            top: 123,
            left: 24,
            child: const Text(
              "Select your vehicle",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          // Car tile (first)
          _vehicleTile(
            keyName: 'car',
            icon: Icons.directions_car,
            label: 'Car',
            top: 170, // some space below the heading
            left: 20,
            width: 402,
            height: 58,
            onTap: () {
              c.selectVehicle('car');
              // navigate to car registration screen -> placeholder
              // Get.snackbar("Selected", "Car selected");
              // Replace Get.back with actual route for car registration
              Get.toNamed('/profile-completion');
            },
          ),

          // Bike tile
          _vehicleTile(
            keyName: 'bike',
            icon: Icons.pedal_bike,
            label: 'Bike',
            top: 246,
            left: 20,
            width: 402,
            height: 58,
            onTap: () {
              c.selectVehicle('bike');
              Get.snackbar("Selected", "Bike selected");
              // Get.toNamed('/bike-registration', arguments: {'role': role});
            },
          ),

          // Rikshaw tile
          _vehicleTile(
            keyName: 'rickshaw',
            icon: Icons.electric_rickshaw,
            label: 'Rickshaw',
            top: 322,
            left: 20,
            width: 402,
            height: 58,
            onTap: () {
              c.selectVehicle('rickshaw');
              Get.snackbar("Selected", "Rickshaw selected");
              // Get.toNamed('/rikshaw-registration', arguments: {'role': role});
            },
          ),
        ],
      ),
    );
  }
}
