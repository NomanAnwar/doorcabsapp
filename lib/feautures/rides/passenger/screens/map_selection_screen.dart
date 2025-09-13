
import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/map_selection_controller.dart';

class MapSelectionScreen extends StatelessWidget {
  const MapSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MapSelectionController());

    return Scaffold(
      body: Obx(
            () => Stack(
          children: [
            GoogleMap(
              initialCameraPosition:
              CameraPosition(target: c.center.value, zoom: 15),
              onMapCreated: c.onMapCreated,
              onCameraMove: c.onCameraMove,
              onCameraIdle: c.onCameraIdle,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
            ),

            /// Back arrow
            Positioned(
              top: 44,
              left: 26,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: Get.back,
                ),
              ),
            ),

            /// Center pin
            const Center(
                child: Icon(Icons.location_pin, size: 48, color: Colors.red)),

            /// Address display
            Positioned(
              left: 24,
              right: 24,
              bottom: 92,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                ),
              ),
            ),

            /// Done button
            Positioned(
              left: 45,
              right: 45,
              bottom: 30,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FColors.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: c.confirm,
                  child: Text("Done", style: FTextTheme.darkTextTheme.labelLarge,),
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }
}
