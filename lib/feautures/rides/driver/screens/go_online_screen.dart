import 'package:doorcab/common/widgets/snakbar/snackbar.dart';
import 'package:doorcab/feautures/rides/driver/screens/reuseable_widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:slide_to_act/slide_to_act.dart';
import '../controllers/go_online_controller.dart';

class GoOnlineScreen extends StatelessWidget {
  final GoOnlineController controller = Get.put(GoOnlineController());

  GoOnlineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      key: controller.scaffoldKey,
      drawer: DriverDrawer(),
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            /// Google Map with Current Location
            Obx(() {
              if (controller.isLoadingLocation.value) {
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: const Color(0xFF003566),
                          strokeWidth: sw(2),
                        ),
                        SizedBox(height: sh(16)),
                        Text(
                          'Getting your location...',
                          style: TextStyle(
                            fontSize: sw(16),
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (controller.currentPosition.value != null) {
                return GoogleMap(
                  onMapCreated: controller.onMapCreated,
                  onCameraMove: controller.onCameraMove,
                  initialCameraPosition: CameraPosition(
                    target: controller.currentPosition.value!,
                    zoom: 15.0,
                  ),
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                  onTap: controller.onMapTap, // ADD THIS for tap functionality
                  markers: {
                    // Current location marker
                    Marker(
                      markerId: const MarkerId('current_location'),
                      position: controller.currentPosition.value!,
                      icon: controller.customMarker ?? BitmapDescriptor.defaultMarker,
                      infoWindow: const InfoWindow(title: 'Your Location'),
                    ),
                    // Add flag markers
                    ...controller.markers, // ADD THIS to show flag markers
                  },
                );
              }

              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: sw(48),
                        color: Colors.grey,
                      ),
                      SizedBox(height: sh(16)),
                      Text(
                        'Unable to get location',
                        style: TextStyle(
                          fontSize: sw(16),
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: sh(8)),
                      ElevatedButton(
                        onPressed: () => controller.getCurrentLocation(),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }),

            /// Back Arrow (SVG)
            Positioned(
              top: sh(80),
              left: sw(33),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: SvgPicture.asset(
                  "assets/images/Arrow.svg",
                  width: sw(28),
                  height: sh(28),
                ),
              ),
            ),

            /// Center Status Container
            Positioned(
              top: sh(65),
              left: 0,
              right: 0,
              child: Center(
                child: Obx(
                      () => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sw(14),
                      vertical: sh(8),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(sw(53)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: sw(4),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          controller.isOnline.value
                              ? "assets/images/openeye.svg"
                              : "assets/images/cleye.svg",
                          width: sw(20),
                          height: sh(20),
                        ),
                        SizedBox(width: sw(6)),
                        Text(
                          controller.isOnline.value ? "PKR 000" : "PKR 500",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w600,
                            fontSize: sw(16),
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            /// Menu Icon
            Positioned(
              top: sh(55),
              left: sw(382),
              child: GestureDetector(
                onTap: () {
                  controller.scaffoldKey.currentState?.openDrawer();
                },
                child: Container(
                  width: sw(39),
                  height: sh(39),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(sw(8)),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      "assets/images/Menu.svg",
                      width: sw(40),
                      height: sh(40),
                    ),
                  ),
                ),
              ),
            ),

            /// Notification Icon with Badge
            Positioned(
              top: sh(100),
              left: sw(382),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: (){
                      FSnackbar.show(title: 'Notifications ', message: "Will add Notifications soon.");
                    },
                    child: Container(
                      width: sw(39),
                      height: sh(39),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(sw(8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: sw(4),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          "assets/images/notification.svg",
                          width: sw(21),
                          height: sh(26),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: sh(-5),
                    right: sw(-5),
                    child: Container(
                      padding: EdgeInsets.all(sw(4)),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: sw(10),
                        minHeight: sh(10),
                      ),
                      child: Center(
                        child: Text(
                          "3",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: sw(12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Locate Icon
            // Positioned(
            //   top: sh(205),
            //   right: sw(150),
            //   child: GestureDetector(
            //     onTap: () => controller.moveToCurrentLocation(),
            //     child: SizedBox(
            //       width: sw(39),
            //       height: sh(39),
            //       child: Center(
            //         child: SvgPicture.asset(
            //           "assets/images/locate.svg",
            //           width: sw(73),
            //           height: sh(88),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            /// Flag Icon
            Obx(
                  () => Positioned(
                top: controller.isOnline.value ? sh(465) : sh(515),
                right: sw(23),
                child: GestureDetector( // ADD GestureDetector
                  onTap: () => controller.toggleFlag(), // ADD onTap
                  child: Container(
                    width: sw(39),
                    height: sh(39),
                    decoration: BoxDecoration(
                      color: controller.isFlagSet.value
                          ? const Color(0xFFFFC300) // Yellow when active
                          : Colors.white, // White when inactive
                      borderRadius: BorderRadius.circular(sw(6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: sw(4),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        "assets/images/flag.svg",
                        width: sw(18),
                        height: sh(23.41),
                        color: controller.isFlagSet.value
                            ? Colors.white // White icon when active
                            : Colors.black, // Black icon when inactive
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// Move Icon
            Obx(
                  () => Positioned(
                top: controller.isOnline.value ? sh(510) : sh(560),
                right: sw(23),
                child: GestureDetector(
                  onTap: () => controller.centerMapLocation(),
                  child: Container(
                    width: sw(39),
                    height: sh(39),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(sw(6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: sw(4),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        "assets/images/move.svg",
                        width: sw(18),
                        height: sh(23.41),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// Compass Icon
            Obx(
                  () => Positioned(
                top: controller.isOnline.value ? sh(510) : sh(560),
                right: sw(390),
                child: GestureDetector(
                  onTap: () => controller.toggleCompass(),
                  child: Container(
                    width: sw(39),
                    height: sh(39),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(sw(6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: sw(4),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        "assets/images/compas.svg",
                        width: sw(24),
                        height: sh(24),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// Ride Time Bubbles
            // Positioned(
            //   top: sh(250),
            //   left: sw(100),
            //   child: _timeBubble("2 min", sw, sh),
            // ),
            // Positioned(
            //   top: sh(280),
            //   left: sw(200),
            //   child: _timeBubble("3 min", sw, sh),
            // ),
            // Positioned(
            //   top: sh(330),
            //   left: sw(60),
            //   child: _timeBubble("5 min", sw, sh),
            // ),

            /// Custom Bottom Navigation Bar - PUT THIS FIRST (under bottom sheet)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                width: screenWidth,
                height: sh(64),
                padding: EdgeInsets.symmetric(horizontal: sw(31)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: sw(10),
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBottomNavItem(
                      icon: "assets/images/bottom_car.svg",
                      label: "Requests List",
                      isActive: true,
                      sw: sw,
                      sh: sh,
                    ),
                    _buildBottomNavItem(
                      icon: "assets/images/bottom_sh.svg",
                      label: "Schedule Ride",
                      isActive: false,
                      sw: sw,
                      sh: sh,
                    ),
                    _buildBottomNavItem(
                      icon: "assets/images/bottom_perf.svg",
                      label: "Performance",
                      isActive: false,
                      sw: sw,
                      sh: sh,
                    ),
                    _buildBottomNavItem(
                      icon: "assets/images/bottom_wallet.svg",
                      label: "Wallet",
                      isActive: false,
                      sw: sw,
                      sh: sh,
                    ),
                  ],
                ),
              ),
            ),

            /// Bottom Sheet - PUT THIS LAST (above bottom nav bar) with GestureDetector
            Obx(() {
              return Positioned(
                bottom: sh(64), // Space for custom bottom nav bar
                left: 0,
                right: 0,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    // Add swipe gesture handling if needed
                    // You can implement custom swipe logic here
                  },
                  child: Container(
                    width: screenWidth,
                    height: controller.isOnline.value ? sh(330) : sh(280),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(sw(31)),
                        topRight: Radius.circular(sw(31)),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView( // ADD THIS for scrollable content
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: sw(24),
                          vertical: sh(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Top drag handle
                            Center(
                              child: Container(
                                width: sw(25),
                                height: sh(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(sw(6)),
                                ),
                              ),
                            ),

                            SizedBox(height: sh(10)),

                            /// Online / Offline text
                            controller.isOnline.value
                                ? Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(left: sw(6)),
                              padding: EdgeInsets.symmetric(
                                horizontal: sw(16),
                                vertical: sh(10),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F2),
                                borderRadius: BorderRadius.circular(sw(14)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "You're Online",
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontWeight: FontWeight.w700,
                                      fontSize: sw(18),
                                    ),
                                  ),
                                  SizedBox(height: sh(2)),
                                  Text(
                                    "We're looking for rides.",
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontWeight: FontWeight.w500,
                                      fontSize: sw(16),
                                      color: const Color(0xFF595959),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : Text(
                              "2 to 5 min wait in your area",
                              style: TextStyle(
                                fontSize: sw(18),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF595959),
                              ),
                            ),

                            SizedBox(height: sh(12)),

                            /// Second block
                            controller.isOnline.value
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/cup.svg',
                                      width: sw(30),
                                      height: sh(30),
                                    ),
                                    SizedBox(width: sw(8)),
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Unlock Your Next Tasks",
                                          style: TextStyle(
                                            fontFamily: "Poppins",
                                            fontWeight: FontWeight.w500,
                                            fontSize: sw(18),
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: sh(2)),
                                        Text(
                                          "70/100 Point",
                                          style: TextStyle(
                                            fontFamily: "Poppins",
                                            fontWeight: FontWeight.w500,
                                            fontSize: sw(16),
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  "until 20/30",
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontWeight: FontWeight.w500,
                                    fontSize: sw(16),
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            )
                                : Text(
                              "Average wait for 20 rides over the last hour",
                              style: TextStyle(
                                fontSize: sw(16),
                                color: Colors.black54,
                              ),
                            ),

                            SizedBox(height: sh(12)),
                            Divider(height: sh(1), thickness: sh(1)),
                            SizedBox(height: sh(12)),

                            /// Grey Card (Goals / Offline Card)
                            controller.isOnline.value
                                ? SizedBox(
                              height: sh(70),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: sh(5),
                                    left: sw(5),
                                    child: SvgPicture.asset(
                                      'assets/images/goals.svg',
                                      width: sw(30),
                                      height: sh(30),
                                    ),
                                  ),
                                  Positioned(
                                    left: sw(50),
                                    child: Text(
                                      "Earnings Goal",
                                      style: TextStyle(
                                        fontFamily: "Poppins",
                                        fontWeight: FontWeight.w500,
                                        fontSize: sw(18),
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: sh(25),
                                    left: sw(50),
                                    child: Text(
                                      "1000/5000",
                                      style: TextStyle(
                                        fontFamily: "Poppins",
                                        fontWeight: FontWeight.w500,
                                        fontSize: sw(16),
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: sh(10),
                                    right: sw(10),
                                    child: Text(
                                      "Ends Sunday",
                                      style: TextStyle(
                                        fontFamily: "Poppins",
                                        fontWeight: FontWeight.w500,
                                        fontSize: sw(16),
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(left: sw(6)),
                              padding: EdgeInsets.symmetric(
                                horizontal: sw(16),
                                vertical: sh(10),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F2),
                                borderRadius: BorderRadius.circular(sw(14)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "You're Offline",
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontWeight: FontWeight.w600,
                                      fontSize: sw(16),
                                    ),
                                  ),
                                  SizedBox(height: sh(4)),
                                  Text(
                                    "Switch online to receive rides.",
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontWeight: FontWeight.w400,
                                      fontSize: sw(13),
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: sh(12)),

                            /// Go Online Button + Filter
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding:
                                    controller.isOnline.value
                                        ? EdgeInsets.only(top: sh(0))
                                        : EdgeInsets.only(top: sh(30)),
                                    child: SizedBox(
                                      height: sh(48),
                                      child: SlideAction(
                                        outerColor:
                                        controller.isOnline.value
                                            ? const Color(0xFFFFC300)
                                            : const Color(0xFF003566),
                                        innerColor: Colors.transparent,
                                        text:
                                        controller.isOnline.value
                                            ? "Go Offline"
                                            : "Go Online",
                                        textStyle: TextStyle(
                                          fontFamily: "Poppins",
                                          fontWeight: FontWeight.w700,
                                          fontSize: sw(18),
                                          color: Colors.white,
                                        ),
                                        elevation: 0,
                                        borderRadius: sw(14),
                                        sliderButtonIcon: SvgPicture.asset(
                                          "assets/images/go.svg",
                                          width: sw(22),
                                          height: sh(22),
                                          color:
                                          controller.isOnline.value
                                              ? const Color(0xFF003566)
                                              : Colors.white,
                                        ),
                                        onSubmit: () async {
                                          controller.toggleOnline();
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding:
                                  controller.isOnline.value
                                      ? EdgeInsets.only(
                                    top: sh(0),
                                    left: sw(20),
                                  )
                                      : EdgeInsets.only(
                                    top: sh(28),
                                    left: sw(20),
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      // handle filter tap
                                      FSnackbar.show(title: 'Filter ', message: "Will add filters soon.");
                                    },
                                    child: SvgPicture.asset(
                                      "assets/images/filter.svg",
                                      width: sw(41),
                                      height: sh(41),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: sh(10)), // Extra space at bottom
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Time bubble widget
  Widget _timeBubble(
      String text,
      double Function(double) sw,
      double Function(double) sh,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sw(10), vertical: sh(6)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: sw(4),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: sw(14)),
      ),
    );
  }

  /// Bottom Navigation Item Widget
  Widget _buildBottomNavItem({
    required String icon,
    required String label,
    required bool isActive,
    required double Function(double) sw,
    required double Function(double) sh,
  }) {
    return GestureDetector(
      onTap: () {
        // Add navigation logic here
        if (label == "Requests List") {
          // Get.to(() => RequestsListScreen());
        } else if (label == "Schedule Ride") {
          // Get.to(() => ScheduleRideScreen());
        } else if (label == "Performance") {
          // Get.to(() => PerformanceScreen());
        } else if (label == "Wallet") {
          // Get.to(() => WalletScreen());
        }
      },
      child: Container(
        width: sw(71),
        height: sh(45),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: sw(24),
              height: sh(24),
              color: isActive ? const Color(0xFF003566) : Colors.grey,
            ),
            SizedBox(height: sh(4)),
            Text(
              label,
              style: TextStyle(
                fontSize: sw(10),
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF003566) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
