import 'package:doorcab/feautures/shared/screens/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../../../shared/services/storage_service.dart';
import '../../driver/screens/reuseable_widgets/drawer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/go_to_pickup_controller.dart';

class GoToPickupScreen extends StatelessWidget {
  const GoToPickupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final raw = Get.arguments;
    final c = Get.put(GoToPickupController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            /// Map (top → till 520)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: sh(520),
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


            /// Back Button
            Positioned(
              top: sh(23),
              left: sw(23),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black, size: sw(28)),
                onPressed: () {},
              ),
            ),

            /// Drawer Menu
            Positioned(
              top: sh(20),
              left: sw(382),
              child: Container(
                width: sw(39),
                height: sh(39),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Builder(
                  builder: (context) {
                    return IconButton(
                      icon: Icon(Icons.menu, color: Colors.black, size: sw(24)),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  },
                ),
              ),
            ),


            /// ✅ NEW: Queue Ride Card - Shows when driver has a queued ride
            Obx(() => c.hasQueuedRide.value
                ? Positioned(
              top: sh(70),
              left: sw(15),
              right: sw(10),
              child: _buildQueuedRideCard(c, sw, sh, screenWidth, baseWidth),
            )
                : const SizedBox.shrink()),

            /// ✅ NEW: New Ride Request Card - Shows when new request arrives
            Obx(() {
              print("🔄 Obx rebuild triggered - showNewRequestCard: ${c.showNewRequestCard.value}");
              return c.showNewRequestCard.value
                  ? Positioned(
                top: sh(100),
                left: sw(10),
                right: sw(10),
                child: _buildNewRequestCard(c, sw, sh, screenWidth, baseWidth),
              )
                  : const SizedBox.shrink();
            }),

            Positioned(
              top: sh(535) - sw(80),
              right: sw(20),
              child: GestureDetector(
                onTap: () {
                  if (!c.rideStarted.value) {
                    c.navigateToPickup();
                  } else {
                    c.navigateToCurrentStop();
                  }
                },
                child: Container(
                  width: sw(50),
                  height: sw(50),
                  decoration: BoxDecoration(
                    color: FColors.secondaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: sw(24),
                  ),
                ),
              ),
            ),

            /// Navigation Info Text
            Positioned(
              top: sh(535) - sw(120),
              right: sw(20),
              child: Obx(() => Container(
                padding: EdgeInsets.symmetric(horizontal: sw(12), vertical: sh(6)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(sw(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  c.getNavigationButtonText(),
                  style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              )),
            ),

            /// Passenger Info Card
            Positioned(
              top: sh(535),
              left: sw(10),
              child: Container(
                width: sw(420),
                height: sh(198),
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
                      child: Obx(() => CircleAvatar(
                        radius: sw(30),
                        backgroundImage: c.passengerProfileUrl.value.isNotEmpty
                            ? NetworkImage(c.passengerProfileUrl.value)
                            : const AssetImage('assets/images/profile_img_sample.png') as ImageProvider,
                      )),
                    ),

                    /// Passenger Name + Rating
                    Positioned(
                      top: sh(10),
                      left: sw(90),
                      child: Row(
                        children: [
                          Obx(() => Text(
                            c.passengerName.value.isNotEmpty ? c.passengerName.value.toUpperCase() : "NAME",
                            style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                              fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! * screenWidth / baseWidth,
                            ),
                          )),
                          SizedBox(width: sw(15)),
                          Icon(
                              Icons.star,
                              size: sw(14),
                              color: const Color(0xFFFFC300)
                          ),
                          SizedBox(width: sw(5)),
                          Obx(() => Text(
                            c.passengerRating.value.isNotEmpty ? c.passengerRating.value : "0",
                            style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                              fontSize: (FTextTheme.lightTextTheme.bodyLarge!.fontSize! * screenWidth / baseWidth) - 4,
                            ),
                          )),
                        ],
                      ),
                    ),

                    /// Pickup
                    Positioned(
                      top: sh(40),
                      left: sw(90),
                      child: Obx(() => SizedBox(
                        width: sw(260),
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Pickup: ',
                                style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: c.pickupAddress.value.isNotEmpty
                                    ? c.pickupAddress.value
                                    : 'location',
                                style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ),

                    /// Dropoff
                    Positioned(
                      top: sh(63),
                      left: sw(90),
                      child: Obx(() => SizedBox(
                        width: sw(260),
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Dropoff: ',
                                style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: c.dropoffAddress.value.isNotEmpty
                                    ? c.dropoffAddress.value
                                    : 'location',
                                style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ),

                    /// Estimated arrival
                    Positioned(
                      top: sh(86),
                      left: sw(90),
                      child: Obx(() => Text(
                        "Estimated Arrival: ${c.estimatedArrivalTime.value.isNotEmpty ? c.estimatedArrivalTime.value : '0000'}",
                        style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                      )),
                    ),

                    /// Estimated dropoff
                    Positioned(
                      top: sh(109),
                      left: sw(90),
                      child: Obx(() => Text(
                        "Estimated Dropoff: ${c.estimatedDropoffTime.value.isNotEmpty ? c.estimatedDropoffTime.value : '11:00 am'}",
                        style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                      )),
                    ),

                    /// Estimated distance
                    Positioned(
                      top: sh(132),
                      left: sw(90),
                      child: Obx(() => Text(
                        "Estimated Distance: ${c.estimatedDistance.value.isNotEmpty ? c.estimatedDistance.value : '0 km'}",
                        style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                      )),
                    ),

                    /// Time (top-right)
                    Positioned(
                      top: sh(12),
                      right: sw(20),
                      child: Text(
                        "2 min",
                        style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                          fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! * screenWidth / baseWidth,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    /// Call
                    Positioned(
                      top: sh(50),
                      right: sw(20),
                      child: GestureDetector(
                        onTap: () {
                          launchUrl(Uri(scheme: 'tel', path: c.phone.value));
                        },
                        child: Image.asset("assets/images/call.png", width: sw(30), height: sh(30)),
                      ),
                    ),

                    /// Message
                    Positioned(
                      top: sh(90),
                      right: sw(20),
                      child: GestureDetector(
                        onTap: () => c.navigateToChat(),
                        // onTap: () => Get.toNamed("/chat", arguments: raw),
                        child: Image.asset("assets/images/chat.png", width: sw(30), height: sh(30)),
                      ),
                    ),

                    /// Fare
                    Positioned(
                      top: sh(157),
                      left: sw(18),
                      child: Obx(() => Row(
                        children: [
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
                                  padding: EdgeInsets.symmetric(vertical: sh(1)),
                                  decoration: BoxDecoration(
                                    color: FColors.white,
                                    borderRadius: BorderRadius.circular(sw(6)),
                                  ),
                                  child: Image.asset("assets/images/cash.png"),
                                ),
                                SizedBox(width: sw(8)),
                                Text(
                                  'PKR ${c.fare.value.toStringAsFixed(0)}',
                                  style: FTextTheme.lightTextTheme.headlineSmall!.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: FColors.white,
                                    fontSize: FTextTheme.lightTextTheme.headlineSmall!.fontSize! * screenWidth / baseWidth,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
            ),

            /// "I am at pickup location" Button
            Obx(() => c.rideStarted.value
                ? const SizedBox.shrink()
                : Positioned(
              top: sh(749),
              left: sw(30),
              child: GestureDetector(
                onTap: () => c.markDriverArrived(),
                child: Container(
                  width: sw(393),
                  height: sh(52),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 195, 0, 1),
                    borderRadius: BorderRadius.circular(sw(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "I am at pick up Location",
                        style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! * screenWidth / baseWidth,
                        ),
                      ),
                      SizedBox(width: sw(12)),
                      Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                          size: sw(18)
                      ),
                    ],
                  ),
                ),
              ),
            )),

            /// Cancel Ride
            Positioned(
              top: sh(821),
              left: sw(30),
              right: sw(30),
              child: GestureDetector(
                onTap: () => c.showCancelReasons(context),
                child: Row(
                  children: [
                    Image.asset("assets/images/vector_icon.png", width: sw(20), height: sh(20)),
                    SizedBox(width: sw(8)),
                    Text(
                      "Cancel Ride",
                      style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                        fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! * screenWidth / baseWidth,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const Spacer(),
                    Image.asset("assets/images/polygon_icon.png", width: sw(18), height: sh(18)),
                  ],
                ),
              ),
            ),

            /// Start / Complete Ride Button
            Obx(() => Positioned(
              top: sh(870),
              left: sw(30),
              right: sw(30),
              child: SizedBox(
                height: sh(52),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw(12))),
                  ),
                  onPressed: (c.isStartingRide.value || c.isCompletingRide.value) ? null : () {
                    if (!c.rideStarted.value) {
                      c.markDriverStarted();
                    } else {
                      c.markDriverEnded();
                    }
                  },
                  child: (c.isStartingRide.value || c.isCompletingRide.value)
                      ? SizedBox(
                    width: sw(20),
                    height: sw(20),
                    child: CircularProgressIndicator(
                      strokeWidth: sw(2),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    c.rideStarted.value ? "Mark Complete" : "Start a Ride",
                    style: FTextTheme.darkTextTheme.labelLarge!.copyWith(
                      fontSize: FTextTheme.darkTextTheme.labelLarge!.fontSize! * screenWidth / baseWidth,
                    ),
                  ),
                ),
              ),
            )),

            /// Fullscreen loader overlay
            if (c.isStartingRide.value || c.isCompletingRide.value || c.isCancelingRide.value )
                // || c.isSubmittingBid.value)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: sw(2),
                      ),
                      SizedBox(height: sh(20)),
                      Text(
                        _getLoadingText(c),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sw(16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Build Queued Ride Card
  Widget _buildQueuedRideCard(GoToPickupController c, double Function(double) sw, double Function(double) sh, double screenWidth, double baseWidth) {

    final queueRides = StorageService.getQueueRides();
    if (queueRides.isNotEmpty) {
      print('✅ Found queued ride:'+ queueRides.length.toString());
      print('✅ Found queued ride:'+ queueRides.toString());
      print('✅ Found queued ride:'+ queueRides[0].toString());
    } else {
      print('ℹ️ No queued rides found');
    }
    return Container(
      padding: EdgeInsets.all(sw(10)),
      decoration: BoxDecoration(
        color: FColors.phoneInputField,
        borderRadius: BorderRadius.circular(sw(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passenger Info
          Row(
            children: [
              CircleAvatar(
                radius: sw(20),
                backgroundImage: queueRides[0]['rideData']['passenger']['profileImage'] != null && queueRides[0]['rideData']['passenger']['profileImage'].isNotEmpty
                    ? NetworkImage(queueRides[0]['rideData']['passenger']['profileImage'])
                    : const AssetImage(FImages.profile_img_sample) as ImageProvider,
              ),
              SizedBox(width: sw(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            queueRides[0]['rideData']['passenger']['name']?.toString().toUpperCase() ?? "PASSENGER",
                            style: FTextTheme.lightTextTheme.bodyMedium!.copyWith(
                              fontSize: FTextTheme.lightTextTheme.bodyMedium!.fontSize! * screenWidth / baseWidth,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          "${queueRides[0]['rideData']['estimated_distance'] ?? '0'}",
                          style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                            fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! * screenWidth / baseWidth,
                            fontWeight: FontWeight.bold,
                            color: FColors.black,
                          ),
                        ),
                        SizedBox(width: sw(10)),
                        Text(
                          "${queueRides[0]['rideData']['estimated_arrival_time'] ?? '0'} ",
                          style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                            fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! * screenWidth / baseWidth,
                            fontWeight: FontWeight.bold,
                            color: FColors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: sh(2)),
                    Row(
                      children: [
                        Icon(Icons.star, size: sw(12), color: const Color(0xFFFFC300)),
                        SizedBox(width: sw(4)),
                        Text(
                          queueRides[0]['rideData']['passenger']['avgRating']?.toString() ?? "0.0",
                          style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                            fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! * screenWidth / baseWidth,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: sh(12)),

          // Ride Details
          _buildRideDetailRow("Pickup", queueRides[0]['rideData']['pickup']['address'] ?? "Unknown", sw, sh, screenWidth, baseWidth),
          SizedBox(height: sh(6)),
          _buildRideDetailRow("Dropoff", queueRides[0]['rideData']['dropoffs'][0]['address'] ?? "Unknown", sw, sh, screenWidth, baseWidth),

          SizedBox(height: sh(12)),

          // Fare and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: sw(5), vertical: sh(6)),
                decoration: BoxDecoration(
                  color: FColors.secondaryColor,
                  borderRadius: BorderRadius.circular(sw(8)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: sw(48),
                      height: sh(30),
                      decoration: BoxDecoration(
                        color: FColors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Image.asset("assets/images/cash.png"),
                    ),
                    SizedBox(width: sw(8)),
                    Text(
                      'PKR ${queueRides[0]['rideData']['fare']?.toStringAsFixed(0) ?? '0'}',
                      style: FTextTheme.lightTextTheme.bodyMedium!.copyWith(
                        fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! * screenWidth / baseWidth,
                        fontWeight: FontWeight.bold,
                        color: FColors.white,
                      ),
                    ),
                  ],
                ),
              ),


            ],
          ),

        ],
      ),
    );
    //   Container(
    //   padding: EdgeInsets.all(sw(16)),
    //   decoration: BoxDecoration(
    //     color: Colors.white,
    //     borderRadius: BorderRadius.circular(sw(12)),
    //     boxShadow: [
    //       BoxShadow(
    //         color: Colors.black.withOpacity(0.1),
    //         blurRadius: 8,
    //         offset: const Offset(0, 2),
    //       ),
    //     ],
    //     border: Border.all(color: FColors.secondaryColor, width: 2),
    //   ),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Row(
    //         children: [
    //           Icon(Icons.queue, color: FColors.secondaryColor, size: sw(20)),
    //           SizedBox(width: sw(8)),
    //           Text(
    //             "Queued Ride",
    //             style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
    //               fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! * screenWidth / baseWidth,
    //               fontWeight: FontWeight.bold,
    //               color: FColors.secondaryColor,
    //             ),
    //           ),
    //         ],
    //       ),
    //       SizedBox(height: sh(8)),
    //       Text(
    //         "You have a ride waiting in queue",
    //         style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
    //           fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! * screenWidth / baseWidth,
    //           color: Colors.grey[700],
    //         ),
    //       ),
    //       SizedBox(height: sh(4)),
    //       Text(
    //         "Complete current ride to start next",
    //         style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
    //           fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! * screenWidth / baseWidth,
    //           color: Colors.grey[600],
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  // ✅ NEW: Build New Request Card
  Widget _buildNewRequestCard(GoToPickupController c, double Function(double) sw, double Function(double) sh, double screenWidth, double baseWidth) {
    final request = c.currentNewRequest;

    return Container(
      padding: EdgeInsets.all(sw(10)),
      decoration: BoxDecoration(
        color: FColors.phoneInputField,
        borderRadius: BorderRadius.circular(sw(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "New Ride Request",
                style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                  fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! * screenWidth / baseWidth,
                  fontWeight: FontWeight.bold,
                  color: FColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: sh(12)),

          // Passenger Info
          Row(
            children: [
              CircleAvatar(
                radius: sw(20),
                backgroundImage: request['passengerImage'] != null && request['passengerImage'].isNotEmpty
                    ? NetworkImage(request['passengerImage'])
                    : const AssetImage(FImages.profile_img_sample) as ImageProvider,
              ),
              SizedBox(width: sw(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request['passengerName']?.toString().toUpperCase() ?? "PASSENGER",
                            style: FTextTheme.lightTextTheme.bodyMedium!.copyWith(
                              fontSize: FTextTheme.lightTextTheme.bodyMedium!.fontSize! * screenWidth / baseWidth,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          "${request['distanceKm']?.toStringAsFixed(1) ?? '0'} km",
                          style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                            fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! * screenWidth / baseWidth,
                            fontWeight: FontWeight.bold,
                            color: FColors.black,
                          ),
                        ),
                        SizedBox(width: sw(10)),
                        Text(
                          "${request['etaMinutes'] ?? '0'} min",
                          style: FTextTheme.lightTextTheme.titleMedium!.copyWith(
                            fontSize: FTextTheme.lightTextTheme.titleSmall!.fontSize! * screenWidth / baseWidth,
                            fontWeight: FontWeight.bold,
                            color: FColors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: sh(2)),
                    Row(
                      children: [
                        Icon(Icons.star, size: sw(12), color: const Color(0xFFFFC300)),
                        SizedBox(width: sw(4)),
                        Text(
                          request['rating']?.toString() ?? "0.0",
                          style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                            fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! * screenWidth / baseWidth,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: sh(12)),

          // Ride Details
          _buildRideDetailRow("Pickup", request['pickupAddress'] ?? "Unknown", sw, sh, screenWidth, baseWidth),
          SizedBox(height: sh(6)),
          _buildRideDetailRow("Dropoff", request['dropoffAddress'] ?? "Unknown", sw, sh, screenWidth, baseWidth),

          SizedBox(height: sh(12)),

          // Fare and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: sw(5), vertical: sh(6)),
                decoration: BoxDecoration(
                  color: FColors.secondaryColor,
                  borderRadius: BorderRadius.circular(sw(8)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: sw(48),
                      height: sh(30),
                      decoration: BoxDecoration(
                        color: FColors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Image.asset("assets/images/cash.png"),
                    ),
                    SizedBox(width: sw(8)),
                    Text(
                      'PKR ${request['offerAmount']?.toStringAsFixed(0) ?? '0'}',
                      style: FTextTheme.lightTextTheme.bodyMedium!.copyWith(
                        fontSize: FTextTheme.lightTextTheme.titleMedium!.fontSize! * screenWidth / baseWidth,
                        fontWeight: FontWeight.bold,
                        color: FColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  // Reject Button
                  Obx(() => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: sw(16), vertical: sh(8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(sw(8)),
                      ),
                    ),
                    onPressed: c.isSubmittingBid.value ? null : c.rejectNewRequest,
                    child: Text(
                      "Reject",
                      style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                        fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! * screenWidth / baseWidth,
                        color: Colors.white,
                      ),
                    ),
                  )),

                  SizedBox(width: sw(8)),

                  // Accept Button
                  Obx(() => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FColors.primaryColor,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: sw(16), vertical: sh(8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(sw(8)),
                      ),
                    ),
                    onPressed: (c.isSubmittingBid.value || c.isBidSubmitted.value) ? null : c.acceptNewRequest,
                    child: c.isSubmittingBid.value
                        ? SizedBox(
                      width: sw(16),
                      height: sw(16),
                      child: CircularProgressIndicator(
                        strokeWidth: sw(2),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                        : Text(
                      c.isBidSubmitted.value ? "Waiting..." : "Accept",
                      style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                        fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! * screenWidth / baseWidth,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                ],
              ),
            ],
          ),

          // Bid Status
          Obx(() => c.isBidSubmitted.value
              ? Padding(
            padding: EdgeInsets.only(top: sh(8)),
            child: Text(
              "Bid submitted - Waiting for passenger response...",
              style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
                fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! * screenWidth / baseWidth,
                color: Colors.blue,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildRideDetailRow(String label, String value, double Function(double) sw, double Function(double) sh, double screenWidth, double baseWidth) {
    return Row(
      children: [
        Container(
          width: sw(70),
          child: Text(
            "$label:",
            style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
              fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! * screenWidth / baseWidth,
              fontWeight: FontWeight.bold,
              color: FColors.black,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
              fontSize: FTextTheme.lightTextTheme.bodySmall!.fontSize! * screenWidth / baseWidth,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  String _getLoadingText(GoToPickupController c) {
    if (c.isStartingRide.value) return "Starting ride...";
    if (c.isCompletingRide.value) return "Completing ride...";
    if (c.isCancelingRide.value) return "Canceling ride...";
    if (c.isSubmittingBid.value) return "Submitting bid...";
    return "Loading...";
  }
}


// import 'package:doorcab/feautures/shared/screens/app_drawer.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../../../../utils/constants/colors.dart';
// import '../../../../utils/constants/image_strings.dart';
// import '../../../../utils/theme/custom_theme/text_theme.dart';
// import '../../driver/screens/reuseable_widgets/drawer.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../controllers/go_to_pickup_controller.dart';
//
// class GoToPickupScreen extends StatelessWidget {
//   const GoToPickupScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final raw = Get.arguments;
//     final c = Get.put(GoToPickupController());
//
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     const baseWidth = 440.0;
//     const baseHeight = 956.0;
//
//     double sw(double w) => w * screenWidth / baseWidth;
//     double sh(double h) => h * screenHeight / baseHeight;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       drawer: const AppDrawer(),
//       body: SizedBox(
//         width: screenWidth,
//         height: screenHeight,
//         child: Stack(
//           children: [
//             /// Map (top → till 520) - ✅ UPDATED: Use new controller observables
//             Positioned(
//               top: 0,
//               left: 0,
//               right: 0,
//               height: sh(520),
//               child: Obx(() {
//                 if (c.currentPosition.value == null) {
//                   return Center(
//                     child: CircularProgressIndicator(
//                       strokeWidth: sw(2),
//                       color: FColors.secondaryColor,
//                     ),
//                   );
//                 }
//
//                 // ✅ UPDATED: Use currentPosition for initial camera
//                 final initial = CameraPosition(
//                   target: c.currentPosition.value ?? const LatLng(0, 0),
//                   zoom: 14,
//                 );
//
//                 // ✅ UPDATED: Use new observables from controller
//                 return GoogleMap(
//                   initialCameraPosition: initial,
//                   onMapCreated: c.onMapCreated,
//                   markers: c.driverMarkers.values.toSet(), // ✅ UPDATED: Use driverMarkers
//                   polylines: c.polylines.toSet(), // ✅ UPDATED: Use polylines (Set<Polyline>)
//                   myLocationButtonEnabled: false,
//                   zoomControlsEnabled: false,
//                   mapToolbarEnabled: false,
//                   compassEnabled: false,
//                   trafficEnabled: false,
//                   buildingsEnabled: true,
//                   indoorViewEnabled: false,
//                 );
//               }),
//             ),
//
//             Positioned(
//               top: sh(535) - sw(80), // Position above the passenger info card
//               right: sw(20),
//               child: GestureDetector(
//                 onTap: () {
//                   if (!c.rideStarted.value) {
//                     // Navigate to pickup
//                     c.navigateToPickup();
//                   } else {
//                     // Navigate to current stop/dropoff
//                     c.navigateToCurrentStop();
//                   }
//                 },
//                 child: Container(
//                   width: sw(50),
//                   height: sw(50),
//                   decoration: BoxDecoration(
//                     color: FColors.secondaryColor,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.3),
//                         blurRadius: 4,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Icon(
//                     Icons.navigation,
//                     color: Colors.white,
//                     size: sw(24),
//                   ),
//                 ),
//               ),
//             ),
//
//             /// Optional: Navigation Info Text (shows current target)
//             Positioned(
//               top: sh(535) - sw(120),
//               right: sw(20),
//               child: Obx(() => Container(
//                 padding: EdgeInsets.symmetric(horizontal: sw(12), vertical: sh(6)),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(sw(20)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 4,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Text(
//                   c.getNavigationButtonText(),
//                   style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//               )),
//             ),
//
//             /// Back Button
//             Positioned(
//               top: sh(23),
//               left: sw(33),
//               child: IconButton(
//                 icon: Icon(Icons.arrow_back, color: Colors.black, size: sw(28)),
//                 onPressed: () {},
//                 // onPressed: () => Get.back(),
//               ),
//             ),
//
//             /// Drawer Menu
//             Positioned(
//               top: sh(20),
//               left: sw(382),
//               child: Container(
//                 width: sw(39),
//                 height: sh(39),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Builder(
//                   builder: (context) {
//                     return IconButton(
//                       icon: Icon(Icons.menu, color: Colors.black, size: sw(24)),
//                       onPressed: () {
//                         Scaffold.of(context).openDrawer();
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ),
//
//             /// Passenger Info Card
//             Positioned(
//               top: sh(535),
//               left: sw(10),
//               child: Container(
//                 width: sw(420),
//                 height: sh(198),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFE3E3E3),
//                   borderRadius: BorderRadius.circular(sw(20)),
//                 ),
//                 child: Stack(
//                   children: [
//                     /// Passenger Image
//                     Positioned(
//                       top: sh(12),
//                       left: sw(18),
//                       child: Obx(() => CircleAvatar(
//                         radius: sw(30),
//                         backgroundImage: c.passengerProfileUrl.value.isNotEmpty
//                             ? NetworkImage(c.passengerProfileUrl.value)
//                             : const AssetImage('assets/images/profile_img_sample.png') as ImageProvider,
//                       )),
//                     ),
//
//                     /// Passenger Name + Rating
//                     Positioned(
//                       top: sh(10),
//                       left: sw(90),
//                       child: Row(
//                         children: [
//                           Obx(() => Text(
//                             c.passengerName.value.isNotEmpty ? c.passengerName.value.toUpperCase() : "NAME",
//                             style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                               fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! * screenWidth / baseWidth,
//                             ),
//                           )),
//                           SizedBox(width: sw(15)),
//                           Icon(
//                               Icons.star,
//                               size: sw(14),
//                               color: const Color(0xFFFFC300)
//                           ),
//                           SizedBox(width: sw(5)),
//                           Obx(() => Text(
//                             c.passengerRating.value.isNotEmpty ? c.passengerRating.value : "0",
//                             style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                               fontSize: (FTextTheme.lightTextTheme.bodyLarge!.fontSize! * screenWidth / baseWidth) - 4,
//                             ),
//                           )),
//                         ],
//                       ),
//                     ),
//
//                     /// Pickup
//                     Positioned(
//                       top: sh(40),
//                       left: sw(90),
//                       child: Obx(() => SizedBox(
//                         width: sw(260),
//                         child: RichText(
//                           overflow: TextOverflow.ellipsis,
//                           text: TextSpan(
//                             children: [
//                               TextSpan(
//                                 text: 'Pickup: ',
//                                 style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               TextSpan(
//                                 text: c.pickupAddress.value.isNotEmpty
//                                     ? c.pickupAddress.value
//                                     : 'location',
//                                 style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.normal,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       )),
//                     ),
//
//                     /// Dropoff
//                     Positioned(
//                       top: sh(63),
//                       left: sw(90),
//                       child: Obx(() => SizedBox(
//                         width: sw(260),
//                         child: RichText(
//                           overflow: TextOverflow.ellipsis,
//                           text: TextSpan(
//                             children: [
//                               TextSpan(
//                                 text: 'Dropoff: ',
//                                 style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               TextSpan(
//                                 text: c.dropoffAddress.value.isNotEmpty
//                                     ? c.dropoffAddress.value
//                                     : 'location',
//                                 style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.normal,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       )),
//                     ),
//
//                     /// Estimated arrival
//                     Positioned(
//                       top: sh(86),
//                       left: sw(90),
//                       child: Obx(() => Text(
//                         "Estimated Arrival: ${c.estimatedArrivalTime.value.isNotEmpty ? c.estimatedArrivalTime.value : '0000'}",
//                         style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
//                           fontSize: 10,
//                           fontWeight: FontWeight.normal,
//                         ),
//                       )),
//                     ),
//
//                     /// Estimated dropoff
//                     Positioned(
//                       top: sh(109),
//                       left: sw(90),
//                       child: Obx(() => Text(
//                         "Estimated Dropoff: ${c.estimatedDropoffTime.value.isNotEmpty ? c.estimatedDropoffTime.value : '11:00 am'}",
//                         style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
//                           fontSize: 10,
//                           fontWeight: FontWeight.normal,
//                         ),
//                       )),
//                     ),
//
//                     /// Estimated distance
//                     Positioned(
//                       top: sh(132),
//                       left: sw(90),
//                       child: Obx(() => Text(
//                         "Estimated Distance: ${c.estimatedDistance.value.isNotEmpty ? c.estimatedDistance.value : '0 km'}",
//                         style: FTextTheme.lightTextTheme.bodySmall!.copyWith(
//                           fontSize: 10,
//                           fontWeight: FontWeight.normal,
//                         ),
//                       )),
//                     ),
//
//                     /// Time (top-right)
//                     Positioned(
//                       top: sh(12),
//                       right: sw(20),
//                       child: Text(
//                         "2 min",
//                         style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                           fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! * screenWidth / baseWidth,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ),
//
//                     /// Call
//                     Positioned(
//                       top: sh(50),
//                       right: sw(20),
//                       child: GestureDetector(
//                         onTap: () {
//                           launchUrl(Uri(scheme: 'tel', path: c.phone.value));
//                         },
//                         child: Image.asset("assets/images/call.png", width: sw(30), height: sh(30)),
//                       ),
//                     ),
//
//                     /// Message
//                     Positioned(
//                       top: sh(90),
//                       right: sw(20),
//                       child: GestureDetector(
//                         onTap: () => Get.toNamed("/chat", arguments: raw),
//                         child: Image.asset("assets/images/chat.png", width: sw(30), height: sh(30)),
//                       ),
//                     ),
//
//                     /// Fare
//                     Positioned(
//                       top: sh(157),
//                       left: sw(18),
//                       child: Obx(() => Row(
//                         children: [
//                           Container(
//                             width: sw(185),
//                             height: sh(37),
//                             padding: EdgeInsets.symmetric(horizontal: sw(8)),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF003566),
//                               borderRadius: BorderRadius.circular(sw(10)),
//                             ),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   width: sw(48),
//                                   height: sh(30),
//                                   padding: EdgeInsets.symmetric(vertical: sh(1)),
//                                   decoration: BoxDecoration(
//                                     color: FColors.white,
//                                     borderRadius: BorderRadius.circular(sw(6)),
//                                   ),
//                                   child: Image.asset("assets/images/cash.png"),
//                                 ),
//                                 SizedBox(width: sw(8)),
//                                 Text(
//                                   'PKR ${c.fare.value.toStringAsFixed(0)}',
//                                   style: FTextTheme.lightTextTheme.headlineSmall!.copyWith(
//                                     fontWeight: FontWeight.w700,
//                                     color: FColors.white,
//                                     fontSize: FTextTheme.lightTextTheme.headlineSmall!.fontSize! * screenWidth / baseWidth,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       )),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             /// "I am at pickup location" Button
//             Obx(() => c.rideStarted.value
//                 ? const SizedBox.shrink()
//                 : Positioned(
//               top: sh(749),
//               left: sw(30),
//               child: GestureDetector(
//                 onTap: () => c.markDriverArrived(),
//                 child: Container(
//                   width: sw(393),
//                   height: sh(52),
//                   decoration: BoxDecoration(
//                     color: const Color.fromRGBO(255, 195, 0, 1),
//                     borderRadius: BorderRadius.circular(sw(14)),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         "I am at pick up Location",
//                         style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                           fontWeight: FontWeight.bold,
//                           fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! * screenWidth / baseWidth,
//                         ),
//                       ),
//                       SizedBox(width: sw(12)),
//                       Icon(
//                           Icons.arrow_forward_ios,
//                           color: Colors.black,
//                           size: sw(18)
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             )),
//
//             /// Cancel Ride
//             Positioned(
//               top: sh(821),
//               left: sw(30),
//               right: sw(30),
//               child: GestureDetector(
//                 onTap: () => c.showCancelReasons(context),
//                 child: Row(
//                   children: [
//                     Image.asset("assets/images/vector_icon.png", width: sw(20), height: sh(20)),
//                     SizedBox(width: sw(8)),
//                     Text(
//                       "Cancel Ride",
//                       style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
//                         fontSize: FTextTheme.lightTextTheme.bodyLarge!.fontSize! * screenWidth / baseWidth,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.red,
//                       ),
//                     ),
//                     const Spacer(),
//                     Image.asset("assets/images/polygon_icon.png", width: sw(18), height: sh(18)),
//                   ],
//                 ),
//               ),
//             ),
//
//             /// Start / Complete Ride Button
//             Obx(() => Positioned(
//               top: sh(870),
//               left: sw(30),
//               right: sw(30),
//               child: SizedBox(
//                 height: sh(52),
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF003366),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw(12))),
//                   ),
//                   onPressed: (c.isStartingRide.value || c.isCompletingRide.value) ? null : () {
//                     if (!c.rideStarted.value) {
//                       c.markDriverStarted();
//                     } else {
//                       c.markDriverEnded();
//                     }
//                   },
//                   child: (c.isStartingRide.value || c.isCompletingRide.value)
//                       ? SizedBox(
//                     width: sw(20),
//                     height: sw(20),
//                     child: CircularProgressIndicator(
//                       strokeWidth: sw(2),
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                       : Text(
//                     c.rideStarted.value ? "Mark Complete" : "Start a Ride",
//                     style: FTextTheme.darkTextTheme.labelLarge!.copyWith(
//                       fontSize: FTextTheme.darkTextTheme.labelLarge!.fontSize! * screenWidth / baseWidth,
//                     ),
//                   ),
//                 ),
//               ),
//             )),
//
//             /// ✅ ADDED: Fullscreen loader overlay for THREE SPECIFIC ACTIONS
//             if (c.isStartingRide.value || c.isCompletingRide.value || c.isCancelingRide.value)
//               Container(
//                 width: double.infinity,
//                 height: double.infinity,
//                 color: Colors.black54,
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: sw(2),
//                       ),
//                       SizedBox(height: sh(20)),
//                       Text(
//                         _getLoadingText(c),
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: sw(16),
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ✅ ADDED: Helper method to get appropriate loading text
//   String _getLoadingText(GoToPickupController c) {
//     if (c.isStartingRide.value) return "Starting ride...";
//     if (c.isCompletingRide.value) return "Completing ride...";
//     if (c.isCancelingRide.value) return "Canceling ride...";
//     return "Loading...";
//   }
// }
