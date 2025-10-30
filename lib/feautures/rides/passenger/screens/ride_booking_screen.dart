import 'package:doorcab/feautures/rides/driver/screens/reuseable_widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // ✅ ADDED: Bottom sheet controller for swipe functionality
    final DraggableScrollableController bottomSheetController = DraggableScrollableController();

    // ✅ ADDED: Observable for bottom sheet size
    final bottomSheetHeight = 0.45.obs;

    // ✅ ADDED: Listen to bottom sheet size changes
    bottomSheetController.addListener(() {
      bottomSheetHeight.value = bottomSheetController.size;
      // Notify controller about bottom sheet size change
      controller.updateBottomSheetSize(bottomSheetController.size);
    });

    // ✅ ADDED: Calculate dynamic map height based on bottom sheet position
    double getMapHeight() {
      final bottomSheetPixelHeight = screenHeight * bottomSheetHeight.value;
      final locationCardHeight = sh(0);
      // final locationCardHeight = sh(25);
      final bottomActionsHeight = sh(0) + MediaQuery.of(context).padding.bottom;
      // final bottomActionsHeight = sh(132) + MediaQuery.of(context).padding.bottom;

      final availableHeight = screenHeight - locationCardHeight - bottomSheetPixelHeight - bottomActionsHeight;
      final newHeight = availableHeight.clamp(sh(200), screenHeight);

      // ✅ Force camera update when height changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.mapController != null) {
          controller.refreshMapView();
        }
      });

      return newHeight;
    }

    // ✅ ADDED: Calculate map top position based on location card
    double getMapTop() {
      // return sh(50) + sh(106); // Location card top + location card height
      return sh(106); // Location card top + location card height
    }

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
              color: FColors.white,
              borderRadius: BorderRadius.circular(sw(14)),
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
                                // ✅ UPDATED: Use vehicle-specific duration
                                '${option.initialPassengers} passengers • ${controller.getVehicleDuration(option.id)}',
                                style: FTextTheme.lightTextTheme.labelSmall!
                                    .copyWith(
                                  fontSize: FTextTheme.lightTextTheme
                                      .labelSmall!.fontSize! *
                                      screenWidth /
                                      baseWidth,
                                ),
                                overflow: TextOverflow.ellipsis,
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
        height: sh(195),
        decoration: BoxDecoration(
          color: Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(sw(14)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => controller.selectRideType(option.id),
              child: Container(
                width: sw(400),
                height: sh(75),
                margin: EdgeInsets.all(sh(8)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(sw(14)),
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
                                SizedBox(width: sw(3)),
                                SvgPicture.asset(
                                  "assets/images/information.svg",
                                  width: sw(12),
                                  height: sh(12),
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
                                  // ✅ UPDATED: Use vehicle-specific duration
                                  '${option.initialPassengers} passengers • ${controller.getVehicleDuration(option.id)}',
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
                          // ✅ UPDATED: Passenger controls with animations
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
                                  // Decrement button
                                  Obx(() {
                                    final isDisabled = controller.isPassengerDecrementDisabled[option.id]?.value ?? true;
                                    return GestureDetector(
                                      onTap: isDisabled ? null : () => controller.decrementPassengers(option.id),
                                      child: Container(
                                        width: sw(20),
                                        height: sh(20),
                                        decoration: BoxDecoration(
                                          color: isDisabled ? Colors.grey[400] : Colors.grey,
                                          borderRadius: BorderRadius.circular(sw(10)),
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          size: sw(12),
                                          color: isDisabled ? Colors.grey[600] : Colors.black,
                                        ),
                                      ),
                                    );
                                  }),
                                  SizedBox(width: sw(6)),
                                  // ✅ UPDATED: Passenger count with animation
                                  Obx(() {
                                    final isAnimating = controller.passengerAnimations[option.id]?.value ?? false;
                                    return AnimatedContainer(
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      width: sw(27),
                                      height: sh(27),
                                      decoration: BoxDecoration(
                                        color: isAnimating ? FColors.primaryColor.withOpacity(0.1) : Colors.white,
                                        borderRadius: BorderRadius.circular(sw(10)),
                                        border: Border.all(
                                          color: isAnimating ? FColors.primaryColor : FColors.chipBg,
                                          width: isAnimating ? sw(2) : sw(1),
                                        ),
                                        boxShadow: isAnimating ? [
                                          BoxShadow(
                                            color: FColors.primaryColor.withOpacity(0.3),
                                            blurRadius: sw(8),
                                            spreadRadius: sw(1),
                                          )
                                        ] : [],
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
                                            color: isAnimating ? FColors.primaryColor : Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  SizedBox(width: sw(9)),
                                  // Increment button
                                  Obx(() {
                                    final isDisabled = controller.isPassengerIncrementDisabled[option.id]?.value ?? false;
                                    return GestureDetector(
                                      onTap: isDisabled ? null : () => controller.incrementPassengers(option.id),
                                      child: Container(
                                        width: sw(20),
                                        height: sw(20),
                                        decoration: BoxDecoration(
                                          color: isDisabled ? Colors.grey[400] : const Color.fromRGBO(0, 0, 0, 0.54),
                                          borderRadius: BorderRadius.circular(sw(20)),
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          size: sw(18),
                                          color: isDisabled ? Colors.grey[600] : Colors.black,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: sh(5)),
                          Divider(height: sh(0.5), thickness: sh(1), color: const Color(0xFF2B2D30)),
                          // ✅ UPDATED: Fare controls with animations
                          Row(
                            children: [
                              // Fare decrement button
                              Obx(() {
                                final isDisabled = controller.isFareDecrementDisabled[option.id]?.value ?? true;
                                return GestureDetector(
                                  onTap: isDisabled ? null : () => controller.decrementFare(option.id),
                                  child: Container(
                                    width: sw(35),
                                    height: sh(35),
                                    decoration: BoxDecoration(
                                      color: isDisabled ? Colors.grey[400] : Colors.grey[600],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: sw(20),
                                        height: sh(5),
                                        child: SvgPicture.asset(
                                          'assets/images/minus.svg',
                                          fit: BoxFit.contain,
                                          color: isDisabled ? Colors.grey[600] : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const Spacer(),
                              // ✅ UPDATED: Fare display with animation
                              Obx(() {
                                final isAnimating = controller.fareAnimations[option.id]?.value ?? false;
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: Column(
                                    children: [
                                      Text(
                                        'PKR ${fare.value}',
                                        style: FTextTheme.lightTextTheme.headlineMedium!
                                            .copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: FTextTheme.lightTextTheme
                                              .headlineMedium!.fontSize! *
                                              screenWidth /
                                              baseWidth,
                                          color: isAnimating ? FColors.primaryColor : Colors.black,
                                        ),
                                      ),
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
                                );
                              }),
                              const Spacer(),
                              // Fare increment button
                              Obx(() {
                                final isDisabled = controller.isFareIncrementDisabled[option.id]?.value ?? false;
                                return GestureDetector(
                                  onTap: isDisabled ? null : () => controller.incrementFare(option.id),
                                  child: Container(
                                    width: sw(35),
                                    height: sh(35),
                                    decoration: BoxDecoration(
                                      color: isDisabled ? Colors.grey[400] : const Color(0xFFFFC107),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: sw(20),
                                        height: sh(20),
                                        child: SvgPicture.asset(
                                          'assets/images/add_stop_plus.svg',
                                          fit: BoxFit.contain,
                                          color: isDisabled ? Colors.grey[600] : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
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
      // ✅ ADDED: Hide system navigation bar
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Stack(
          children: [
            // ✅ UPDATED: Dynamic Map Container that adjusts height based on bottom sheet
            Obx(() => Positioned(
              top: getMapTop(), // Start below location card
              left: 0,
              right: 0,
              height: getMapHeight(), // Dynamic height based on bottom sheet
              child: SizedBox(
                width: screenWidth,
                height: getMapHeight(),
                child: Stack(
                  children: [
                    // Google Map - Dynamic height
                    Positioned.fill(
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

                    // Back Arrow - Positioned relative to map container
                    Positioned(
                      top: sh(70), // Adjusted position within map container
                      left: sw(15),
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: sw(39),
                          height: sh(39),
                          decoration: BoxDecoration(
                            color: FColors.secondaryColor,
                            borderRadius: BorderRadius.circular(sw(20)),
                          ),
                          child: Icon(Icons.arrow_back, size: sw(30), color: FColors.white,),
                        ),
                      ),
                    ),

                    // ✅ ADDED: Loading indicator while calculating fares
                    Obx(() => controller.isCalculatingFare.value
                        ? Positioned(
                      top: sh(80),
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
                  ],
                ),
              ),
            )),

            // Location Card - Fixed position at top (UNCHANGED)
            Positioned(
              top: sh(60),
              left: sw(10),
              right: sw(10),
              child: Container(
                width: screenWidth,
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
                      left: sw(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
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
                                  width: screenWidth - 80,
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
                            width: screenWidth-50,
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
                                  width: screenWidth - 80,
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
                      top: sh(40),
                      right: sw(5),
                      child: SizedBox(
                        width: sw(35),
                        height: sh(35),
                        child: IconButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            padding: EdgeInsets.only(
                                left: sw(3),
                                right: sw(2)
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(sw(10)),
                            ),
                          ),
                          onPressed:()=> Get.back(),
                          icon: SvgPicture.asset(
                            "assets/images/add_stop_plus.svg",
                            width: sw(15),
                            height: sw(15),
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ UPDATED: Bottom sheet for ride options (swipeable) - UNCHANGED
            DraggableScrollableSheet(
              controller: bottomSheetController,
              initialChildSize: 0.45, // 45% of screen height initially
              minChildSize: 0.25, // Minimum 25% when collapsed
              maxChildSize: 0.75, // Maximum 75% when expanded
              snap: true,
              snapSizes: [0.45, 0.75],
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: FColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(sw(20)),
                      topRight: Radius.circular(sw(20)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: sw(16),
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: sw(40),
                        height: sh(4),
                        margin: EdgeInsets.only(top: sh(8)),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(sw(2)),
                        ),
                      ),
                      // Ride options list
                      Expanded(
                        child: Obx(
                              () {
                            // Show loading state if no ride options
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

                            return ListView(
                              controller: scrollController,
                              physics: ClampingScrollPhysics(),
                              children: [
                                ...controller.rideOptions.map(rideItem).toList(),
                                // SizedBox(height: sh(120)), // Space for bottom actions
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ✅ UPDATED: Bottom Actions - Fixed position above navigation bar - UNCHANGED
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                width: screenWidth,
                height: sh(132) + MediaQuery.of(context).padding.bottom, // Add safe area padding
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
                      left: sw(35),
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
                        child: Obx(() => Text(
                          'Auto Accept offer that match fare Rs ${controller.autoAcceptFareDisplay}',
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
                          onChanged: controller.onAutoAcceptToggle,
                        ),
                      )),
                    ),
                    // ✅ UPDATED: Request Ride button with proper disabled state
                    Positioned(
                      top: sh(55),
                      left: sw(77),
                      child: SizedBox(
                        width: sw(287),
                        height: sh(48),
                        child: Obx(() {
                          final isDisabled = controller.isRequestRideDisabled.value;
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDisabled ? Colors.grey[400] : const Color(0xFF003566),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(sw(14)),
                              ),
                            ),
                            onPressed: isDisabled ? null : () {
                              controller.onRequestRide();
                            },
                            child: controller.isRequestingRide.value
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
                                color: isDisabled ? Colors.grey[600] : Colors.white,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Positioned(
                      top: sh(65),
                      right: sw(30),
                      child: Obx(() {
                        final isDisabled = controller.isRequestingRide.value;
                        return InkWell(
                          borderRadius: BorderRadius.circular(sw(8)),
                          onTap: isDisabled ? null : () {
                            controller.openComments();
                          },
                          child: Opacity(
                            opacity: isDisabled ? 0.5 : 1.0,
                            child: Image.asset("assets/images/comment.png"),
                          ),
                        );
                      }),
                    ),
                    Positioned(
                      top: sh(55),
                      left: sw(12),
                      child: Obx(() {
                        final isDisabled = controller.isRequestingRide.value;
                        return InkWell(
                          onTap: isDisabled ? null : controller.openPaymentMethods,
                          child: Opacity(
                            opacity: isDisabled ? 0.5 : 1.0,
                            child: Column(
                              children: [
                                Image.asset(
                                  "assets/images/cash.png",
                                  width: sw(30),
                                  height: sh(30),
                                ),
                                SizedBox(height: sh(0)),
                                Obx(() => Text(
                                  _getPaymentText(controller.selectedPaymentLabel.value),
                                  style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: (FTextTheme.lightTextTheme
                                        .labelSmall!.fontSize!-1) *
                                        screenWidth /
                                        baseWidth,
                                  ),
                                )),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // Overlay loading indicators - ONLY FOR API REQUEST - UNCHANGED
            Obx(() => controller.isRequestingRide.value
                ? _buildLoadingOverlay('Requesting ride...')
                : const SizedBox.shrink()),
          ],
        ),
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