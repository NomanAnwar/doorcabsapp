import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/select_vehicle_type_controller.dart';

class SelectVehicleTypeScreen extends StatelessWidget {
  const SelectVehicleTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final role = args['role'] ?? 'driver';
    final c = Get.put(SelectVehicleTypeController());

    /// ---- Responsive setup (same as OtpScreen) ----
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    /// ---- Vehicle tile builder ----
    Widget _vehicleTile({
      required String keyName,
      required String svgAssetPath,
      required String label,
      required double top,
      required double left,
      required double width,
      required double height,
      required VoidCallback onTap,
    }) {
      return Positioned(
        top: sh(top),
        left: sw(left),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: sw(width),
            height: sh(height),
            padding: EdgeInsets.symmetric(horizontal: sw(12)),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(sw(12)),
            ),
            child: Stack(
              children: [
                // SVG icon
                Positioned(
                  left: sw(8),
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: sw(40),
                    height: sh(40),
                    child: Center(
                      child: SvgPicture.asset(
                        svgAssetPath,
                        width: sw(26),
                        height: sh(26),
                      ),
                    ),
                  ),
                ),

                // Label text
                Positioned(
                  left: sw(56),
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      label,
                      style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                        fontSize:
                        FTextTheme.lightTextTheme.bodyLarge!.fontSize! *
                            screenWidth /
                            baseWidth,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Radio button
                Positioned(
                  right: sw(12),
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Obx(() {
                      final selected = c.selectedVehicleType.value == keyName;
                      return Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: sw(22),
                        color: selected ? Colors.black : Colors.black54,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    /// ---- Main UI ----
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// ---- Top AppBar ----
          Positioned(
            top: sh(48),
            left: sw(29),
            right: sw(29),
            child: SizedBox(
              height: sh(60),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: sh(12),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: FColors.black,),
                      iconSize: sw(28),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(top: sh(12.0)),
                      child: Text(
                        "Vehicle",
                        style: FTextTheme.lightTextTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize:
                          FTextTheme.lightTextTheme.titleLarge!.fontSize! *
                              screenWidth /
                              baseWidth,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ---- "Select your vehicle" text ----
          Positioned(
            top: sh(123),
            left: sw(24),
            child: Text(
              "Select your vehicle",
              style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                fontSize:
                FTextTheme.lightTextTheme.bodyLarge!.fontSize! *
                    screenWidth /
                    baseWidth,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          /// ---- Car tile ----
          _vehicleTile(
            keyName: 'car',
            svgAssetPath: 'assets/images/vehicle_car.svg',
            label: 'Car',
            top: 170,
            left: 20,
            width: 402,
            height: 58,
            onTap: () {
              c.selectVehicle('car');
              Get.toNamed('/profile-completion',
                  arguments: {'vehicle': 'car', 'role': role});
            },
          ),

          /// ---- Bike tile ----
          _vehicleTile(
            keyName: 'bike',
            svgAssetPath: 'assets/images/vehicle_bike.svg',
            label: 'Bike',
            top: 246,
            left: 20,
            width: 402,
            height: 58,
            onTap: () {
              c.selectVehicle('bike');
              Get.toNamed('/profile-completion',
                  arguments: {'vehicle': 'bike', 'role': role});
            },
          ),

          /// ---- Rickshaw tile ----
          _vehicleTile(
            keyName: 'rickshaw',
            svgAssetPath: 'assets/images/vehicle_auto_rickshaw.svg',
            label: 'Rickshaw',
            top: 322,
            left: 20,
            width: 402,
            height: 58,
            onTap: () {
              c.selectVehicle('rickshaw');
              Get.toNamed('/profile-completion',
                  arguments: {'vehicle': 'rickshaw', 'role': role});
            },
          ),
        ],
      ),
    );
  }
}
