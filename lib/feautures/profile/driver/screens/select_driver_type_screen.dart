import 'package:doorcab/feautures/profile/driver/screens/select_vehicle_type_screen.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/select_driver_type_controller.dart';

class SelectDriverTypeScreen extends StatelessWidget {
  const SelectDriverTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SelectDriverTypeController());

    // Responsive scaling setup (same as OtpScreen)
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    // ---- Reusable radio tile ----
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
                // Icon
                Positioned(
                  left: sw(8),
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: sw(40),
                    height: sh(40),
                    child: Center(child: leadingIcon),
                  ),
                ),

                // Title
                Positioned(
                  left: sw(66),
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      title,
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

                // Radio Button
                Positioned(
                  right: sw(12),
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Obx(() {
                      final selected = c.selectedDriverType.value == keyName;
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ---- Top Bar ----
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
                      padding: EdgeInsets.only(top: sh(15.0)),
                      child: Text(
                        "Choose Your Role",
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

          // ---- Description ----
          Positioned(
            top: sh(114),
            left: sw(41),
            child: SizedBox(
              width: sw(358),
              child: Text(
                "Select the role that best fits your current task. This choice will determine the types of jobs you'll be offered.",
                textAlign: TextAlign.center,
                style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                  color: Colors.black87,
                  fontSize:
                  FTextTheme.lightTextTheme.bodyLarge!.fontSize! *
                      screenWidth /
                      baseWidth,
                ),
              ),
            ),
          ),

          // ---- Role Selection Label ----
          Positioned(
            top: sh(237),
            left: sw(89),
            child: SizedBox(
              width: sw(262),
              child: Center(
                child: Text(
                  "Role Selection",
                  textAlign: TextAlign.center,
                  style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize:
                    FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                        screenWidth /
                        baseWidth,
                  ),
                ),
              ),
            ),
          ),

          // ---- Driver Tile ----
          _radioTile(
            keyName: 'driver',
            leadingIcon: SvgPicture.asset(
              'assets/images/driver.svg',
              width: sw(40),
              height: sh(40),
            ),
            title: "Driver",
            top: 295,
            left: 20,
            width: 402,
            height: 58,
            onTap: () {
              c.selectRole('driver');
              Future.microtask(() {
                Get.to(() => const SelectVehicleTypeScreen(),
                    arguments: {'role': 'driver'});
              });
            },
          ),

          // ---- Courier Tile ----
          _radioTile(
            keyName: 'courier',
            leadingIcon: SvgPicture.asset(
              'assets/images/courier.svg',
              width: sw(40),
              height: sh(40),
            ),
            title: "Courier",
            top: 385,
            left: 20,
            width: 402,
            height: 58,
            onTap: () {
              c.selectRole('courier');
              Future.microtask(() {
                Get.to(() => const SelectVehicleTypeScreen(),
                    arguments: {'role': 'courier'});
              });
            },
          ),
        ],
      ),
    );
  }
}
