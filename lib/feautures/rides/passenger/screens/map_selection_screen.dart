import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/constants/text_strings.dart';
import '../controllers/map_selection_controller.dart';

class MapSelectionScreen extends StatelessWidget {
  const MapSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MapSelectionController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      body: Obx(
            () {
          if (c.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: sw(2),
                color: FColors.secondaryColor,
              ),
            );
          }

          return SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: c.center.value,
                    zoom: 15,
                  ),
                  onMapCreated: c.onMapCreated,
                  onCameraMove: c.onCameraMove,
                  onCameraIdle: c.onCameraIdle,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                ),

                /// Back arrow
                Positioned(
                  top: sh(44),
                  left: sw(26),
                  child: IconButton(
                    icon: Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                        size: sw(28.02)
                    ),
                    onPressed: Get.back,
                  ),
                ),

                /// Center pin
                Center(
                  child: IgnorePointer(
                    ignoring: true,
                    child: Image.asset(
                      "assets/images/position_marker.png",
                      width: sw(60),
                      height: sh(60),
                    ),
                  ),
                ),

                /// Address display
                Positioned(
                  left: sw(24),
                  right: sw(24),
                  bottom: sh(92),
                  child: Container(
                    width: sw(393),
                    height: sh(52),
                    padding: EdgeInsets.symmetric(
                        horizontal: sw(12),
                        vertical: sh(15)
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(sw(12)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      c.address.value.isEmpty
                          ? 'Move the map to pick a location...'
                          : c.address.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FTextTheme
                          .lightTextTheme
                          .titleMedium!
                          .copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize:
                        FTextTheme
                            .lightTextTheme
                            .titleMedium!
                            .fontSize! *
                            screenWidth /
                            baseWidth,
                      ),
                    ),
                  ),
                ),

                /// Done button
                // Positioned(
                //   left: sw(45),
                //   right: sw(45),
                //   bottom: sh(30),
                //   child: SizedBox(
                //     height: sh(48),
                //     child: ElevatedButton(
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: FColors.secondaryColor,
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(sw(14)),
                //         ),
                //       ),
                //       onPressed: c.confirm,
                //       child: Text(
                //         "Done",
                //         style: FTextTheme.darkTextTheme.labelLarge?.copyWith(
                //           fontSize: sw(16),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),


                Positioned(
                  left: sw(45),
                  right: sw(45),
                  bottom: sh(30),
                  child: SizedBox(
                    height: sh(48),
                    width: sw(358),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FColors.secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(sw(14)),
                        ),
                      ),
                      onPressed: c.confirm,
                      child: Text(
                        FTextStrings.done,
                        style: FTextTheme.darkTextTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: FTextTheme.lightTextTheme
                              .titleSmall!.fontSize! *
                              screenWidth /
                              baseWidth,
                        ),
                      ),
                    ),
                  ),
                ),

                /// Recenter FAB (bottom-right)
                Positioned(
                  bottom: sh(160),
                  right: sw(16),
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: c.recenter,
                    child: Icon(
                      Icons.my_location,
                      color: Colors.black87,
                      size: sw(20),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}