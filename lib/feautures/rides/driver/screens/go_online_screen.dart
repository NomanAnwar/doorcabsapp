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

    // Create bottom navigation bar items with proper scaling
    List<BottomNavigationBarItem> bottomNavItems() {
      final double iconSize = sw(24);
      return [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            "assets/images/bottom_car.svg",
            width: iconSize,
            height: iconSize,
          ),
          activeIcon: SvgPicture.asset(
            "assets/images/bottom_car.svg",
            width: iconSize,
            height: iconSize,
            color: const Color(0xFF003566),
          ),
          label: "Requests List",
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: () {
              // Get.to(() => NewRideView());
            },
            child: SvgPicture.asset(
              "assets/images/bottom_sh.svg",
              width: iconSize,
              height: iconSize,
              color: Colors.grey,
            ),
          ),
          activeIcon: GestureDetector(
            onTap: () {
              // Get.to(() => NewRideView());
            },
            child: SvgPicture.asset(
              "assets/images/bottom_sh.svg",
              width: iconSize,
              height: iconSize,
              color: const Color(0xFF003566),
            ),
          ),
          label: "Schedule Ride",
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            "assets/images/bottom_perf.svg",
            width: iconSize,
            height: iconSize,
            color: Colors.grey,
          ),
          activeIcon: SvgPicture.asset(
            "assets/images/bottom_perf.svg",
            width: iconSize,
            height: iconSize,
            color: const Color(0xFF003566),
          ),
          label: "Performance",
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            "assets/images/bottom_wallet.svg",
            width: iconSize,
            height: iconSize,
            color: Colors.grey,
          ),
          activeIcon: SvgPicture.asset(
            "assets/images/bottom_wallet.svg",
            width: iconSize,
            height: iconSize,
            color: const Color(0xFF003566),
          ),
          label: "Wallet",
        ),
      ];
    }

    return Scaffold(
      key: controller.scaffoldKey,
      drawer: DriverDrawer(),
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            /// Google Map with Current Location
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

              // If we have current location, show map with custom marker
              if (controller.currentPosition.value != null) {
                return GoogleMap(
                  onMapCreated: controller.onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: controller.currentPosition.value!,
                    zoom: 15.0,
                  ),
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                  // ✅ NO BLUE DOT
                  markers: {
                    Marker(
                      markerId: const MarkerId('current_location'),
                      position: controller.currentPosition.value!,
                      icon:
                          controller.customMarker ??
                          BitmapDescriptor.defaultMarker,
                      infoWindow: const InfoWindow(title: 'Your Location'),
                    ),
                  },
                );
              }

              // If no location available, show error state
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
                          controller.isOnline.value ? "PKR" : "PKR 500",
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
                  // Notification Icon Container
                  Container(
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

                  // Red Badge
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

            /// Locate Icon - Updated to move to current location
            Positioned(
              top: sh(205),
              right: sw(150),
              child: GestureDetector(
                onTap: () => controller.moveToCurrentLocation(),
                child: SizedBox(
                  width: sw(39),
                  height: sh(39),
                  child: Center(
                    child: SvgPicture.asset(
                      "assets/images/locate.svg",
                      width: sw(73),
                      height: sh(88),
                    ),
                  ),
                ),
              ),
            ),

            /// Flag Icon
            Obx(
              () => Positioned(
                top: controller.isOnline.value ? sh(435) : sh(480),
                right: sw(23),
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
                      "assets/images/flag.svg",
                      width: sw(18),
                      height: sh(23.41),
                    ),
                  ),
                ),
              ),
            ),

            /// Move Icon
            Obx(
              () => Positioned(
                top: controller.isOnline.value ? sh(480) : sh(525),
                right: sw(23),
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

            /// Compass Icon
            Obx(
              () => Positioned(
                top: controller.isOnline.value ? sh(470) : sh(525),
                right: sw(390),
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

            /// Ride Time Bubbles
            Positioned(
              top: sh(250),
              left: sw(100),
              child: _timeBubble("2 min", sw, sh),
            ),
            Positioned(
              top: sh(280),
              left: sw(200),
              child: _timeBubble("3 min", sw, sh),
            ),
            Positioned(
              top: sh(330),
              left: sw(60),
              child: _timeBubble("5 min", sw, sh),
            ),

            /// Bottom Sheet
            Obx(() {
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
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

                        /// Go Online Button + Filter
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Slide button - takes available space
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

                            // Filter icon - fixed width with reduced spacing
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
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),

      /// Bottom Nav Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF003566),
        unselectedItemColor: Colors.grey,
        items: bottomNavItems(),
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
}
