import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/ride_details_controller.dart';
import '../models/ride_model.dart';

class RideDetailScreen extends StatelessWidget {
  final RideDetailController controller = Get.put(RideDetailController());

  RideDetailScreen({super.key}) {
    // Get ride data from arguments
    final ride = Get.arguments as RideModel?;
    if (ride != null) {
      controller.getRideDetails(ride);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      body: Obx(() {
        final rideDetails = controller.rideDetails.value;
        if (rideDetails == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final otherUserInfo = controller.getOtherUserInfo();

        return Stack(
          children: [
            // Google Map
            Positioned(
              top: sh(0),
              left: sw(0),
              right: sw(0),
              height: sh(350),
              child: Obx(() {
                final rideDetails = controller.rideDetails.value;

                // if (rideDetails == null) {
                //   return _buildMapPlaceholder('Loading ride details...', sw, sh);
                // }

                return Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          rideDetails!.pickupLocation.lat,
                          rideDetails.pickupLocation.lng,
                        ),
                        zoom: 14,
                      ),
                      markers: controller.markers.value,
                      polylines: controller.polylines.value,
                      myLocationEnabled: false,
                      zoomControlsEnabled: false,
                      onMapCreated: controller.onMapCreated,
                    ),

                    // Loading overlay for route
                    if (!controller.routeLoaded.value)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: FColors.primaryColor,
                              ),
                              SizedBox(height: sh(16)),
                              Text(
                                'Calculating route...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: sw(16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),

            // Back Button
            Positioned(
              top: sh(39),
              left: sw(33),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: IconButton(
                  icon: SvgPicture.asset(
                    "assets/images/Arrow.svg",
                    width: sw(28),
                    height: sh(20),
                  ),
                  onPressed: () => Get.back(),
                ),
              ),
            ),

            // Bottom Sheet
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: sh(650),
                decoration: const BoxDecoration(color: Colors.white),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(sw(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: sw(420),
                        margin: EdgeInsets.symmetric(vertical: sh(10)),
                        padding: EdgeInsets.symmetric(
                          horizontal: sw(15),
                          vertical: sh(10),
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(227, 227, 227, 1),
                          borderRadius: BorderRadius.circular(sw(14)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/images/circle.svg",
                                  width: sw(16),
                                  height: sh(16),
                                ),
                                SizedBox(width: sw(8)),
                                Expanded(
                                  child: Text(
                                    rideDetails.location,
                                    style: FTextTheme.lightTextTheme.bodyLarge!
                                        .copyWith(
                                          fontWeight: FontWeight.w400,
                                          fontSize:
                                              FTextTheme
                                                  .lightTextTheme
                                                  .bodyLarge!
                                                  .fontSize! *
                                              screenWidth /
                                              baseWidth,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: sh(6)),
                            Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/images/locate.svg",
                                  width: sw(16),
                                  height: sh(16),
                                ),
                                SizedBox(width: sw(5)),
                                Expanded(
                                  child: Text(
                                    rideDetails.firstDropoffAddress,
                                    style: FTextTheme.lightTextTheme.bodyLarge!
                                        .copyWith(
                                          fontWeight: FontWeight.w400,
                                          fontSize:
                                              FTextTheme
                                                  .lightTextTheme
                                                  .bodyLarge!
                                                  .fontSize! *
                                              screenWidth /
                                              baseWidth,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: sh(1)),
                      // Text(
                      //   "Details",
                      //   style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                      //     fontSize:
                      //         FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                      //         screenWidth /
                      //         baseWidth,
                      //   ),
                      // ),
                      // ✅ ADDED: Cancel Status and Details Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Details",
                            style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                              fontSize:
                              FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                                  screenWidth /
                                  baseWidth,
                            ),
                          ),

                          // ✅ ADDED: Cancel Status Tag
                          if (rideDetails.status.toLowerCase() == 'cancelled' ||
                              rideDetails.status.toLowerCase() == 'canceled')
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: sw(12),
                                vertical: sh(6),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(sw(20)),
                                border: Border.all(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "Cancelled",
                                style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                                  color: Colors.red,
                                  fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                                      screenWidth /
                                      baseWidth,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: sh(1)),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(sw(16)),
                        decoration: BoxDecoration(
                          color: FColors.white,
                          borderRadius: BorderRadius.circular(sw(20)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(sw(50)),
                                  child: otherUserInfo['profileImage']?.isNotEmpty == true
                                      ? (otherUserInfo['profileImage'].startsWith("http")
                                      ? Image.network(
                                    otherUserInfo['profileImage'],
                                    width: sw(70),
                                    height: sh(70),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(sw, sh),
                                  )
                                      : Image.asset(
                                    otherUserInfo['profileImage'],
                                    width: sw(70),
                                    height: sh(70),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(sw, sh),
                                  ))
                                      : _buildDefaultAvatar(sw, sh),
                                ),
                                SizedBox(height: sh(8)),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: sw(16),
                                    ),
                                    SizedBox(width: sw(4)),
                                    Text(
                                      "${otherUserInfo['rating']?.toStringAsFixed(1) ?? '0.0'} (${otherUserInfo['total_rides'] ?? 0} ${rideDetails.isDriverRole ? 'rides' : 'ratings'})",
                                      style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                                        fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                                            screenWidth /
                                            baseWidth,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: sh(2)),
                                Text(
                                  "${otherUserInfo['role'] ?? 'User'}",
                                  style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                                    color: Colors.grey,
                                    fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                                        screenWidth /
                                        baseWidth,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: sw(10)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    otherUserInfo['name'] ?? 'Unknown',
                                    style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                                          screenWidth /
                                          baseWidth,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: sh(4)),

                                  // Vehicle Info
                                  if (otherUserInfo['vehicle'] != null && otherUserInfo['vehicle']!.isNotEmpty)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            otherUserInfo['vehicle']!,
                                            style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                                              fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! *
                                                  screenWidth /
                                                  baseWidth,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (otherUserInfo['license_plate'] != null && otherUserInfo['license_plate']!.isNotEmpty)
                                          Text(
                                            otherUserInfo['license_plate']!,
                                            style: FTextTheme.lightTextTheme.labelLarge!.copyWith(
                                              fontSize: FTextTheme.lightTextTheme.labelLarge!.fontSize! *
                                                  screenWidth /
                                                  baseWidth,
                                            ),
                                          ),
                                      ],
                                    ),

                                  // Badge/Role
                                  if (otherUserInfo['badge'] != null && otherUserInfo['badge']!.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: sh(2)),
                                      child: Text(
                                        otherUserInfo['badge']!,
                                        style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                                          color: FColors.primaryColor,
                                          fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                                              screenWidth /
                                              baseWidth,
                                        ),
                                      ),
                                    ),

                                  SizedBox(height: sh(3)),

                                  // Arrival Time
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Arrival Time",
                                        style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                                          fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                                              screenWidth /
                                              baseWidth,
                                        ),
                                      ),
                                      Text(
                                        controller.getFormattedArrivalTime(),
                                        style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                                          fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! *
                                              screenWidth /
                                              baseWidth,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Drop Time
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Drop Time",
                                        style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                                          fontSize: FTextTheme.lightTextTheme.labelSmall!.fontSize! *
                                              screenWidth /
                                              baseWidth,
                                        ),
                                      ),
                                      Text(
                                        controller.getFormattedDropTime(),
                                        style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                                          fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! *
                                              screenWidth /
                                              baseWidth,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: sh(2)),
                      Text(
                        "Price",
                        style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                          fontSize:
                              FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                              screenWidth /
                              baseWidth,
                        ),
                      ),
                      SizedBox(height: sh(2)),
                      _priceCard(
                        rideDetails,
                        context,
                        sw,
                        sh,
                        screenWidth,
                        baseWidth,
                      ),
                      SizedBox(height: sh(5)),
                      _actionButtonsCard(
                        context,
                        sw,
                        sh,
                        screenWidth,
                        baseWidth,
                      ),

                      // ✅ ADDED: Submit Complaint Button
                      SizedBox(height: sh(15)),

                      Obx(() {
                        if (controller.shouldShowComplaintButton)
                          return Column(
                            children: [
                              SizedBox(height: sh(15)),
                              GestureDetector(
                                onTap: () => controller.navigateToSubmitComplaint(),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: sh(16)),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A2C4B),
                                    borderRadius: BorderRadius.circular(sw(10)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Submit New Complaint",
                                      style: TextStyle(
                                        fontFamily: "Plus Jakarta Sans",
                                        fontWeight: FontWeight.w500,
                                        fontSize: sw(16),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        else
                          return SizedBox.shrink();
                      }),

                      // GestureDetector(
                      //   onTap: () => controller.navigateToSubmitComplaint(),
                      //   child: Container(
                      //     width: double.infinity,
                      //     padding: EdgeInsets.symmetric(vertical: sh(16)),
                      //     decoration: BoxDecoration(
                      //       color: const Color(0xFF0A2C4B),
                      //       borderRadius: BorderRadius.circular(sw(10)),
                      //     ),
                      //     child: Center(
                      //       child: Text(
                      //         "Submit New Complaint",
                      //         style: TextStyle(
                      //           fontFamily: "Plus Jakarta Sans",
                      //           fontWeight: FontWeight.w500,
                      //           fontSize: sw(16),
                      //           color: Colors.white,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Price Card
  Widget _priceCard(
    RideModel details,
    BuildContext context,
    double Function(double) sw,
    double Function(double) sh,
    double screenWidth,
    double baseWidth,
  ) {
    return Container(
      width: double.infinity,
      height: sh(175),
      padding: EdgeInsets.all(sw(16)),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(227, 227, 227, 1),
        borderRadius: BorderRadius.circular(sw(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _priceRow(
              "Ride Price",
              "PKR ${details.acceptedPrice.toInt()}",
              context,
              sw,
              sh,
              screenWidth,
              baseWidth,
            ),
            // Divider(thickness: sh(1), color: Colors.black12),
            // _priceRow(
            //   "Distance Charges",
            //   "PKR ${details.fareDistance.toInt()}",
            //   context,
            //   sw,
            //   sh,
            //   screenWidth,
            //   baseWidth,
            // ),
            // Divider(thickness: sh(1), color: Colors.black12),
            // _priceRow(
            //   "Surge Charges",
            //   "PKR ${details.fareSurge.toInt()}",
            //   context,
            //   sw,
            //   sh,
            //   screenWidth,
            //   baseWidth,
            // ),
            if (details.fareWaitingCharge > 0) ...[
              Divider(thickness: sh(1), color: Colors.black12),
              _priceRow(
                "Waiting Charges",
                "PKR ${details.fareWaitingCharge.toInt()}",
                context,
                sw,
                sh,
                screenWidth,
                baseWidth,
              ),
            ],
            if (details.fareDiscount > 0) ...[
              Divider(thickness: sh(1), color: Colors.black12),
              _priceRow(
                "Discount",
                "-PKR ${details.fareDiscount.toInt()}",
                context,
                sw,
                sh,
                screenWidth,
                baseWidth,
                isPromo: true,
              ),
            ],
            Divider(thickness: sh(1), color: Colors.black12),
            _priceRow(
              "Total",
              "PKR ${details.totalFare.toInt()}",
              context,
              sw,
              sh,
              screenWidth,
              baseWidth,
              isTotal: true,
            ),
            SizedBox(height: sh(8)),
            _paymentMethod(
              details.paymentType,
              context,
              sw,
              sh,
              screenWidth,
              baseWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value,
    BuildContext context,
    double Function(double) sw,
    double Function(double) sh,
    double screenWidth,
    double baseWidth, {
    bool isPromo = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              isTotal
                  ? FTextTheme.lightTextTheme.titleSmall!.copyWith(
                    fontSize:
                        FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                  )
                  : FTextTheme.lightTextTheme.bodySmall!.copyWith(
                    fontSize:
                        FTextTheme.lightTextTheme.bodySmall!.fontSize! *
                        screenWidth /
                        baseWidth,
                  ),
        ),
        Text(
          value,
          style:
              isTotal
                  ? FTextTheme.lightTextTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                        screenWidth /
                        baseWidth,
                  )
                  : FTextTheme.lightTextTheme.labelLarge!.copyWith(
                    fontSize:
                        FTextTheme.lightTextTheme.labelLarge!.fontSize! *
                        screenWidth /
                        baseWidth,
                    color: isPromo ? Colors.red : Colors.black,
                  ),
        ),
      ],
    );
  }

  Widget _paymentMethod(
    String method,
    BuildContext context,
    double Function(double) sw,
    double Function(double) sh,
    double screenWidth,
    double baseWidth,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: sh(1)),
      padding: EdgeInsets.symmetric(horizontal: sw(16), vertical: sh(4)),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 195, 0, 0.37),
        borderRadius: BorderRadius.circular(sw(14)),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              method.toUpperCase(),
              style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize:
                    FTextTheme.lightTextTheme.bodySmall!.fontSize! *
                    screenWidth /
                    baseWidth,
              ),
            ),
          ),
          SvgPicture.asset(
            "assets/images/cash.svg",
            width: sw(42),
            height: sh(42),
          ),
        ],
      ),
    );
  }

  // Action button
  Widget _actionButtonsCard(
    BuildContext context,
    double Function(double) sw,
    double Function(double) sh,
    double screenWidth,
    double baseWidth,
  ) {
    final buttons = [
      {
        "label": "Send report to email",
        "icon": SvgPicture.asset(
          "assets/images/email.svg",
          width: sw(22),
          height: sh(22),
        ),
        "confirmColor": const Color.fromRGBO(255, 195, 0, 1),
        "confirmTextColor": Colors.black,
        "onConfirm": () => controller.sendRideReport(),
      },
      // {
      //   "label": "Delete Record",
      //   "icon": SvgPicture.asset(
      //     "assets/images/delete.svg",
      //     width: sw(22),
      //     height: sh(22),
      //   ),
      //   "confirmColor": Colors.red,
      //   "confirmTextColor": Colors.white,
      //   "onConfirm": () => print('Delete record'),
      // },
    ];

    return Container(
      margin: EdgeInsets.symmetric(vertical: sh(10)),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(227, 227, 227, 1),
        borderRadius: BorderRadius.circular(sw(20)),
        border: Border.all(color: Colors.grey.shade300, width: sw(1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: sw(6),
            offset: Offset(0, sh(3)),
          ),
        ],
      ),
      child: Column(
        children: List.generate(buttons.length, (index) {
          final button = buttons[index];
          return Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(sw(20)),
                onTap: () {
                  _showCustomDialog(
                    context,
                    title:
                        button["label"] as String == "Send report to email"
                            ? "Send Report to Email?"
                            : "Delete this Record?",
                    confirmText:
                        button["label"] as String == "Send report to email"
                            ? "Send"
                            : "Delete",
                    confirmColor: button["confirmColor"] as Color,
                    confirmTextColor: button["confirmTextColor"] as Color,
                    onConfirm: button["onConfirm"] as Function(),
                    sw: sw,
                    sh: sh,
                    screenWidth: screenWidth,
                    baseWidth: baseWidth,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: sw(15),
                    vertical: sh(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          button["icon"] as Widget,
                          SizedBox(width: sw(10)),
                          Text(
                            button["label"] as String,
                            style: FTextTheme.lightTextTheme.bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize:
                                      FTextTheme
                                          .lightTextTheme
                                          .bodyMedium!
                                          .fontSize! *
                                      screenWidth /
                                      baseWidth,
                                ),
                          ),
                        ],
                      ),
                      SvgPicture.asset(
                        "assets/images/Polygon.svg",
                        width: sw(16),
                        height: sh(16),
                      ),
                    ],
                  ),
                ),
              ),
              if (index != buttons.length - 1)
                Divider(color: Colors.grey.shade300, height: sh(1)),
            ],
          );
        }),
      ),
    );
  }

  void _showCustomDialog(
    BuildContext context, {
    required String title,
    required String confirmText,
    required Color confirmColor,
    required Color confirmTextColor,
    required Function onConfirm,
    required double Function(double) sw,
    required double Function(double) sh,
    required double screenWidth,
    required double baseWidth,
  }) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: sw(20)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sw(20)),
          ),
          backgroundColor: Colors.white,
          child: SafeArea(
            child: SizedBox(
              width: sw(408),
              height: sh(259),
              child: Padding(
                padding: EdgeInsets.all(sw(20)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: sh(10)),
                    Text(
                      title,
                      style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontSize:
                            FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                            screenWidth /
                            baseWidth,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: sh(52),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: confirmColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(sw(14)),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                        child: Text(
                          confirmText,
                          style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: confirmTextColor,
                            fontSize:
                                FTextTheme.lightTextTheme.bodyLarge!.fontSize! *
                                screenWidth /
                                baseWidth,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: sh(12)),
                    SizedBox(
                      width: double.infinity,
                      height: sh(52),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color.fromRGBO(
                            227,
                            227,
                            227,
                            1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(sw(14)),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          debugPrint('Dialog closed');
                        },
                        child: Text(
                          "Close",
                          style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            fontSize:
                                FTextTheme.lightTextTheme.bodyLarge!.fontSize! *
                                screenWidth /
                                baseWidth,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar(double Function(double) sw, double Function(double) sh) {
    return Container(
      width: sw(70),
      height: sh(70),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: sw(40),
        color: Colors.grey[600],
      ),
    );
  }

}



