import 'package:doorcab/feautures/rides/driver/screens/reuseable_widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/ride_booking_controller.dart';
import '../models/ride_option_model.dart';

class RideBookingScreen extends StatelessWidget {
  final RideBookingController controller = Get.put(RideBookingController());

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    Widget rideItem(RideOption option) {
      final bool selected = controller.selectedRideType.value == option.id;
      final passengers = controller.ridePassengers[option.id];
      final fare = controller.rideFare[option.id];

      // ✅ ADDED: Safety check for null values
      if (passengers == null || fare == null) {
        return SizedBox.shrink(); // Hide if not initialized
      }

      if (!selected) {
        // Collapsed (not selected)
        return GestureDetector(
          onTap: () => controller.selectRideType(option.id),
          child: Container(
            width: sw(419),
            height: sh(80),
            margin: EdgeInsets.symmetric(vertical: sh(8), horizontal: sw(8)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(sw(14)),
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withOpacity(0.06),
              //     blurRadius: sw(6),
              //     offset: const Offset(0, 2),
              //   ),
              // ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sw(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: sw(71),
                    height: sh(75.95),
                    child: Center(
                      child: option.imageAsset.toLowerCase().endsWith(".svg")
                          ? SvgPicture.asset(
                        option.imageAsset,
                        width: sw(71),
                        height: sh(75.95),
                        fit: BoxFit.contain,
                      )
                          : Image.asset(
                        option.imageAsset,
                        width: sw(71),
                        height: sh(75.95),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(width: sw(20)),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          option.name,
                          style: FTextTheme.lightTextTheme.titleMedium!
                              .copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: FTextTheme.lightTextTheme
                                .titleMedium!.fontSize! *
                                screenWidth /
                                baseWidth,
                          ),
                        ),
                        SizedBox(height: sh(4)),
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/person.svg',
                              width: sw(10),
                              height: sh(13),
                            ),
                            SizedBox(width: sw(4)),
                            Expanded(
                              child: Text(
                                option.subtitle,
                                style: FTextTheme.lightTextTheme.labelSmall!
                                    .copyWith(
                                  fontSize: FTextTheme.lightTextTheme
                                      .labelSmall!.fontSize! *
                                      screenWidth /
                                      baseWidth,
                                ),
                                overflow: TextOverflow.ellipsis, // ✅ ADD THIS
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: sh(2)),
                        Text(
                          option.description,
                          style: FTextTheme.lightTextTheme.labelSmall!
                              .copyWith(
                            color: FColors.chipBg.withOpacity(0.8),
                            fontSize: FTextTheme.lightTextTheme
                                .labelSmall!.fontSize! *
                                screenWidth /
                                baseWidth,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: sw(100),
                    height: sh(52),
                    child: Text(
                      option.fare,
                      style: FTextTheme.lightTextTheme.titleMedium!
                          .copyWith(
                        fontSize: FTextTheme.lightTextTheme
                            .titleMedium!.fontSize! *
                            screenWidth /
                            baseWidth,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Selected: Expanded view
      return Container(
        width: sw(419),
        height: sh(183),
        // margin: EdgeInsets.symmetric(vertical: sh(8), horizontal: sw(13)),
        decoration: BoxDecoration(
          color: Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(sw(14)),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.10),
          //     blurRadius: sw(14),
          //     offset: const Offset(0, 4),
          //   ),
          // ],
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => controller.selectRideType(option.id),
              child: Container(
                width: sw(400),
                height: sh(75),
                margin: EdgeInsets.all(sh(6)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(sw(14)),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.black.withOpacity(0.08),
                  //     blurRadius: sw(8),
                  //     offset: const Offset(0, 2),
                  //   ),
                  // ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sw(14)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: sw(83),
                        height: sh(60),
                        child: Center(
                          child: option.imageAsset.toLowerCase().endsWith(".svg")
                              ? SvgPicture.asset(
                            option.imageAsset,
                            width: sw(83),
                            height: sh(60),
                            fit: BoxFit.contain,
                          )
                              : Image.asset(
                            option.imageAsset,
                            width: sw(83),
                            height: sh(60),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(width: sw(20)),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  option.name,
                                  style: FTextTheme.lightTextTheme.titleSmall!
                                      .copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: FTextTheme.lightTextTheme
                                        .titleSmall!.fontSize! *
                                        screenWidth /
                                        baseWidth,
                                  ),
                                ),
                                SizedBox(
                                  width: sw(3),
                                ),
                                SvgPicture.asset(
                                  "assets/images/information.svg",
                                  width: sw(12),
                                  height: sh(12),
                                  // fit: BoxFit.contain,
                                )
                              ],
                            ),
                            SizedBox(height: sh(4)),
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/images/person.svg',
                                  width: sw(10),
                                  height: sh(13),
                                ),
                                SizedBox(width: sw(4)),
                                Text(
                                  option.subtitle,
                                  style: FTextTheme.lightTextTheme.labelSmall!
                                      .copyWith(
                                    fontSize: FTextTheme.lightTextTheme
                                        .labelSmall!.fontSize! *
                                        screenWidth /
                                        baseWidth,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: sh(2)),
                            Text(
                              option.description,
                              style: FTextTheme.lightTextTheme.labelSmall!
                                  .copyWith(
                                color: FColors.chipBg.withOpacity(0.8),
                                fontSize: FTextTheme.lightTextTheme
                                    .labelSmall!.fontSize! *
                                    screenWidth /
                                    baseWidth,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        child: Padding(
                          padding:  EdgeInsets.only(top: sh(8)),
                          child: SvgPicture.asset(
                            'assets/images/edit.svg',
                            width: sw(10),
                            height: sh(10),
                          ),
                        ),
                      )
                      // SizedBox(
                      //   width: sw(100),
                      //   height: sh(52),
                      //   child: Text(
                      //     option.fare,
                      //     style: TextStyle(
                      //       fontFamily: 'Poppins',
                      //       fontSize: sw(16),
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //     textAlign: TextAlign.left,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(
              height: sh(1),
              thickness: sh(1),
              color: const Color(0xFFF2F2F2),
            ),
            // Controls
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 0,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: sw(32.0), vertical: sh(3.0)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/images/person.svg',
                                width: sw(16),
                                height: sh(21),
                              ),
                              Text(
                                ' Passengers',
                                style: FTextTheme.lightTextTheme.labelLarge!
                                    .copyWith(
                                  fontSize: FTextTheme.lightTextTheme
                                      .labelLarge!.fontSize! *
                                      screenWidth /
                                      baseWidth,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => controller.decrementPassengers(option.id),
                                    child: Container(
                                      width: sw(20),
                                      height: sh(20),
                                      // padding: EdgeInsets.all(sw(6)),
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(sw(10)),
                                        // border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Icon(Icons.remove, size: sw(12), color: Colors.black),
                                    ),
                                  ),
                                  SizedBox(width: sw(6)),
                                  Obx(() => Container(
                                    width: sw(27),
                                    height: sh(27),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(sw(10)),
                                      border: Border.all(
                                        color: FColors.chipBg,
                                        width: sw(1),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${passengers.value}',
                                        style: FTextTheme.lightTextTheme.titleMedium!
                                            .copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontSize: FTextTheme.lightTextTheme
                                              .titleMedium!.fontSize! *
                                              screenWidth /
                                              baseWidth,
                                        ),
                                      ),
                                    ),
                                  )),
                                  SizedBox(width: sw(9)),
                                  GestureDetector(
                                    onTap: () => controller.incrementPassengers(option.id),
                                    child: Container(
                                      width: sw(20),
                                      height: sh(20),
                                      // padding: EdgeInsets.all(sw(6)),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(0, 0, 0, 0.54),
                                        borderRadius: BorderRadius.circular(sw(20)),
                                        // border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Icon(Icons.add, size: sw(18), color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: sh(5),),
                          Divider(height: sh(0.5), thickness: sh(1), color: const Color(0xFF2B2D30)),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => controller.decrementFare(option.id),
                                child: Container(
                                  width: sw(35),
                                  height: sh(35),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[600],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: sw(20),
                                      height: sh(5),
                                      child: SvgPicture.asset(
                                        'assets/images/minus.svg',
                                        fit: BoxFit.contain,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Column(
                                children: [
                                  Obx(() => Text(
                                    'PKR ${fare.value}',
                                    style: FTextTheme.lightTextTheme.headlineMedium!
                                        .copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: FTextTheme.lightTextTheme
                                          .headlineMedium!.fontSize! *
                                          screenWidth /
                                          baseWidth,
                                    ),
                                  )),
                                  // ✅ UPDATED: Show "Calculating..." while fares are being calculated
                                  Obx(() => controller.isCalculatingFare.value
                                      ? Text(
                                    'Calculating fare...',
                                    style: TextStyle(
                                      fontSize: sw(10),
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey,
                                    ),
                                  )
                                      : Text(
                                    'Recommended fare: ${option.fare}',
                                    style: FTextTheme.lightTextTheme.labelSmall!
                                        .copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontSize: FTextTheme.lightTextTheme
                                          .labelSmall!.fontSize! *
                                          screenWidth /
                                          baseWidth,
                                    ),
                                  )),
                                ],
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => controller.incrementFare(option.id),
                                child: Container(
                                  width: sw(35),
                                  height: sh(35),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFC107),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: sw(20),
                                      height: sh(20),
                                      child: SvgPicture.asset(
                                        'assets/images/add_stop_plus.svg',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Helper method for loading overlay
    Widget _buildLoadingOverlay(String message) {
      return Container(
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
                  offset: Offset(0, 4),
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
                    valueColor: AlwaysStoppedAnimation<Color>(FColors.secondaryColor),
                  ),
                ),
                SizedBox(height: sh(16)),
                Text(
                  message,
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
      );
    }

    return Scaffold(
      key: controller.scaffoldKey,
      drawer: PassengerDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: Stack(
                children: [
                  // Google Map
                  Positioned(
                    top: sh(-31),
                    width: screenWidth,
                    height: sh(466 + 31),
                    child: Obx(
                          () => GoogleMap(
                        onMapCreated: controller.onMapCreated,
                        initialCameraPosition: controller.initialCameraPosition,
                        markers: controller.markers.toSet(),
                        polylines: controller.polylines.toSet(),
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        trafficEnabled: false,
                        buildingsEnabled: true,
                        indoorViewEnabled: false,
                        mapType: MapType.normal,
                      ),
                    ),
                  ),

                  // Back Arrow
                  Positioned(
                    top: sh(38),
                    left: sw(33),
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Icon(Icons.arrow_back, size: sw(28)),
                    ),
                  ),

                  // Menu Button
                  Positioned(
                    top: sh(38),
                    right: sw(33),
                    child: GestureDetector(
                      onTap: () {
                        controller.scaffoldKey.currentState?.openDrawer();
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

                  // Location Card
                  Positioned(
                    top: sh(88),
                    left: sw(29),
                    child: Container(
                      width: sw(393),
                      height: sh(106),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(sw(14)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: sw(12),
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: sh(22),
                            left: sw(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => Get.back(),
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/circle.svg',
                                        width: sw(22),
                                        height: sh(22),
                                      ),
                                      SizedBox(width: sw(8)),
                                      SizedBox(
                                        width: sw(300),
                                        child: Obx(() => Text(
                                          controller.pickupLocation.value,
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: sw(364),
                                  child: Divider(
                                    thickness: sh(1.0),
                                    color: Colors.black54,
                                    indent: sw(10),
                                    endIndent: sw(10),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Get.back(),
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/location.svg',
                                        width: sw(20),
                                        height: sh(20),
                                      ),
                                      SizedBox(width: sw(8)),
                                      SizedBox(
                                        width: sw(300),
                                        child: Obx(() => Text(
                                          controller.dropoffLocation.value,
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: sh(65),
                            left: sw(280),
                            child: SizedBox(
                              width: sw(98),
                              height: sh(30),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFC107),
                                  padding: EdgeInsets.only(
                                    left: sw(4),
                                    right: sw(1)
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(sw(10)),
                                  ),
                                ),
                                onPressed:()=> Get.back(),
                                label: Text(
                                  "ADD STOPS",
                                  style: FTextTheme.lightTextTheme.labelSmall!
                                      .copyWith(
                                    fontSize:
                                    FTextTheme
                                        .lightTextTheme
                                        .labelSmall!
                                        .fontSize! *
                                        screenWidth /
                                        baseWidth,
                                  ),
                                ),
                                icon: SvgPicture.asset(
                                  "assets/images/add_stop_plus.svg",
                                  width: sw(15),
                                  height: sw(15),
                                  color: Colors.black,
                                ),
                                iconAlignment: IconAlignment.end,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ ADDED: Loading indicator while calculating fares
                  Obx(() => controller.isCalculatingFare.value
                      ? Positioned(
                    top: sh(200),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: sw(20), vertical: sh(10)),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(sw(20)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: sw(20),
                              height: sw(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: sw(10)),
                            Text(
                              'Calculating fares...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: sw(14),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      : SizedBox.shrink()),

                  // Bottom Body
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: screenWidth,
                      height: screenHeight - sh(466) + sh(31),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 16,
                            offset: Offset(0, -8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Obx(
                              () {
                            // ✅ ADDED: Show loading state if no ride options
                            if (controller.rideOptions.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: sh(16)),
                                    Text(
                                      'Loading ride options...',
                                      style: TextStyle(
                                        fontSize: sw(16),
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: sh(20)),
                                  ...controller.rideOptions.map(rideItem).toList(),
                                  SizedBox(height: sh(120)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Bottom Actions
                  Positioned(
                    bottom: sh(0),
                    // left: sw(5),
                    child: Container(
                      width: sw(440),
                      height: sh(132),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(sw(20)),
                          topRight: Radius.circular(sw(20)),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 16,
                            offset: Offset(0, -8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: sh(18),
                            left: sw(50),
                            child: SvgPicture.asset(
                              'assets/images/forward.svg',
                              width: sw(26.43),
                              height: sh(23.93),
                            ),
                          ),
                          Positioned(
                            top: sh(20),
                            left: 0,
                            right: sw(15),
                            child: Center(
                              child: Obx(() => Text( // ✅ WRAP WITH Obx
                                'Auto Accept offer that match fare Rs ${controller.autoAcceptFareDisplay}', // ✅ USE THE COMPUTED PROPERTY
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
                              )),
                            ),
                          ),
                          Positioned(
                            top: sh(1),
                            right: sw(29),
                            child: Obx(() => Transform.scale(
                              scale: 0.75,
                              child: Switch(
                                padding: EdgeInsets.zero,
                                activeColor: FColors.secondaryColor,
                                inactiveThumbColor: FColors.white,
                                inactiveTrackColor: FColors.secondaryColor,
                                activeTrackColor: FColors.primaryColor,
                                value: controller.autoAccept.value,
                                onChanged: controller.toggleAutoAccept,
                              ),
                            )),
                          ),
                          Positioned(
                            top: sh(55),
                            left: sw(77),
                            child: SizedBox(
                              width: sw(287),
                              height: sh(48),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003566),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(sw(14)),
                                  ),
                                ),
                                onPressed: () {
                                  // ✅ ADDED: Validation before API call
                                  if (controller.selectedRideType.value.isEmpty) {
                                    Get.snackbar(
                                      'Select Vehicle Type',
                                      'Please select a Vehicle type first',
                                      backgroundColor: Colors.orange,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }
                                  controller.onRequestRide();
                                },
                                child: Obx(() => controller.isRequestingRide.value
                                    ? SizedBox(
                                  width: sw(20),
                                  height: sw(20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : Text(
                                  'Request Ride',
                                  style: FTextTheme.darkTextTheme.titleSmall!.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: FTextTheme.lightTextTheme
                                        .titleSmall!.fontSize! *
                                        screenWidth /
                                        baseWidth,
                                  ),
                                )),
                              ),
                            ),
                          ),
                          Positioned(
                            top: sh(65),
                            right: sw(30),
                            child: InkWell(
                                borderRadius: BorderRadius.circular(sw(8)),
                                onTap: controller.isRequestingRide.value ? null : () {
                                  controller.openComments();
                                },
                                child: Opacity(
                                  opacity: controller.isRequestingRide.value ? 0.5 : 1.0,
                                  child: Image.asset("assets/images/comment.png"),
                                )
                            ),
                          ),
                          Positioned(
                            top: sh(50),
                            left: sw(10),
                            child: InkWell(
                              onTap: controller.isRequestingRide.value ? null : controller.openPaymentMethods,
                              child: Opacity(
                                opacity: controller.isRequestingRide.value ? 0.5 : 1.0,
                                child: Column(
                                  children: [
                                    Image.asset(
                                      "assets/images/cash.png",
                                      width: sw(30),
                                      height: sh(30),
                                    ),
                                    SizedBox(height: sh(1)),
                                    Obx(() => Text(
                                      _getPaymentText(controller.selectedPaymentLabel.value),
                                      style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                                        fontWeight: FontWeight.w400,
                                        fontSize: FTextTheme.lightTextTheme
                                            .labelSmall!.fontSize! *
                                            screenWidth /
                                            baseWidth,
                                      ),
                                    )),
                                  ],
                                ),
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

          // Overlay loading indicators - ONLY FOR API REQUEST
          Obx(() => controller.isRequestingRide.value
              ? _buildLoadingOverlay('Requesting ride...')
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}

String _getPaymentText(String method) {
  switch (method) {
    case "Cash Payment":
      return "cash";
    case "Easypaisa":
      return "easypaisa";
    case "JazzCash":
      return "jazzcash";
    case "Debit/Credit Card":
      return "card";
    case "DoorCabs Wallet":
      return "wallet";
    default:
      return "cash";
  }
}