import 'package:doorcab/utils/constants/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../common/widgets/snakbar/snackbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/ride_request_detail_controller.dart';

class RideRequestDetailScreen extends StatelessWidget {
  const RideRequestDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RideRequestDetailController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base reference (iPhone 16 Pro Max)
    final baseWidth = 440.0;
    final baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return WillPopScope(
      onWillPop: () async {
        if (c.isBidSubmitted.value) {
          FSnackbar.show(
            title: "Please Wait",
            message: "Cannot go back while waiting for bid response",
            isError: true,
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Obx(() {
          final loading = c.isLoading.value;

          return Stack(
            children: [
              /// Main UI
              SingleChildScrollView(
                child: SizedBox(
                  height: screenHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      /// Back arrow
                      Positioned(
                        top: sh(39),
                        left: sw(33),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: sw(24),
                          ),
                          onPressed:
                              c.isBidSubmitted.value
                                  ? null
                                  : () => c.closeScreen(),
                        ),
                      ),

                      /// Menu icon
                      Positioned(
                        top: sh(39),
                        right: sw(33),
                        child: Icon(
                          Icons.menu,
                          size: sw(24),
                          color: Colors.black,
                        ),
                      ),

                      /// Map
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: sh(450),
                        child: Obx(() {
                          if (c.currentPosition.value == null) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: FColors.secondaryColor,
                              ),
                            );
                          }
                          return GoogleMap(
                            onMapCreated: c.onMapCreated,
                            initialCameraPosition: CameraPosition(
                              target: c.currentPosition.value!,
                              zoom: 14,
                            ),
                            myLocationButtonEnabled: true,
                            markers: c.markers.value,
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
                            borderRadius: BorderRadius.circular(sw(20)),
                          ),
                          child: Stack(
                            children: [
                              /// Passenger Image
                              Positioned(
                                top: sh(12),
                                left: sw(18),
                                child: SizedBox(
                                  width: sw(60),
                                  height: sh(60),
                                  child: CircleAvatar(
                                    radius: sw(30),
                                    backgroundImage:
                                        c.request.passengerImage.isNotEmpty
                                            ? NetworkImage(
                                              c.request.passengerImage,
                                            )
                                            : const AssetImage(
                                                  FImages.profile_img_sample,
                                                )
                                                as ImageProvider,
                                  ),
                                ),
                              ),

                              /// Passenger Name, Rating Star, and Rating Value
                              Positioned(
                                top: sh(13),
                                left: sw(90),
                                child: Row(
                                  children: [
                                    Obx(
                                      () => Text(
                                        c.passengerName.value.toUpperCase(),
                                        style: FTextTheme
                                            .lightTextTheme
                                            .titleSmall!
                                            .copyWith(
                                              fontWeight: FontWeight.w500,
                                              fontSize:
                                                  FTextTheme
                                                      .lightTextTheme
                                                      .titleSmall!
                                                      .fontSize! *
                                                  screenWidth /
                                                  baseWidth,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: sw(15)),
                                    Icon(
                                      Icons.star,
                                      size: sw(14),
                                      color: const Color(0xFFFFC300),
                                    ),
                                    SizedBox(width: sw(5)),
                                    Obx(
                                      () => Text(
                                        c.passengerRating.value.toString(),
                                        style: FTextTheme
                                            .lightTextTheme
                                            .labelSmall!
                                            .copyWith(
                                              fontWeight: FontWeight.w400,
                                              fontSize:
                                                  (FTextTheme
                                                          .lightTextTheme
                                                          .labelSmall!
                                                          .fontSize! *
                                                      screenWidth /
                                                      baseWidth) -
                                                  2,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// Pickup
                              Positioned(
                                top: sh(50),
                                left: sw(90),
                                child: Obx(
                                  () => Container(
                                    width: sw(320),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Pickup : ',
                                            style: FTextTheme
                                                .lightTextTheme
                                                .labelSmall!
                                                .copyWith(
                                                  fontSize:
                                                      FTextTheme
                                                          .lightTextTheme
                                                          .labelSmall!
                                                          .fontSize! *
                                                      screenWidth /
                                                      baseWidth,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          TextSpan(
                                            text: c.pickupAddress.value,
                                            style: FTextTheme
                                                .lightTextTheme
                                                .labelSmall!
                                                .copyWith(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize:
                                                      FTextTheme
                                                          .lightTextTheme
                                                          .labelSmall!
                                                          .fontSize! *
                                                      screenWidth /
                                                      baseWidth,
                                                ),
                                          ),
                                        ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),

                              /// Dropoff
                              Positioned(
                                top: sh(75),
                                left: sw(90),
                                child: Obx(
                                  () => Container(
                                    width: sw(320),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Dropoff : ',
                                            style: FTextTheme
                                                .lightTextTheme
                                                .labelSmall!
                                                .copyWith(
                                                  fontSize:
                                                      FTextTheme
                                                          .lightTextTheme
                                                          .labelSmall!
                                                          .fontSize! *
                                                      screenWidth /
                                                      baseWidth,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          TextSpan(
                                            text: c.dropoffAddress.value,
                                            style: FTextTheme
                                                .lightTextTheme
                                                .labelSmall!
                                                .copyWith(
                                                  fontSize:
                                                      FTextTheme
                                                          .lightTextTheme
                                                          .labelSmall!
                                                          .fontSize! *
                                                      screenWidth /
                                                      baseWidth,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                          ),
                                        ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),

                              /// Estimated arrival
                              Positioned(
                                top: sh(100),
                                left: sw(90),
                                child: Obx(
                                  () => Text(
                                    "Estimated Arrival time ${c.estimatedPickupTime.value}",
                                    style: FTextTheme.lightTextTheme.labelSmall!
                                        .copyWith(
                                          fontSize:
                                              FTextTheme
                                                  .lightTextTheme
                                                  .labelSmall!
                                                  .fontSize! *
                                              screenWidth /
                                              baseWidth,
                                          fontWeight: FontWeight.w400,
                                        ),
                                  ),
                                ),
                              ),

                              /// Estimated dropoff
                              Positioned(
                                top: sh(125),
                                left: sw(90),
                                child: Obx(
                                  () => Text(
                                    "Estimated Dropoff time ${c.estimatedDropoffTime.value}",
                                    style: FTextTheme.lightTextTheme.labelSmall!
                                        .copyWith(
                                          fontSize:
                                              FTextTheme
                                                  .lightTextTheme
                                                  .labelSmall!
                                                  .fontSize! *
                                              screenWidth /
                                              baseWidth,
                                          fontWeight: FontWeight.w400,
                                        ),
                                  ),
                                ),
                              ),

                              /// Time + Distance
                              Positioned(
                                top: sh(150),
                                left: sw(260),
                                child: Obx(
                                  () => Text(
                                    c.estimatedPickupTime.value,
                                    style: FTextTheme.lightTextTheme.labelSmall!
                                        .copyWith(
                                          fontSize:
                                              (FTextTheme
                                                      .lightTextTheme
                                                      .labelSmall!
                                                      .fontSize! *
                                                  screenWidth /
                                                  baseWidth) -
                                              2,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: sh(150),
                                right: sw(35),
                                child: Obx(
                                  () => Text(
                                    c.distance.value,
                                    style: FTextTheme.lightTextTheme.labelSmall!
                                        .copyWith(
                                          fontSize:
                                              (FTextTheme
                                                      .lightTextTheme
                                                      .labelSmall!
                                                      .fontSize! *
                                                  screenWidth /
                                                  baseWidth) -
                                              2,
                                          fontWeight: FontWeight.w700,
                                        ),
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
                        right: sw(28),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // PKR Amount Container
                            Container(
                              width: sw(185),
                              height: sh(37),
                              padding: EdgeInsets.symmetric(horizontal: sw(8)),
                              decoration: BoxDecoration(
                                color: const Color(0xFF003566),
                                borderRadius: BorderRadius.circular(sw(10)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: sw(48),
                                    height: sh(30),
                                    padding: EdgeInsets.symmetric(
                                      vertical: sh(1),
                                    ),
                                    decoration: BoxDecoration(
                                      color: FColors.white,
                                      borderRadius: BorderRadius.circular(
                                        sw(6),
                                      ),
                                    ),
                                    child: Image.asset(
                                      "assets/images/cash.png",
                                    ),
                                  ),
                                  SizedBox(width: sw(8)),
                                  Obx(
                                    () => Text(
                                      'PKR ${c.fare.value.toStringAsFixed(0)}',
                                      style: FTextTheme
                                          .lightTextTheme
                                          .headlineSmall!
                                          .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: FColors.white,
                                            fontSize:
                                                FTextTheme
                                                    .lightTextTheme
                                                    .headlineSmall!
                                                    .fontSize! *
                                                screenWidth /
                                                baseWidth,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Accept Button
                            Obx(
                              () => ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      !c.isAcceptButtonEnabled
                                          ? Colors.grey
                                          : const Color(0xFFF8DC25),
                                  minimumSize: Size(sw(160), sh(37)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(sw(10)),
                                  ),
                                ),
                                onPressed:
                                    !c.isAcceptButtonEnabled
                                        ? null
                                        : () {
                                          c.acceptRide(
                                            c.request.id,
                                            c.fare.value.toDouble(),
                                          );
                                        },
                                child: Text(
                                  "Accept",
                                  style: FTextTheme.lightTextTheme.titleSmall!
                                      .copyWith(
                                        fontSize:
                                            FTextTheme
                                                .lightTextTheme
                                                .titleSmall!
                                                .fontSize! *
                                            screenWidth /
                                            baseWidth,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Quick fare buttons
                      if (!c.isBidSubmitted.value)
                        Positioned(
                          top: sh(687),
                          left: sw(59),
                          child: Obx(
                            () => Row(
                              children: [
                                _fareChip(
                                  c.originalFare.value + 20,
                                  sw,
                                  sh,
                                  c,
                                  screenWidth,
                                  baseWidth,
                                ),
                                SizedBox(width: sw(10)),
                                _fareChip(
                                  c.originalFare.value + 30,
                                  sw,
                                  sh,
                                  c,
                                  screenWidth,
                                  baseWidth,
                                ),
                                SizedBox(width: sw(10)),
                                _fareChip(
                                  c.originalFare.value + 40,
                                  sw,
                                  sh,
                                  c,
                                  screenWidth,
                                  baseWidth,
                                ),
                              ],
                            ),
                          ),
                        ),

                      /// Offer amount input - FIXED: Added keyboard padding
                      if (!c.isBidSubmitted.value)
                        Positioned(
                          top: sh(750),
                          left: sw(19),
                          child: Container(
                            width: sw(393),
                            height: sh(45),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3E3E3),
                              borderRadius: BorderRadius.circular(sw(14)),
                            ),
                            child: TextField(
                              controller: c.offerController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 5,
                              style: FTextTheme.lightTextTheme.titleMedium!
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
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Type your offer amount",
                                counterText: "",
                                contentPadding: EdgeInsets.only(
                                  bottom: 12,
                                ), // ✅ FIX: Better vertical alignment
                              ),
                              onChanged: c.onOfferTextChanged,
                            ),
                          ),
                        ),

                      /// Close Request button - FIXED: Added bottom padding for keyboard
                      Positioned(
                        top: sh(860), // ✅ MOVED UP: To avoid keyboard overlap
                        left: sw(41),
                        child: SizedBox(
                          width: sw(358),
                          height: sh(48),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  c.isBidSubmitted.value
                                      ? Colors.grey
                                      : const Color(0xFF003566),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(sw(14)),
                              ),
                            ),
                            onPressed:
                                c.isBidSubmitted.value
                                    ? null
                                    : () => c.closeScreen(),
                            child: Text(
                              c.isBidSubmitted.value
                                  ? "Waiting for Response..."
                                  : "Close Request",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
                      ),
                    ],
                  ),
                ),
              ),

              /// 🔹 Fullscreen loader overlay
              if (loading)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black54,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: sh(20)),
                      Text(
                        c.isBidSubmitted.value
                            ? "Waiting for passenger response..."
                            : "Submitting your bid...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sw(16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _fareChip(
    int amount,
    double Function(double) sw,
    double Function(double) sh,
    RideRequestDetailController c,
    double screenWidth,
    double baseWidth,
  ) {
    return InkWell(
      onTap: () {
        c.selectChip(amount);
      },
      child: Obx(() {
        final isSelected = c.selectedChipAmount.value == amount;
        return Container(
          width: sw(100),
          height: sh(40),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFF003566) : const Color(0xFF595959),
            borderRadius: BorderRadius.circular(sw(10)),
          ),
          child: Text(
            "$amount",
            style: FTextTheme.lightTextTheme.displaySmall!.copyWith(
              fontWeight: FontWeight.w600,
              fontSize:
                  FTextTheme.lightTextTheme.displaySmall!.fontSize! *
                  screenWidth /
                  baseWidth,
              color: FColors.white,
            ),
          ),
        );
      }),
    );
  }
}
