import 'package:doorcab/common/widgets/buttons/f_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/available_drivers_controller.dart';

class AvailableDriversScreen extends StatelessWidget {
  const AvailableDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AvailableDriversController());

    // Get the initial fare from previous screen
    final initialFare = Get.arguments?['fare'] ?? 250;
    c.fareController.text = initialFare.toString();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Map full screen
          Positioned.fill(
            child: Obx(() {
              if (c.currentPosition.value == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: c.currentPosition.value!,
                  zoom: 15,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                onMapCreated: c.onMapCreated,
                markers: c.driverMarkers.values.toSet(),
              );
            }),
          ),

          /// Back button
          PositionedScaled(
            top: 44,
            left: 26,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: Get.back,
            ),
          ),

          /// Bottom container
          PositionedScaled(
            top: 672,
            left: 0,
            right: 0,
            child: Container(
              height: 284,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, -2))
                ],
              ),
              child: Stack(
                children: [
                  /// "x drivers viewing" text
                  PositionedScaled(
                    top: 20, // from top 692 - container top 672 = 20
                    left: 18,
                    child: SizedBox(
                      width: 180,
                      child: Obx(() => Text(
                        "${c.viewingDrivers.value} drivers are viewing your request",
                        style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.w400,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                    ),
                  ),

                  /// Driver avatars row (max 6)
                  PositionedScaled(
                    top: 17, // from top 689 - container top 672 = 17
                    left: 274,
                    width: 128,
                    height: 24,
                    child: Obx(() => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: c.driverAvatars.take(6).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 4),
                      itemBuilder: (_, index) {
                        final avatar = c.driverAvatars[index];
                        return CircleAvatar(
                          radius: 12,
                          backgroundImage: AssetImage(avatar),
                        );
                      },
                    )
                    ),
                  ),

                  /// Grey sub-container
                  PositionedScaled(
                    top: 51, // from top 723 - container top 672 = 51
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 196,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E3E3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Stack(
                        children: [
                          /// "Waiting for drivers..." text
                          PositionedScaled(
                            top: 5, // from top 728 - grey top 723 = 5
                            left: 22,
                            child: const Text(
                              "Waiting for drivers to bid...",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),

                          /// Countdown timer
                          PositionedScaled(
                            top: 25, // from top 748 - grey top 723 = 25
                            right: 22,
                            child: Obx(() => Text(
                              "${c.remainingSeconds.value}s",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )),
                          ),

                          /// Progress bar
                          PositionedScaled(
                            top: 50, // from top 773 - grey top 723 = 50
                            left: 18,
                            right: 18,
                            child: Obx(() => LinearProgressIndicator(
                              value: c.remainingSeconds.value / 60,
                              backgroundColor: Colors.white,
                              color: FColors.secondaryColor,
                            )),
                          ),

                          /// -5 button
                          PositionedScaled(
                            top: 82, // from top 805 - grey top 723 = 82
                            left: 38,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => c.adjustFare(-5),
                            ),
                          ),

                          /// Fare field
                          PositionedScaled(
                            top: 76, // from top 799 - grey top 723 = 76
                            left: 126,
                            width: 199,
                            height: 39,
                            child: TextField(
                              controller: c.fareController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixText: "PKR ",
                              ),
                            ),
                          ),

                          /// +5 button
                          PositionedScaled(
                            top: 82, // from top 805 - grey top 723 = 82
                            left: 365,
                            child: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => c.adjustFare(5),
                            ),
                          ),

                          /// Raise Fare button
                          PositionedScaled(
                            top: 135, // from top 858 - grey top 723 = 135
                            left: 41,
                            width: 358,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF595959),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: c.raiseFare,
                              child: Text("Raise Fare",),
                            ),
                          ),

                          /// Raise Fare button
                          PositionedScaled(
                            top: 135, // from top 858 - grey top 723 = 135
                            left: 41,
                            width: 358,
                            height: 48,
                            child: FPrimaryButton(
                              onPressed: c.raiseFare,
                              text: 'Raise Fare',
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
    );
  }
}
