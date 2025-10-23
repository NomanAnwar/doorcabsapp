import 'package:doorcab/common/widgets/buttons/f_primary_button.dart';
import 'package:doorcab/feautures/rides/driver/screens/reuseable_widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
      key: c.scaffoldKey,
      backgroundColor: Colors.white,
      drawer: PassengerDrawer(),
      body: Stack(
        children: [
          /// Main content
          SingleChildScrollView(
            child: SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: Stack(
                children: [
                  /// Map full screen
                  Positioned.fill(
                    child: Obx(() {
                      if (c.currentPosition.value == null) {
                        return Center(
                          child: CircularProgressIndicator(strokeWidth: sw(2)),
                        );
                      }
                      return GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: c.currentPosition.value!,
                          zoom: 15,
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
                      icon: Icon(Icons.arrow_back, size: sw(28)),
                      onPressed: Get.back,
                    ),
                  ),

                  // Menu Button
                  Positioned(
                    top: sh(44),
                    right: sw(33),
                    child: GestureDetector(
                      onTap: () {
                        c.scaffoldKey.currentState?.openDrawer();
                      },
                      child: Container(
                        width: sw(39),
                        height: sh(39),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(sw(20)),
                        ),
                        child: Image.asset(
                          'assets/images/Menu.png',
                          width: sw(20),
                          height: sh(20),
                        ),
                      ),
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
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(sw(14)),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: sw(6),
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          /// "x drivers viewing" text
                          Positioned(
                            top: sh(20),
                            left: sw(18),
                            child: SizedBox(
                              width: sw(230),
                              child: Obx(
                                    () => Text(
                                  "${c.viewingDrivers.value} drivers are viewing your request",
                                  style: FTextTheme.lightTextTheme.labelSmall!
                                      .copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                ),
                              ),
                            ),
                          ),

                          /// Driver avatars row (max 6)
                          Positioned(
                            top: sh(17),
                            left: sw(285),
                            width: sw(140),
                            height: sh(24),
                            child: Obx(
                                  () => ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: c.driverAvatars.take(6).length,
                                separatorBuilder: (_, __) => SizedBox(width: sw(1)),
                                itemBuilder: (_, index) {
                                  final avatar = c.driverAvatars[index];
                                  return CircleAvatar(
                                    radius: sw(12),
                                    backgroundImage: AssetImage(avatar),
                                  );
                                },
                              ),
                            ),
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
                                    top: sh(15),
                                    left: sw(22),
                                    child: Text(
                                      "Good fare. Your request gets priority",
                                      style: FTextTheme.lightTextTheme.labelSmall!
                                          .copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: FTextTheme.lightTextTheme
                                            .labelSmall!.fontSize! *
                                            screenWidth /
                                            baseWidth,
                                      ),
                                    ),
                                  ),

                                  /// Countdown timer
                                  Positioned(
                                    top: sh(15),
                                    right: sw(22),
                                    child: Obx(
                                          () => Text(
                                        "${c.remainingSeconds.value}s",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: sw(16),
                                        ),
                                      ),
                                    ),
                                  ),

                                  /// Progress bar
                                  Positioned(
                                    top: sh(50),
                                    left: sw(18),
                                    right: sw(18),
                                    child: Obx(
                                          () => LinearProgressIndicator(
                                        value: c.remainingSeconds.value / 60,
                                        backgroundColor: FColors.chipBg,
                                        color: FColors.primaryColor,
                                      ),
                                    ),
                                  ),

                                  /// -5 button (UPDATED with disabled state)
                                  Positioned(
                                    top: sh(75),
                                    left: sw(38),
                                    child: Obx(() {
                                      return IconButton(
                                        icon: SvgPicture.asset(
                                          "assets/images/minus5.svg",
                                          color: c.isDecrementDisabled.value ? Colors.grey : null,
                                        ),
                                        onPressed: c.isDecrementDisabled.value ? null : () => c.adjustFare(-5),
                                      );
                                    }),
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
                                      alignment: Alignment.center,
                                      child: IntrinsicHeight(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Rs.",
                                              style: FTextTheme.lightTextTheme.labelLarge!.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            ConstrainedBox(
                                              constraints: BoxConstraints(maxWidth: sw(90)),
                                              child: TextField(
                                                controller: c.fareController,
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: (FTextTheme.lightTextTheme.titleMedium!.fontSize! + 4) *
                                                      screenWidth /
                                                      baseWidth,
                                                ),
                                                decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                  isCollapsed: true,
                                                  contentPadding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  /// +5 button (UPDATED with disabled state)
                                  Positioned(
                                    top: sh(75),
                                    right: sw(38),
                                    child: Obx(() {
                                      return IconButton(
                                        icon: SvgPicture.asset(
                                          "assets/images/plus5.svg",
                                          color: c.isIncrementDisabled.value ? Colors.grey : null,
                                        ),
                                        onPressed: c.isIncrementDisabled.value ? null : () => c.adjustFare(5),
                                      );
                                    }),
                                  ),

                                  /// Raise Fare button (UPDATED with disabled state) - ✅ FIXED
                                  Positioned(
                                    top: sh(135),
                                    left: sw(41),
                                    width: sw(358),
                                    height: sh(48),
                                    child: Obx(() {
                                      return ElevatedButton(
                                        onPressed: c.isRaiseFareDisabled.value ? null : () => c.raiseFare(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: c.isRaiseFareDisabled.value ? Colors.grey : FColors.chipBg,
                                          foregroundColor: c.isRaiseFareDisabled.value ? Colors.grey[600] : Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(sw(14)),
                                          ),
                                          minimumSize: Size(sw(358), sh(48)),
                                        ),
                                        child: Text(
                                          'Raise Fare',
                                          style: TextStyle(
                                            fontSize: sw(16),
                                            fontWeight: FontWeight.w600,
                                            color: c.isRaiseFareDisabled.value ? Colors.grey[600] : Colors.white,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Loading overlay for API calls
          Obx(() => c.isRaisingFare.value
              ? Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: sw(30), vertical: sh(20)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(sw(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: sw(10),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: sw(40),
                      height: sw(40),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(FColors.primaryColor),
                      ),
                    ),
                    SizedBox(height: sh(16)),
                    Text(
                      'Raising fare...',
                      style: TextStyle(
                        fontSize: sw(16),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}