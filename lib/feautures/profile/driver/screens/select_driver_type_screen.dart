import 'package:doorcab/feautures/profile/driver/screens/select_vehicle_type_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../controllers/select_driver_type_controller.dart';

class SelectDriverTypeScreen extends StatelessWidget {
  const SelectDriverTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SelectDriverTypeController());

    // helper builder for radio tile
    Widget _radioTile({
      required String keyName,
      required Widget leadingIcon,
      required String title,
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
              color: const Color(0xFFF2F2F2), // bg color f2f2f2
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // leading icon (placed left inside the tile)
                Positioned(
                  top: (height - 30) / 2, // approximate centering for provided 30px icon height
                  left: 8,
                  child: SizedBox(
                    width: 40,
                    height: 30,
                    child: leadingIcon,
                  ),
                ),
                // title (text)
                Positioned(
                  top: (height / 2) - 10,
                  left: 102 - left, // the design spec says text at 314 from left with container left 20 -> 314-20=294? We approximate using left param to place at requested absolute left by adjusting.
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                // radio at far right
                Positioned(
                  top: (height / 2) - 10,
                  right: 12,
                  child: Obx(() {
                    final selected = c.selectedRole.value == keyName;
                    return Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 22,
                      color: selected ? Colors.black : Colors.black54,
                    );
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
          // row with back arrow and centered title (row from top 48 from left 29)
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
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        "Choose Your Role",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // centered text block width 358 from top 114 and left 41 (text center aligned)
          PositionedScaled(
            top: 114,
            left: 41,
            width: 358,
            child: SizedBox(
              child: Text(
                "Select the role that best fits your current task. This choice will determine the types of jobs you'll be offered.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
              ),
            ),
          ),

          // Role selection label below (width 262 from top 237 left 89)
          PositionedScaled(
            top: 237,
            left: 89,
            width: 262,
            child: const Center(
              child: Text(
                "Role Selection",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // First radio field (driver)
          // container from top 295 left 20 width 402 height 58
          _radioTile(
            keyName: 'driver',
            leadingIcon: const Icon(Icons.directions_car, size: 28),
            title: "Driver",
            top: 295,
            left: 20,
            width: 402,
            height: 58,
            onTap: () {
              c.selectRole('driver');
              // navigate to vehicle selection screen after a tiny delay so radio shows
              Future.microtask(() {
                Get.to(() => const SelectVehicleTypeScreen(), arguments: {'role': 'driver'});
              });
            },
          ),

          // Second radio field (courier) — positioned under the first
          _radioTile(
            keyName: 'courier',
            leadingIcon: const Icon(Icons.local_shipping, size: 28),
            title: "Courier",
            top: 371, // roughly 295 + 58 + some gap -> matches visual stack
            left: 20,
            width: 402,
            height: 58,
            onTap: () {
              c.selectRole('courier');
              // show message then proceed
              Get.snackbar("Notice", "Courier screens are under designing");
              // Future.microtask(() {
              //   Get.to(() => const SelectVehicleTypeScreen(), arguments: {'role': 'courier'});
              // });
            },
          ),
        ],
      ),
    );
  }
}
