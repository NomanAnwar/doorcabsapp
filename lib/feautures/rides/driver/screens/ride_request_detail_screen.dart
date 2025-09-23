import 'package:doorcab/utils/constants/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/ride_request_detail_controller.dart';

class RideRequestDetailScreen extends StatelessWidget {
  const RideRequestDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RideRequestDetailController());

    const baseWidth = 440.0;
    const baseHeight = 956.0;
    final size = MediaQuery.of(context).size;
    double sw(double w) => w * size.width / baseWidth;
    double sh(double h) => h * size.height / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Back arrow
          Positioned(
            top: sh(39),
            left: sw(33),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
            ),
          ),

          /// Menu icon
          Positioned(
            top: sh(25),
            left: sw(382),
            child: Icon(Icons.menu, size: sw(39), color: Colors.black),
          ),

          /// Map
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: sh(450),
            child: Obx(() {
              if (c.currentPosition.value == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: c.currentPosition.value!,
                  zoom: 14,
                ),
                myLocationEnabled: true,
                markers: c.markers,
                polylines:
                    c.routePolyline.value != null
                        ? {c.routePolyline.value!}
                        : {},
              );
            }),
          ),

          /// Passenger detail card
          Positioned(
            top: sh(456),
            left: sw(10),
            child: Container(
              width: sw(420),
              height: sh(218),
              decoration: BoxDecoration(
                color: const Color(0xFFE3E3E3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  /// Passenger Image
                  Positioned(
                    top: sh(12),
                    left: sw(18),
                    child: CircleAvatar(
                      radius: sw(30),
                      backgroundImage:
                          c.request.passengerImage.isNotEmpty
                              ? NetworkImage(c.request.passengerImage)
                              : const AssetImage(FImages.profile_img_sample)
                                  as ImageProvider,
                    ),
                  ),

                  /// Passenger Name, Rating Star, and Rating Value in a single row
                  Positioned(
                    top: sh(13),
                    left: sw(90),
                    child: Row(
                      children: [
                        /// Passenger Name
                        Obx(
                          () => Text(
                            c.passengerName.value,
                            style: FTextTheme.lightTextTheme.titleMedium,
                          ),
                        ),

                        SizedBox(width: sw(15)),
                        // Spacing between name and star

                        /// Passenger Rating Star
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFFFC300),
                        ),

                        SizedBox(width: sw(5)),
                        // Spacing between star and rating value

                        /// Passenger Rating Value
                        Obx(
                          () => Text(
                            c.passengerRating.value.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Pickup
                  Positioned(
                    top: sh(43),
                    left: sw(90),
                    child: Obx(
                      () => Text(
                        "Pickup: ${c.pickupAddress.value}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),

                  /// Dropoff
                  Positioned(
                    top: sh(65),
                    left: sw(90),
                    child: Obx(
                      () => Text(
                        "Dropoff: ${c.dropoffAddress.value}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),

                  /// Estimated arrival
                  Positioned(
                    top: sh(88),
                    left: sw(90),
                    child: Obx(
                      () => Text(
                        "Estimated Arrival time: ${c.estimatedPickupTime.value}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),

                  /// Estimated dropoff
                  Positioned(
                    top: sh(106),
                    left: sw(90),
                    child: Obx(
                      () => Text(
                        "Estimated Dropoff time: ${c.estimatedDropoffTime.value}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),

                  /// Time + Distance
                  Positioned(
                    top: sh(134),
                    left: sw(260),
                    child: Obx(
                      () => Text(
                        c.estimatedPickupTime.value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Positioned(
                    top: sh(134),
                    left: sw(365),
                    child: Obx(
                      () => Text(
                        c.distance.value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Fare & Accept buttons
          Positioned(
            top: sh(617),
            left: sw(28),
            child: Row(
              children: [
                Obx(
                  () => ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003566),
                      minimumSize: Size(sw(185), sh(37)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    icon: Image.asset("assets/images/cash.png"),
                    // icon: const Icon(Icons.attach_money, color: Colors.white),
                    label: Text(
                      "PKR ${c.fare.value}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(width: sw(20)),
                Obx(
                  () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          c.offerSecondsLeft.value > 0
                              ? const Color(0xFFF8DC25)
                              : const Color(0xFFFFC300),
                      minimumSize: Size(sw(160), sh(37)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed:
                        c.offerSecondsLeft.value > 0
                            ? () {
                              c.acceptRide(
                                c.request.id,
                                c.fare.value.toDouble(),
                              );
                            }
                            : null,
                    child: Obx(
                      () =>
                          c.isLoading.value
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                              : Text(
                                "Accept (${c.offerSecondsLeft.value})",
                                style: const TextStyle(color: Colors.black),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// Quick fare buttons
          Positioned(
            top: sh(687),
            left: sw(59),
            child: Row(
              children: [
                _fareChip("260", sw, c),
                SizedBox(width: sw(10)),
                _fareChip("270", sw, c, selected: true),
                SizedBox(width: sw(10)),
                _fareChip("280", sw, c),
              ],
            ),
          ),

          /// Offer amount input
          Positioned(
            top: sh(750),
            left: sw(19),
            child: Container(
              width: sw(393),
              height: sh(45),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3E3E3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: c.offerController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Type your offer amount",
                ),
              ),
            ),
          ),

          /// Close Request button
          Positioned(
            top: sh(866),
            left: sw(41),
            child: SizedBox(
              width: sw(358),
              height: sh(48),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003566),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Get.back(),
                child: const Text(
                  "Close Request",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareChip(
    String amount,
    double Function(double) sw,
    RideRequestDetailController c, {
    bool selected = false,
  }) {
    return InkWell(
      onTap: () => c.fare.value = int.parse(amount),
      child: Obx(() {
        // force Obx to always depend on c.fare
        final isSelected =
            c.fare.value.toString() == amount || (selected && true);

        return Container(
          width: sw(100),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFF003566) : const Color(0xFF595959),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "PKR $amount",
            style: const TextStyle(color: Colors.white),
          ),
        );
      }),
    );
  }
}
