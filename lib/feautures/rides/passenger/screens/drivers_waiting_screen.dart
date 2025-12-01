import 'package:cached_network_image/cached_network_image.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../shared/screens/app_drawer.dart';
import '../../driver/screens/reuseable_widgets/drawer.dart';
import '../controllers/drivers_waiting_controller.dart';

class DriversWaitingScreen extends StatelessWidget {
  const DriversWaitingScreen({super.key});

  Future<void> _call(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Could not launch dialer");
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DriversWaitingController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      key: c.scaffoldKey,
      backgroundColor: Colors.white,
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: SizedBox(
          height: screenHeight,
          width: screenWidth,
          child: Obx(
                () => Stack(
              children: [
                /// Map background
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: c.updateView.value ? sh(450) : sh(510),
                  child: Obx(() {
                    if (c.currentPosition.value == null) {
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: sw(2),
                          color: FColors.secondaryColor,
                        ),
                      );
                    }

                    final initial = CameraPosition(
                      target: c.currentPosition.value ?? const LatLng(0, 0),
                      zoom: 14,
                    );

                    return GoogleMap(
                      initialCameraPosition: initial,
                      onMapCreated: c.onMapCreated,
                      markers: c.driverMarkers.values.toSet(),
                      polylines: c.polylines.toSet(),
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      trafficEnabled: false,
                      buildingsEnabled: true,
                      indoorViewEnabled: false,
                    );
                  }),
                ),

                Positioned(
                  top: c.updateView.value ? sh(280) : sh(340),
                  right: sw(16),
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    elevation: 4,
                    onPressed: () => c.recenterCamera(),
                    child: Icon(Icons.my_location, color: Colors.blueAccent),
                  ),
                ),

                /// Back button
                Positioned(
                  top: sh(23),
                  left: sw(23),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: sw(28),
                    ),
                    onPressed: () {},
                  ),
                ),

                // Menu Button
                Positioned(
                  top: sh(23),
                  right: sw(33),
                  child: GestureDetector(
                    onTap: () {
                      c.scaffoldKey.currentState?.openDrawer();
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

                // Queue Ride View Data start
                // Positioned(
                //   top: c.updateView.value ? sh(360) : sh(420),
                //   left: sw(20),
                //   right: sw(20),
                //   child: Container(
                //     width: sw(401),
                //     height: sh(83),
                //     decoration: BoxDecoration(
                //       color: FColors.secondaryColor,
                //       borderRadius: BorderRadius.circular(sw(14)),
                //     ),
                //   ),
                // ),
                //
                // Positioned(
                //   top: c.updateView.value ? sh(365) : sh(424),
                //   right: sw(30),
                //   child: Container(
                //     width: sw(100),
                //     height: sh(65),
                //     decoration: BoxDecoration(
                //       color: FColors.white,
                //       borderRadius: BorderRadius.circular(sw(14)),
                //     ),
                //     child: Column(
                //       children: [
                //         Image.asset("assets/images/car.png", width: sw(50)),
                //         SizedBox(height: sh(5)),
                //         Text(
                //           (c.rideInfo.value?.driver?['vehiclePlate'] ?? "N/A"),
                //           style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                //             fontSize: 10,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                //
                // Positioned(
                //   top: c.updateView.value ? sh(365) : sh(425),
                //   left: sw(35),
                //   child: Text(
                //     (((c.rideInfo.value?.driver?['vehicle'] ?? "N/A") +
                //         " on the way your drop location")),
                //     style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                //       color: FColors.white,
                //       fontWeight: FontWeight.bold,
                //       fontSize: 10,
                //     ),
                //   ),
                // ),
                //
                // Positioned(
                //   top: c.updateView.value ? sh(385) : sh(445),
                //   left: sw(35),
                //   child: Text(
                //     (("~ " + (c.rideInfo.value?.estimated_drop_time ?? "N/A"))),
                //     style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                //       color: FColors.white,
                //       fontWeight: FontWeight.bold,
                //       fontSize: 10,
                //     ),
                //   ),
                // ),
                //
                // Positioned(
                //   top: c.updateView.value ? sh(395) : sh(455),
                //   left: sw(35),
                //   child: Row(
                //     children: [
                //       Text(
                //         "PKR ",
                //         style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                //           color: FColors.white,
                //         ),
                //       ),
                //       Text(
                //         "${c.rideInfo.value?.fareOffered ?? 0}",
                //         style: FTextTheme.lightTextTheme.displaySmall!.copyWith(
                //           fontWeight: FontWeight.w600,
                //           color: FColors.white,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                // Queue Ride View Data ended

                /// Driver card container
                Positioned(
                  top: c.updateView.value ? sh(460) : sh(524),
                  left: sw(10),
                  child: Container(
                    width: sw(420),
                    height: c.updateView.value ? sh(215) : sh(145),
                    decoration: BoxDecoration(
                      color: FColors.phoneInputField,
                      borderRadius: BorderRadius.circular(sw(14)),
                    ),
                  ),
                ),

                /// Driver Image
                Positioned(
                  top: c.updateView.value ? sh(470) : sh(547),
                  left: sw(28),
                  child: Obx(() {
                    final driver = c.rideInfo.value?.driver;
                    final profileImage = driver?['profileImage']?.toString();

                    return CircleAvatar(
                      radius: sw(32),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: (profileImage != null && profileImage.isNotEmpty)
                              ? profileImage
                              : "https://via.placeholder.com/150",
                          fit: BoxFit.cover,
                          width: sw(64),
                          height: sh(64),
                          placeholder: (_, __) => Image.asset(
                            "assets/images/profile_img_sample.png",
                          ),
                          errorWidget: (_, __, ___) => Image.asset(
                            "assets/images/profile_img_sample.png",
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                /// Badge near driver image
                Positioned(
                  top: c.updateView.value ? sh(510) : sh(591.42),
                  left: sw(84.33),
                  child: Icon(
                    Icons.verified,
                    color: Colors.green,
                    size: sw(11.92),
                  ),
                ),

                /// Star icon + rating + total ratings
                Positioned(
                  top: c.updateView.value ? sh(560) : sh(623),
                  left: sw(23),
                  child: Obx(() {
                    final driver = c.rideInfo.value?.driver;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: sw(14)),
                        SizedBox(width: sw(5)),
                        Text(
                          (driver?['avgRating']?.toString() ?? '0'),
                          style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(width: sw(4)),
                        Text(
                          (driver?['total_ratings'] == null)
                              ? '(0)'
                              : "(${driver?['total_ratings']})",
                          style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                            fontSize: 8,
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                /// Driver category
                Positioned(
                  top: c.updateView.value ? sh(580) : sh(640),
                  left: sw(25),
                  child: Text(
                    c.rideInfo.value?.driver?['category'] ?? "Platinum",
                    style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                      fontSize: 10,
                    ),
                  ),
                ),

                /// Driver name
                Positioned(
                  top: c.updateView.value ? sh(480) : sh(547),
                  left: sw(113),
                  child: Text(
                    (((c.rideInfo.value?.driver?['name']?['firstName'] ?? "N/A") +
                        " " +
                        (c.rideInfo.value?.driver?['name']?['lastName'] ?? "")))
                        .toUpperCase(),
                    style: FTextTheme.lightTextTheme.bodyLarge,
                  ),
                ),

                /// Car model
                Positioned(
                  top: c.updateView.value ? sh(505) : sh(570),
                  left: sw(113),
                  child: Row(
                    children: [
                      Text(
                        (c.rideInfo.value?.driver?['vehicle'] ?? "N/A"),
                        style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (c.rideInfo.value?.driver?['vehiclePlate'] ?? "N/A"),
                        style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Ride type
                if (c.rideStarted.value)
                  Positioned(
                    top: sh(525),
                    left: sw(113),
                    child: Text(
                      "${c.rideArgs['rideType']}",
                      style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                /// Estimated Distance
                if (c.rideStarted.value)
                  Positioned(
                    top: sh(540),
                    left: sw(113),
                    child: Text(
                      "Estimated Distance ${c.rideInfo.value?.distance ?? ''}",
                      style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ),

                /// Estimated arrival time
                Positioned(
                  top: c.updateView.value ? sh(555) : sh(592),
                  left: sw(113),
                  child: Text(
                    "Estimated Arrival Time ${c.rideInfo.value?.eta ?? ''}",
                    style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                      fontSize: 10,
                    ),
                  ),
                ),

                /// Estimated Drop Time
                if (c.rideStarted.value)
                  Positioned(
                    top: sh(570),
                    left: sw(113),
                    child: Text(
                      "Estimated Drop Time ${c.rideInfo.value?.estimated_drop_time ?? ''}",
                      style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ),

                /// Promo status
                if (c.rideStarted.value)
                  Positioned(
                    top: sh(585),
                    left: sw(113),
                    child: Text(
                      "Promo Code Applied",
                      style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ),

                /// Promo Amount
                if (c.rideStarted.value)
                  Positioned(
                    top: sh(600),
                    left: sw(113),
                    child: Text(
                      "Promo Amount",
                      style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ),

                /// Fare
                Positioned(
                  top: c.updateView.value ? sh(620) : sh(622),
                  left: sw(113),
                  child: Row(
                    children: [
                      Text(
                        "PKR ",
                        style: FTextTheme.lightTextTheme.titleSmall!.copyWith(),
                      ),
                      Text(
                        "${c.rideInfo.value?.fareOffered ?? 0}",
                        style: FTextTheme.lightTextTheme.displaySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Driver time
                Positioned(
                  top: c.updateView.value ? sh(480) : sh(536),
                  right: sw(25),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${c.rideInfo.value?.estimated_drop_time ?? ''}",
                        style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: sw(10)),
                      if (!c.rideStarted.value)
                        Text(
                          "${c.rideInfo.value?.distance}",
                          style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),

                /// Call icon button
                Positioned(
                  top: c.updateView.value ? sh(530) : sh(562),
                  left: sw(374),
                  child: SizedBox(
                    width: sw(30),
                    height: sh(30),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Image.asset("assets/images/call.png"),
                      onPressed: () => _call(c.driverPhone),
                    ),
                  ),
                ),

                /// Message icon button
                Positioned(
                  top: c.updateView.value ? sh(575) : sh(606),
                  left: sw(375),
                  child: SizedBox(
                    width: sw(30),
                    height: sh(30),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Image.asset("assets/images/chat.png"),
                      onPressed: () => Get.toNamed("/chat", arguments: {
                        'driver': c.rideInfo.value?.driver,
                        'rideId': c.rideId,
                      }),
                    ),
                  ),
                ),

                /// Pickup location field
                Positioned(
                  top: sh(683),
                  left: sw(19),
                  child: Container(
                    width: sw(393),
                    height: sh(52),
                    padding: EdgeInsets.symmetric(horizontal: sw(14)),
                    decoration: BoxDecoration(
                      color: FColors.phoneInputField,
                      borderRadius: BorderRadius.circular(sw(14)),
                    ),
                    child: Row(
                      children: [
                        Image.asset("assets/images/place.png"),
                        SizedBox(width: sw(12)),
                        Expanded(
                          child: Text(
                            c.rideInfo.value?.pickup?['address'] ?? "No Address Found",
                            style: FTextTheme.lightTextTheme.bodyLarge
                                ?.copyWith(fontSize: sw(14)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Dropoff location field
                Positioned(
                  top: sh(751),
                  left: sw(19),
                  child: Container(
                    width: sw(393),
                    height: sh(52),
                    padding: EdgeInsets.symmetric(horizontal: sw(14)),
                    decoration: BoxDecoration(
                      color: FColors.phoneInputField,
                      borderRadius: BorderRadius.circular(sw(14)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: sw(20)),
                        SizedBox(width: sw(12)),
                        Expanded(
                          child: Text(
                            c.rideInfo.value?.dropoffs.isNotEmpty == true
                                ? c.rideInfo.value!.dropoffs[0]['address']
                                : "",
                            style: FTextTheme.lightTextTheme.bodyLarge
                                ?.copyWith(fontSize: sw(14)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Cancel Ride
                Positioned(
                  top: sh(825),
                  left: sw(27),
                  right: sw(30),
                  child: GestureDetector(
                    onTap: () => c.showCancelReasons(context),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/images/vector_icon.png",
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Cancel Ride",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold)
                              ?.copyWith(color: Colors.red),
                        ),
                        const Spacer(),
                        Transform.rotate(
                          angle: 0,
                          child: Image.asset(
                            "assets/images/vector_icon.png",
                            width: 18,
                            height: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// ✅ NEW: Other Active Rides Cards Section
                if (c.otherActiveRides.isNotEmpty)
                  Positioned(
                    top: sh(870), // Position below cancel ride button
                    left: sw(20),
                    right: sw(20),
                    child: Container(
                      height: sh(100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Other Active Rides',
                            style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: sh(10)),
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: c.otherActiveRides.length,
                              itemBuilder: (context, index) {
                                final ride = c.otherActiveRides[index];
                                return _buildOtherRideCard(ride, c, sw, sh);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                /// New Ride Request button - Show only if user can request more
                if (c.canRequestMoreRides)
                  Positioned(
                    top: c.otherActiveRides.isNotEmpty ? sh(980) : sh(866),
                    left: sw(41),
                    child: SizedBox(
                      width: sw(358),
                      height: sh(48),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(sw(12)),
                          ),
                        ),
                        onPressed: () => Get.offAllNamed('/ride-type'),
                        child: Text(
                          "+ New Request",
                          style: FTextTheme.darkTextTheme.labelLarge,
                        ),
                      ),
                    ),
                  ),

                /// Show message when max rides reached
                if (!c.canRequestMoreRides)
                  Positioned(
                    top: sh(866),
                    left: sw(41),
                    child: Container(
                      width: sw(358),
                      height: sh(48),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(sw(12)),
                      ),
                      child: Center(
                        child: Text(
                          "Maximum active rides reached",
                          style: FTextTheme.lightTextTheme.labelLarge!.copyWith(
                            color: Colors.grey[600],
                          ),
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
  }

  /// ✅ NEW: Build other ride card
  Widget _buildOtherRideCard(
      Map<String, dynamic> ride,
      DriversWaitingController c,
      double Function(double) sw,
      double Function(double) sh
      ) {
    final rideId = ride['rideId']?.toString() ?? '';
    final driver = ride['bid']?['driver'] ?? {};
    final firstName = driver['name']?['firstName'] ?? 'Driver';
    final lastName = driver['name']?['lastName'] ?? '';
    final driverName = '$firstName $lastName'.trim();
    final vehicle = driver['vehicle'] ?? 'Vehicle';
    final vehiclePlate = driver['vehiclePlate'] ?? '';
    final eta = ride['eta'] ?? ride['estimated_arrival_time'] ?? 'N/A';
    final fare = ride['fareOffered'] ?? ride['bid']?['fareOffered'] ?? 0;
    final rideType = ride['rideType'] ?? 'Ride';

    return GestureDetector(
      onTap: () => c.switchToDifferentRide(ride),
      child: Container(
        width: sw(180),
        margin: EdgeInsets.only(right: sw(10)),
        padding: EdgeInsets.all(sw(12)),
        decoration: BoxDecoration(
          color: FColors.phoneInputField,
          borderRadius: BorderRadius.circular(sw(12)),
          border: Border.all(color: FColors.secondaryColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Info Row
            Row(
              children: [
                CircleAvatar(
                  radius: sw(12),
                  backgroundImage: driver['profileImage'] != null
                      ? CachedNetworkImageProvider(driver['profileImage'])
                      : AssetImage("assets/images/profile_img_sample.png") as ImageProvider,
                ),
                SizedBox(width: sw(6)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: sw(9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$vehicle • $vehiclePlate',
                        style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                          fontSize: sw(7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: sh(6)),

            // Ride Details
            Text(
              rideType,
              style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: sw(8),
              ),
            ),

            SizedBox(height: sh(4)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ETA: $eta',
                  style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                    fontSize: sw(7),
                  ),
                ),
                Text(
                  'PKR $fare',
                  style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: sw(8),
                  ),
                ),
              ],
            ),

            SizedBox(height: sh(4)),

            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: sw(6), vertical: sh(2)),
              decoration: BoxDecoration(
                color: FColors.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(sw(4)),
              ),
              child: Text(
                'Active',
                style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                  color: FColors.secondaryColor,
                  fontSize: sw(7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:doorcab/utils/constants/colors.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../../../../utils/theme/custom_theme/text_theme.dart';
// import '../../../shared/screens/app_drawer.dart';
// import '../../driver/screens/reuseable_widgets/drawer.dart';
// import '../controllers/drivers_waiting_controller.dart';
//
// class DriversWaitingScreen extends StatelessWidget {
//   const DriversWaitingScreen({super.key});
//
//   Future<void> _call(String phone) async {
//     final Uri uri = Uri(scheme: 'tel', path: phone);
//
//     if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
//       Get.snackbar("Error", "Could not launch dialer");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final driverArg = Get.arguments as Map<String, dynamic>? ?? {};
//     final c = Get.put(DriversWaitingController());
//
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     /// Reference device size (iPhone 16 Pro Max)
//     const baseWidth = 440.0;
//     const baseHeight = 956.0;
//
//     double sw(double w) => w * screenWidth / baseWidth;
//     double sh(double h) => h * screenHeight / baseHeight;
//
//     final driverPhone = driverArg['phone']?.toString() ?? '';
//
//     return Scaffold(
//       key: c.scaffoldKey,
//       backgroundColor: Colors.white,
//       drawer: AppDrawer(),
//       body: SingleChildScrollView(
//         child: SizedBox(
//           height: screenHeight,
//           width: screenWidth,
//           child: Obx(
//             () => Stack(
//               children: [
//                 /// Map background (from top to 510)
//                 // Positioned(
//                 //   top: 0,
//                 //   left: 0,
//                 //   right: 0,
//                 //   height: c.updateView.value ? sh(450) : sh(510),
//                 //   child: Obx(() {
//                 //     if (c.currentPosition.value == null) {
//                 //       return Center(
//                 //         child: CircularProgressIndicator(strokeWidth: sw(2)),
//                 //       );
//                 //     }
//                 //     return GoogleMap(
//                 //       initialCameraPosition: CameraPosition(
//                 //         target: c.currentPosition.value!,
//                 //         zoom: 14,
//                 //       ),
//                 //       onMapCreated: c.onMapCreated,
//                 //       markers: c.driverMarkers.values.toSet(),
//                 //       polylines:
//                 //       c.polylines.value, // --- FIX: added to show polyline
//                 //
//                 //       myLocationButtonEnabled: false,
//                 //       zoomControlsEnabled: false,
//                 //       mapToolbarEnabled: false,
//                 //       compassEnabled: false,
//                 //       trafficEnabled: false,
//                 //       buildingsEnabled: true,
//                 //       indoorViewEnabled: false,
//                 //     );
//                 //   }),
//                 // ),
//                 Positioned(
//                   top: 0,
//                   left: 0,
//                   right: 0,
//                   height: c.updateView.value ? sh(450) : sh(510),
//                   child: Obx(() {
//                     if (c.currentPosition.value == null) {
//                       return Center(
//                         child: CircularProgressIndicator(
//                           strokeWidth: sw(2),
//                           color: FColors.secondaryColor,
//                         ),
//                       );
//                     }
//
//                     // ✅ UPDATED: Use currentPosition for initial camera
//                     final initial = CameraPosition(
//                       target: c.currentPosition.value ?? const LatLng(0, 0),
//                       zoom: 14,
//                     );
//
//                     // ✅ UPDATED: Use new observables from controller
//                     return GoogleMap(
//                       initialCameraPosition: initial,
//                       onMapCreated: c.onMapCreated,
//                       markers: c.driverMarkers.values.toSet(),
//                       // ✅ UPDATED: Use driverMarkers
//                       polylines: c.polylines.toSet(),
//                       // ✅ UPDATED: Use polylines (Set<Polyline>)
//                       myLocationButtonEnabled: false,
//                       zoomControlsEnabled: false,
//                       mapToolbarEnabled: false,
//                       compassEnabled: false,
//                       trafficEnabled: false,
//                       buildingsEnabled: true,
//                       indoorViewEnabled: false,
//                     );
//                   }),
//                 ),
//
//                 Positioned(
//                   top: c.updateView.value ? sh(280) : sh(340),
//                   // adjust so it sits inside the map area
//                   right: sw(16),
//                   child: FloatingActionButton(
//                     backgroundColor: Colors.white,
//                     elevation: 4,
//                     onPressed: () => c.recenterCamera(),
//                     child: Icon(Icons.my_location, color: Colors.blueAccent),
//                   ),
//                 ),
//
//                 /// Back button (top 39 left 33)
//                 Positioned(
//                   top: sh(23),
//                   left: sw(33),
//                   child: IconButton(
//                     icon: Icon(
//                       Icons.arrow_back,
//                       color: Colors.black,
//                       size: sw(28),
//                     ),
//                     onPressed: () {},
//                     // onPressed: () => Get.back(),
//                   ),
//                 ),
//
//                 // Menu Button
//                 Positioned(
//                   top: sh(23),
//                   right: sw(33),
//                   child: GestureDetector(
//                     onTap: () {
//                       c.scaffoldKey.currentState?.openDrawer();
//                     },
//                     child: Container(
//                       width: sw(39),
//                       height: sh(39),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.8),
//                         borderRadius: BorderRadius.circular(sw(20)),
//                       ),
//                       child: Image.asset(
//                         'assets/images/Menu.png',
//                         width: sw(20),
//                         height: sh(20),
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 // Queue Ride View Data start
//                 Positioned(
//                   top: c.updateView.value ? sh(360) : sh(420),
//                   left: sw(20),
//                   right: sw(20),
//                   child: Container(
//                     width: sw(401),
//                     height: sh(83),
//                     decoration: BoxDecoration(
//                       color: FColors.secondaryColor,
//                       borderRadius: BorderRadius.circular(sw(14)),
//                     ),
//                   ),
//                 ),
//
//                 Positioned(
//                   top: c.updateView.value ? sh(365) : sh(424),
//                   // left: sw(20),
//                   right: sw(30),
//                   child: Container(
//                     width: sw(100),
//                     height: sh(65),
//                     decoration: BoxDecoration(
//                       color: FColors.white,
//                       borderRadius: BorderRadius.circular(sw(14)),
//                     ),
//
//                     child: Column(
//                       children: [
//                         Image.asset("assets/images/car.png", width: sw(50)),
//                         SizedBox(height: sh(5)),
//                         Text(
//                           (c.rideInfo.value?.driver?['vehiclePlate'] ?? "N/A"),
//                           style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 Positioned(
//                   top: c.updateView.value ? sh(365) : sh(425),
//                   left: sw(35),
//                   child: Text(
//                     (((c.rideInfo.value?.driver?['vehicle'] ?? "N/A") +
//                         " on the way your drop location")),
//                     // 👈 Convert full name to uppercase
//                     style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
//                       color: FColors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 10,
//                     ),
//                   ),
//                 ),
//
//                 Positioned(
//                   top: c.updateView.value ? sh(385) : sh(445),
//                   left: sw(35),
//                   child: Text(
//                     (("~ " +
//                         (c.rideInfo.value?.estimated_drop_time ??
//                             "N/A"))), // 👈 Convert full name to uppercase
//                     style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
//                       color: FColors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 10,
//                     ),
//                   ),
//                 ),
//
//                 Positioned(
//                   top: c.updateView.value ? sh(395) : sh(455),
//                   left: sw(35),
//                   child: Row(
//                     children: [
//                       Text(
//                         "PKR ",
//                         style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
//                           color: FColors.white,
//                         ),
//                       ),
//                       Text(
//                         "${c.rideInfo.value?.fareOffered ?? 0}",
//                         style: FTextTheme.lightTextTheme.displaySmall!.copyWith(
//                           fontWeight: FontWeight.w600,
//                           color: FColors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Queue Ride View Data ended
//
//                 /// Driver card container (top 510 → height 145, width 420, bg e3e3e3, radius 14)
//                 Positioned(
//                   top: c.updateView.value ? sh(460) : sh(524),
//                   left: sw(10),
//                   child: Container(
//                     width: sw(420),
//                     height: c.updateView.value ? sh(215) : sh(145),
//                     decoration: BoxDecoration(
//                       color: FColors.phoneInputField,
//                       borderRadius: BorderRadius.circular(sw(14)),
//                     ),
//                   ),
//                 ),
//
//                 /// Driver Image (top 533 left 28, w=68.25 h=65)
//                 Positioned(
//                   top: c.updateView.value ? sh(470) : sh(547),
//                   left: sw(28),
//                   child: Container(
//                     width: sw(68.25),
//                     height: sh(65),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       image: DecorationImage(
//                         image: AssetImage(
//                           "assets/images/profile_img_sample.png",
//                         ),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 Positioned(
//                   top: c.updateView.value ? sh(470) : sh(547),
//                   left: sw(28),
//                   child: Obx(() {
//                     final driver = c.rideInfo.value?.driver;
//                     final profileImage = driver?['profileImage']?.toString();
//
//                     return CircleAvatar(
//                       radius: sw(32),
//                       // backgroundColor: Colors.grey.shade200,
//                       child: ClipOval(
//                         child: CachedNetworkImage(
//                           imageUrl:
//                               (profileImage != null && profileImage.isNotEmpty)
//                                   ? profileImage
//                                   : "https://via.placeholder.com/150",
//                           fit: BoxFit.cover,
//                           width: sw(64),
//                           height: sh(64),
//                           placeholder:
//                               (_, __) => Image.asset(
//                                 "assets/images/profile_img_sample.png",
//                               ),
//                           errorWidget:
//                               (_, __, ___) => Image.asset(
//                                 "assets/images/profile_img_sample.png",
//                               ),
//                         ),
//                       ),
//                     );
//                   }),
//                 ),
//
//                 /// Badge near driver image (top 597.42 left 84.33, w=11.92 h=11.92)
//                 Positioned(
//                   top: c.updateView.value ? sh(510) : sh(591.42),
//                   left: sw(84.33),
//                   child: Icon(
//                     Icons.verified,
//                     color: Colors.green,
//                     size: sw(11.92),
//                   ),
//                 ),
//
//                 /// Star icon + rating + total ratings
//                 Positioned(
//                   top: c.updateView.value ? sh(560) : sh(623),
//                   left: sw(23),
//                   child: Obx(() {
//                     final driver = c.rideInfo.value?.driver;
//                     return Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Icon(Icons.star, color: Colors.amber, size: sw(14)),
//                         SizedBox(width: sw(5)),
//                         Text(
//                           (driver?['avgRating']?.toString() ?? '0'),
//                           style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                             fontSize: 10,
//                           ),
//                         ),
//                         SizedBox(width: sw(4)),
//                         Text(
//                           (driver?['total_ratings'] == null)
//                               ? '(0)'
//                               : "(${driver?['total_ratings']})",
//                           style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                             fontSize: 8,
//                           ),
//                         ),
//                       ],
//                     );
//                   }),
//                 ),
//                 // Positioned(
//                 //   top: sh(623),
//                 //   left: sw(23),
//                 //   child: Icon(Icons.star, color: Colors.amber, size: sw(14)),
//                 // ),
//                 // Positioned(
//                 //   top: sh(623),
//                 //   left: sw(42),
//                 //   child: Text(
//                 //     driverArg['rating']?.toString() ?? "0.0",
//                 //     style: TextStyle(
//                 //       fontSize: sw(12),
//                 //       fontWeight: FontWeight.bold,
//                 //     ),
//                 //   ),
//                 // ),
//                 // Positioned(
//                 //   top: sh(623),
//                 //   left: sw(62),
//                 //   child: Text(
//                 //     "(${driverArg['totalRatings'] ?? 0})",
//                 //     style: TextStyle(fontSize: sw(12), color: Colors.grey),
//                 //   ),
//                 // ),
//
//                 /// Driver category (top 641 left 23)
//                 Positioned(
//                   top: c.updateView.value ? sh(580) : sh(640),
//                   left: sw(25),
//                   child: Text(
//                     driverArg['category'] ?? "Platinum",
//                     style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                       fontSize: 10,
//                     ),
//                   ),
//                 ),
//
//                 /// Driver name (top 553 left 113)
//                 Positioned(
//                   top: c.updateView.value ? sh(480) : sh(547),
//                   left: sw(113),
//                   child: Text(
//                     (((c.rideInfo.value?.driver?['name']?['firstName'] ??
//                                 "N/A") +
//                             " " +
//                             (c.rideInfo.value?.driver?['name']?['lastName'] ??
//                                 "")))
//                         .toUpperCase(), // 👈 Convert full name to uppercase
//                     style: FTextTheme.lightTextTheme.bodyLarge,
//                   ),
//                 ),
//
//                 /// Car model (top 576 left 113)
//                 Positioned(
//                   top: c.updateView.value ? sh(505) : sh(570),
//                   left: sw(113),
//                   child: Row(
//                     children: [
//                       Text(
//                         (c.rideInfo.value?.driver?['vehicle'] ?? "N/A"),
//                         style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                           fontSize: 10,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       // space between model and plate
//                       Text(
//                         (c.rideInfo.value?.driver?['vehiclePlate'] ?? "N/A"),
//                         style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 /// Ride type
//                 if (c.rideStarted.value)
//                   Positioned(
//                     top: sh(525),
//                     left: sw(113),
//                     child: Text(
//                       "${c.rideArgs['rideType']}",
//                       style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//
//                 /// Estimated Distance
//                 if (c.rideStarted.value)
//                   Positioned(
//                     top: sh(540),
//                     left: sw(113),
//                     child: Text(
//                       "Estimated Distance ${c.rideInfo.value?.distance ?? ''}",
//                       style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                         fontSize: 10,
//                       ),
//                     ),
//                   ),
//
//                 /// Estimated arrival time (top 598 left 113)
//                 Positioned(
//                   top: c.updateView.value ? sh(555) : sh(592),
//                   left: sw(113),
//                   child: Text(
//                     "Estimated Arrival Time ${c.rideInfo.value?.eta ?? ''}",
//                     style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                       fontSize: 10,
//                     ),
//                   ),
//                 ),
//
//                 /// Estimated Drop Time
//                 if (c.rideStarted.value)
//                   Positioned(
//                     top: sh(570),
//                     left: sw(113),
//                     child: Text(
//                       "Estimated Drop Time ${c.rideInfo.value?.estimated_drop_time ?? ''}",
//                       style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                         fontSize: 10,
//                       ),
//                     ),
//                   ),
//
//                 /// Promo status
//                 if (c.rideStarted.value)
//                   Positioned(
//                     top: sh(585),
//                     left: sw(113),
//                     child: Text(
//                       "Promo Code Applied",
//                       style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                         fontSize: 10,
//                       ),
//                     ),
//                   ),
//
//                 /// Promo Amount  (top 598 left 113)
//                 if (c.rideStarted.value)
//                   Positioned(
//                     top: sh(600),
//                     left: sw(113),
//                     child: Text(
//                       "Promo Amount",
//                       style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                         fontSize: 10,
//                       ),
//                     ),
//                   ),
//
//                 /// Fare (top 628 left 113)
//                 // Positioned(
//                 //   top: sh(622),
//                 //   left: sw(113),
//                 //   child: Text(
//                 //     "PKR ${c.rideInfo.value?.fareOffered ?? 0}",
//                 //     style: FTextTheme.lightTextTheme.displaySmall!.copyWith(
//                 //       fontWeight: FontWeight.w600,
//                 //     ),
//                 //   ),
//                 // ),
//                 Positioned(
//                   top: c.updateView.value ? sh(620) : sh(622),
//                   left: sw(113),
//                   child: Row(
//                     children: [
//                       Text(
//                         "PKR ",
//                         style: FTextTheme.lightTextTheme.titleSmall!.copyWith(),
//                       ),
//                       Text(
//                         "${c.rideInfo.value?.fareOffered ?? 0}",
//                         style: FTextTheme.lightTextTheme.displaySmall!.copyWith(
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 /// Driver time (top 542 left 327)
//                 ///
//                 Positioned(
//                   top: c.updateView.value ? sh(480) : sh(536),
//                   right: sw(25),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     // ✅ keeps Row only as wide as needed
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Text(
//                         "${c.rideInfo.value?.estimated_drop_time ?? ''}",
//                         style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       SizedBox(width: sw(10)),
//                       // ✅ spacing between ETA and distance
//                       if (!c.rideStarted.value)
//                         Text(
//                           "${c.rideInfo.value?.distance}",
//                           style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                             fontSize: 10,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 // Positioned(
//                 //   top: sh(536),
//                 //   left: sw(300),
//                 //   child: Text(
//                 //     "${c.rideInfo.value?.distance ?? ''} ",
//                 //     style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                 //       fontSize: 10,
//                 //       fontWeight: FontWeight.w700,
//                 //     ),
//                 //   ),
//                 // ),
//                 // /// Driver distance (top 542 left 373)
//                 // Positioned(
//                 //   top: sh(536),
//                 //   left: sw(363),
//                 //   child: Text(
//                 //     "${driverArg['distance'] ?? '20.6'} km",
//                 //     style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                 //       fontSize: 10,
//                 //       fontWeight: FontWeight.w700,
//                 //     ),
//                 //   ),
//                 // ),
//
//                 /// Call icon button (top 568 left 374, w=30 h=30)
//                 Positioned(
//                   top: c.updateView.value ? sh(530) : sh(562),
//                   left: sw(374),
//                   child: SizedBox(
//                     width: sw(30),
//                     height: sh(30),
//                     child: IconButton(
//                       padding: EdgeInsets.zero,
//                       icon: Image.asset("assets/images/call.png"),
//                       // onPressed: () => c.onInit(),
//                       onPressed: () => _call(driverPhone),
//                     ),
//                   ),
//                 ),
//
//                 /// Message icon button (top 612 left 375, w=30 h=30)
//                 Positioned(
//                   top: c.updateView.value ? sh(575) : sh(606),
//                   left: sw(375),
//                   child: SizedBox(
//                     width: sw(30),
//                     height: sh(30),
//                     child: IconButton(
//                       padding: EdgeInsets.zero,
//                       icon: Image.asset("assets/images/chat.png"),
//                       onPressed:
//                           () => Get.toNamed("/chat", arguments: driverArg),
//                     ),
//                   ),
//                 ),
//
//                 /// Pickup location field (top 708 left 19, w=393 h=52)
//                 Positioned(
//                   top: sh(683),
//                   left: sw(19),
//                   child: Container(
//                     width: sw(393),
//                     height: sh(52),
//                     padding: EdgeInsets.symmetric(horizontal: sw(14)),
//                     decoration: BoxDecoration(
//                       color: FColors.phoneInputField,
//                       borderRadius: BorderRadius.circular(sw(14)),
//                     ),
//                     child: Row(
//                       children: [
//                         Image.asset("assets/images/place.png"),
//                         SizedBox(width: sw(12)),
//                         Expanded(
//                           child: Text(
//                             c.rideInfo.value?.pickup?['address'] ??
//                                 "No Address Found",
//                             style: FTextTheme.lightTextTheme.bodyLarge
//                                 ?.copyWith(fontSize: sw(14)),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 /// Dropoff location field (top 780 left 18, w=393 h=52)
//                 Positioned(
//                   top: sh(751),
//                   left: sw(19),
//                   child: Container(
//                     width: sw(393),
//                     height: sh(52),
//                     padding: EdgeInsets.symmetric(horizontal: sw(14)),
//                     decoration: BoxDecoration(
//                       color: FColors.phoneInputField,
//                       borderRadius: BorderRadius.circular(sw(14)),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.location_on, size: sw(20)),
//                         SizedBox(width: sw(12)),
//                         Expanded(
//                           child: Text(
//                             c.rideInfo.value?.dropoffs.isNotEmpty == true
//                                 ? c.rideInfo.value!.dropoffs[0]['address']
//                                 : "",
//                             style: FTextTheme.lightTextTheme.bodyLarge
//                                 ?.copyWith(fontSize: sw(14)),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 // Cancel Ride
//                 Positioned(
//                   top: sh(825),
//                   left: sw(27),
//                   right: sw(30),
//                   child: GestureDetector(
//                     onTap: () => c.showCancelReasons(context),
//                     child: Row(
//                       children: [
//                         Image.asset(
//                           "assets/images/vector_icon.png",
//                           width: 20,
//                           height: 20,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           "Cancel Ride",
//                           style: Theme.of(context).textTheme.bodyMedium
//                               ?.copyWith(fontWeight: FontWeight.bold)
//                               ?.copyWith(color: Colors.red),
//                         ),
//                         const Spacer(),
//                         Transform.rotate(
//                           angle: 0,
//                           child: Image.asset(
//                             "assets/images/vector_icon.png",
//                             width: 18,
//                             height: 18,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 /// New Ride Request button (top 866 left 41, w=358 h=48)
//                 Positioned(
//                   top: sh(866),
//                   left: sw(41),
//                   child: SizedBox(
//                     width: sw(358),
//                     height: sh(48),
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF003366),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(sw(12)),
//                         ),
//                       ),
//                       onPressed: () => c.onNewRequest(),
//                       // onPressed: () => {},
//                       child: Text(
//                         "+ New Request",
//                         style: FTextTheme.darkTextTheme.labelLarge,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
