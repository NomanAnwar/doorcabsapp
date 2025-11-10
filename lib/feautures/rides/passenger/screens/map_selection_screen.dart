import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/system_ui_mixin.dart';
import '../controllers/map_selection_controller.dart';

class MapSelectionScreen extends StatelessWidget{
  const MapSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MapSelectionController("AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4"));

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;
    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;


    return Scaffold(
      body: Obx(() {
        if (c.isLoadingLocation.value) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: sw(2),
              color: FColors.secondaryColor,
            ),
          );
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: c.center.value, zoom: 15),
              onMapCreated: c.onMapCreated,
              onCameraMove: c.onCameraMove,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              markers: {
                if (c.selectedPlace.value != null)
                  Marker(
                    markerId: const MarkerId("selected"),
                    position: c.selectedPlace.value!.latLng!,
                    icon: c.markerIcon ?? BitmapDescriptor.defaultMarker,
                  ),
              },
            ),

            /// Back arrow
            Positioned(
              top: sh(44),
              left: sw(26),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black87, size: sw(28.02)),
                onPressed: Get.back,
              ),
            ),

            /// Center pin stays if no suggestion selected
            if (c.selectedPlace.value == null)
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

            /// Search input
            Positioned(
              left: sw(24),
              right: sw(24),
              top: sh(80),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(sw(12)),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: TextField(
                  onTap: () {
                    // Auto-select text on tap
                    c.queryCtrl.selection = TextSelection(baseOffset: 0, extentOffset: c.queryCtrl.text.length);
                  },
                  controller: c.queryCtrl,
                  focusNode: c.queryFocus,
                  decoration: InputDecoration(
                    hintText: "Search for a place...",
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: sw(12), vertical: sh(14)),
                  ),
                ),
              ),
            ),

            /// Suggestions list
            Obx(() {
              final show = c.showSuggestions.value && c.suggestions.isNotEmpty;
              if (!show) return const SizedBox.shrink();

              return Positioned(
                left: sw(24),
                right: sw(24),
                top: sh(150),
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(sw(12)),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                      ),
                      padding: EdgeInsets.symmetric(vertical: sh(8)), // ⬅ adds top/bottom space
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: sh(300)),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: c.suggestions.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                          itemBuilder: (_, i) {
                            final s = c.suggestions[i];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: sw(12), vertical: sh(6)),
                              title: Text(
                                s.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                              onTap: () => c.selectSuggestion(s),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),


            /// Done button
            Positioned(
              left: sw(45),
              right: sw(45),
              bottom: sh(30),
              child: SizedBox(
                height: sh(48),
                width: sw(358),
                child: Obx(() => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.canConfirm ? FColors.secondaryColor : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sw(14)),
                    ),
                  ),
                  onPressed: c.canConfirm ? c.confirm : null,
                  child: Text(
                    FTextStrings.done,
                    style: FTextTheme.darkTextTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! * screenWidth / baseWidth,
                    ),
                  ),
                )),
              ),
            ),

            /// Recenter FAB
            Positioned(
              bottom: sh(160),
              right: sw(16),
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: c.recenter,
                child: Icon(Icons.my_location, color: Colors.black87, size: sw(20)),
              ),
            ),
          ],
        );
      }),
    );
  }
}
