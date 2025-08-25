// map_selection_screen.dart
import 'package:doorcab/utils/constants/colors.dart';
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
      body: Obx(() => Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: c.center.value, zoom: 15),
            onMapCreated: c.onMapCreated,
            onCameraMove: c.onCameraMove,
            onCameraIdle: c.onCameraIdle,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
          ),

          /// Back arrow (top-left)
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
          const Center(child: Icon(Icons.location_pin, size: 48, color: Colors.red)),

          /// Done button (bottom center)
          Positioned(
            left: 45,
            right: 45,
            bottom: 30,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: FColors.primaryColor),
                onPressed: c.confirm,
                child: const Text("Done"),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
