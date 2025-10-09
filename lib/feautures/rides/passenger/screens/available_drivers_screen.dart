import 'package:doorcab/common/widgets/buttons/f_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/available_drivers_controller.dart';

class AvailableDriversScreen extends StatelessWidget {
  const AvailableDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AvailableDriversController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              /// Map full screen
              Positioned.fill(
                child: Obx(() {
                  if (c.currentPosition.value == null) {
                    return Center(child: CircularProgressIndicator(strokeWidth: sw(2)));
                  }
                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: c.currentPosition.value!,
                      zoom: 13,
                    ),
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    onMapCreated: c.onMapCreated,
                    markers: c.driverMarkers.values.toSet(),
                  );
                }),
              ),

              /// Back button
              Positioned(
                top: sh(44),
                left: sw(26),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, size: sw(24)),
                  onPressed: Get.back,
                ),
              ),

              /// Bottom container
              Positioned(
                top: sh(672),
                left: 0,
                right: 0,
                child: Container(
                  height: sh(284),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(sw(14))),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: sw(6),
                          offset: const Offset(0, -2)
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      /// "x drivers viewing" text
                      Positioned(
                        top: sh(20),
                        left: sw(18),
                        child: SizedBox(
                          width: sw(180),
                          child: Obx(() => Text(
                            "${c.viewingDrivers.value} drivers are viewing your request",
                            style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              fontSize: sw(14),
                            ),
                          )),
                        ),
                      ),

                      /// Driver avatars row (max 6)
                      Positioned(
                        top: sh(17),
                        left: sw(274),
                        width: sw(128),
                        height: sh(24),
                        child: Obx(() => ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: c.driverAvatars.take(6).length,
                          separatorBuilder: (_, __) => SizedBox(width: sw(4)),
                          itemBuilder: (_, index) {
                            final avatar = c.driverAvatars[index];
                            return CircleAvatar(
                              radius: sw(12),
                              backgroundImage: AssetImage(avatar),
                            );
                          },
                        )),
                      ),

                      /// Grey sub-container
                      Positioned(
                        top: sh(51),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: sh(196),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3E3E3),
                            borderRadius: BorderRadius.circular(sw(14)),
                          ),
                          child: Stack(
                            children: [
                              /// "Waiting for drivers..." text
                              Positioned(
                                top: sh(5),
                                left: sw(22),
                                child: Text(
                                  "Waiting for drivers to bid...",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: sw(16),
                                  ),
                                ),
                              ),

                              /// Countdown timer
                              Positioned(
                                top: sh(25),
                                right: sw(22),
                                child: Obx(() => Text(
                                  "${c.remainingSeconds.value}s",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: sw(16),
                                  ),
                                )),
                              ),

                              /// Progress bar
                              Positioned(
                                top: sh(50),
                                left: sw(18),
                                right: sw(18),
                                child: Obx(() => LinearProgressIndicator(
                                  value: c.remainingSeconds.value / 60,
                                  backgroundColor: Colors.white,
                                  color: FColors.primaryColor,
                                )),
                              ),

                              /// -5 button
                              Positioned(
                                top: sh(75),
                                left: sw(38),
                                child: IconButton(
                                  icon: Image.asset(
                                    "assets/images/minus5.png",
                                    width: sw(40),
                                    height: sh(40),
                                  ),
                                  onPressed: () => c.adjustFare(-5),
                                ),
                              ),

                              /// Fare field
                              Positioned(
                                top: sh(82),
                                left: sw(126),
                                width: sw(199),
                                height: sh(39),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: FColors.primaryColor,
                                    borderRadius: BorderRadius.circular(sw(10)),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: sw(32)),
                                        child: Text(
                                          "PKR",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: sw(20)
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: c.fareController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: sw(20)
                                          ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(vertical: sh(11)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              /// +5 button
                              Positioned(
                                top: sh(75),
                                right: sw(38),
                                child: IconButton(
                                  icon: Image.asset(
                                    "assets/images/plus5.png",
                                    width: sw(40),
                                    height: sh(40),
                                  ),
                                  onPressed: () => c.adjustFare(5),
                                ),
                              ),

                              /// Raise Fare button
                              Positioned(
                                top: sh(135),
                                left: sw(41),
                                width: sw(358),
                                height: sh(48),
                                child: FPrimaryButton(
                                  onPressed: c.raiseFare,
                                  text: 'Raise Fare',
                                  backgroundColor: FColors.chipBg,
                                  textStyle: TextStyle(fontSize: sw(16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}