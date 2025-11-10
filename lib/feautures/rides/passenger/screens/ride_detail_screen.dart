import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/ride_details_controller.dart';
import '../models/ride_detail_model.dart';
import '../models/ride_model.dart';
import 'package:flutter_svg/svg.dart';

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

    // Base reference (iPhone 16 Pro Max)
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

        return Stack(
          children: [
            // Google Map
            Obx(() => GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  controller.rideDetails.value?.pickupLat ?? 31.4765,
                  controller.rideDetails.value?.pickupLng ?? 74.3070,
                ),
                zoom: 13,
              ),
              markers: controller.markers.value,
              polylines: controller.polylines.value,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
            )),

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
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(sw(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: sw(420),
                        margin: EdgeInsets.symmetric(vertical: sh(10)),
                        padding: EdgeInsets.symmetric(
                            horizontal: sw(15), vertical: sh(10)),
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
                                SvgPicture.asset("assets/images/circle.svg",
                                    width: sw(16), height: sh(16)),
                                SizedBox(width: sw(8)),
                                Expanded(
                                  child: Text(
                                    rideDetails.location,
                                    style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! *
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
                                SvgPicture.asset("assets/images/locate.svg",
                                    width: sw(16), height: sh(16)),
                                SizedBox(width: sw(5)),
                                Expanded(
                                  child: Text(
                                    rideDetails.dropLocation,
                                    style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! *
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
                      Text(
                        "Details",
                        style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                          fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                              screenWidth /
                              baseWidth,
                        ),
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
                                  child: rideDetails.driverProfilePic.isNotEmpty
                                      ? (rideDetails.driverProfilePic.startsWith("http")
                                      ? Image.network(
                                    rideDetails.driverProfilePic,
                                    width: sw(70),
                                    height: sh(70),
                                    fit: BoxFit.cover,
                                  )
                                      : Image.asset(
                                    rideDetails.driverProfilePic,
                                    width: sw(70),
                                    height: sh(70),
                                    fit: BoxFit.cover,
                                  ))
                                      : Icon(Icons.person, size: sw(60)),
                                ),
                                SizedBox(height: sh(8)),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: sw(16)),
                                    SizedBox(width: sw(4)),
                                    Text(
                                      "${rideDetails.driverRating} (${rideDetails.totalrides} rides)",
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
                                  "Platinum driver",
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
                                  /// Driver name
                                  Text(
                                    rideDetails.driverName,
                                    style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                                          screenWidth /
                                          baseWidth,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: sh(4)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${rideDetails.carModel}  ",
                                          style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                                            fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! *
                                                screenWidth /
                                                baseWidth,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        rideDetails.licensePlate,
                                        style: FTextTheme.lightTextTheme.labelLarge!.copyWith(
                                          fontSize: FTextTheme.lightTextTheme.labelLarge!.fontSize! *
                                              screenWidth /
                                              baseWidth,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: sh(3)),
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
                                        rideDetails.arrivalTime,
                                        style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                                          fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! *
                                              screenWidth /
                                              baseWidth,
                                        ),
                                      ),
                                    ],
                                  ),
                                  /// Drop Time
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
                                        rideDetails.dropTime,
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
                      SizedBox(height: sh(8)),
                      Text(
                        "Price",
                        style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                          fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                              screenWidth /
                              baseWidth,
                        ),
                      ),
                      SizedBox(height: sh(2)),
                      _priceCard(rideDetails, context, sw, sh, screenWidth, baseWidth),
                      SizedBox(height: sh(5)),
                      _actionButtonsCard(context, sw, sh, screenWidth, baseWidth),
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
      RideDetailModel details,
      BuildContext context,
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return Container(
      width: double.infinity,
      height: sh(215),
      padding: EdgeInsets.all(sw(16)),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(227, 227, 227, 1),
        borderRadius: BorderRadius.circular(sw(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _priceRow("Ride Price", "PKR ${details.ridePrice.toInt()}", context, sw, sh, screenWidth, baseWidth),
            Divider(thickness: sh(1), color: Colors.black12),
            _priceRow("Promo Amount", "PKR ${details.promoAmount.toInt()}", context, sw, sh, screenWidth, baseWidth, isPromo: true),
            Divider(thickness: sh(1), color: Colors.black12),
            _priceRow("Total", "PKR ${details.totalFare.toInt()}", context, sw, sh, screenWidth, baseWidth, isTotal: true),
            SizedBox(height: sh(8)),
            _paymentMethod(details.paymentMethod, context, sw, sh, screenWidth, baseWidth),
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
        bool isTotal = false
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? FTextTheme.lightTextTheme.titleSmall!.copyWith(
            fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! *
                screenWidth /
                baseWidth,
          )
              : FTextTheme.lightTextTheme.bodySmall!.copyWith(
            fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! *
                screenWidth /
                baseWidth,
          ),
        ),
        Text(
          value,
          style: isTotal
              ? FTextTheme.lightTextTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
                screenWidth /
                baseWidth,
          )
              : FTextTheme.lightTextTheme.labelLarge!.copyWith(
            fontSize: FTextTheme.lightTextTheme.labelLarge!.fontSize! *
                screenWidth /
                baseWidth,
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
      // height: sh(40),
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
              method,
              style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! *
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
        "icon": SvgPicture.asset("assets/images/email.svg", width: sw(22), height: sh(22)),
        "confirmColor": const Color.fromRGBO(255, 195, 0, 1),
        "confirmTextColor": Colors.black,
      },
      {
        "label": "Delete Record",
        "icon": SvgPicture.asset("assets/images/delete.svg", width: sw(22), height: sh(22)),
        "confirmColor": Colors.red,
        "confirmTextColor": Colors.white,
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(vertical: sh(10)),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(227, 227, 227, 1),
        borderRadius: BorderRadius.circular(sw(20)),
        border: Border.all(color: Colors.grey.shade300, width: sw(1)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: sw(6), offset: Offset(0, sh(3))),
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
                    title: button["label"] as String == "Send report to email"
                        ? "Send Report to Email?"
                        : "Delete this Record?",
                    confirmText: button["label"] as String == "Send report to email" ? "Send" : "Delete",
                    confirmColor: button["confirmColor"] as Color,
                    confirmTextColor: button["confirmTextColor"] as Color,
                    sw: sw,
                    sh: sh,
                    screenWidth: screenWidth,
                    baseWidth: baseWidth,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: sw(15), vertical: sh(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          button["icon"] as Widget,
                          SizedBox(width: sw(10)),
                          Text(
                            button["label"] as String,
                            style: FTextTheme.lightTextTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              fontSize: FTextTheme.lightTextTheme.bodyMedium!.fontSize! *
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw(20))),
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
                        fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! *
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
                          if (confirmText == "Send") {
                            // Get.to(() => const HelpScreen());
                          }
                          debugPrint('$confirmText pressed');
                        },
                        child: Text(
                          confirmText,
                          style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: confirmTextColor,
                            fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! *
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
                          backgroundColor: const Color.fromRGBO(227, 227, 227, 1),
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
                            fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! *
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
}