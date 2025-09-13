// screens/ride_request_list_screen.dart
import 'dart:async';
import 'package:doorcab/utils/constants/image_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Models
class RequestModel {
  final String id;
  final String passengerName;
  final String passengerImage;
  final double rating;
  final String pickupAddress;
  final String dropoffAddress;
  final String phone;
  final int etaMinutes;
  final double distanceKm;
  final double offerAmount;
  final DateTime createdAt;

  RequestModel({
    required this.id,
    required this.passengerName,
    required this.passengerImage,
    required this.rating,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.phone,
    required this.etaMinutes,
    required this.distanceKm,
    required this.offerAmount,
    required this.createdAt,
  });
}

// Controllers
class RideRequestListController extends GetxController {
  final requests = <RequestModel>[].obs;
  final remainingSeconds = <String, int>{}.obs;
  final _timers = <String, Timer>{};
  final isOnline = true.obs;
  final int offerCountdownSeconds = 60;

  @override
  void onInit() {
    super.onInit();
    final sample = _sampleRequests();
    requests.assignAll(sample);
    for (final r in sample) {
      _startTimerForRequest(r.id);
    }
  }

  void _startTimerForRequest(String requestId) {
    _timers[requestId]?.cancel();
    remainingSeconds[requestId] = offerCountdownSeconds;

    _timers[requestId] = Timer.periodic(const Duration(seconds: 1), (t) {
      final current = remainingSeconds[requestId] ?? 0;
      if (current <= 1) {
        t.cancel();
        remainingSeconds[requestId] = 0;
        _handleRequestTimeout(requestId);
      } else {
        remainingSeconds[requestId] = current - 1;
      }
    });
  }

  void stopTimerForRequest(String requestId) {
    _timers[requestId]?.cancel();
    _timers.remove(requestId);
    remainingSeconds.remove(requestId);
  }

  void _handleRequestTimeout(String requestId) {
    final idx = requests.indexWhere((r) => r.id == requestId);
    if (idx >= 0) {
      requests.removeAt(idx);
    }
    Get.snackbar('Request timed out', 'Request $requestId has been removed.');
  }

  void acceptRequest(RequestModel request) {
    stopTimerForRequest(request.id);
    Get.toNamed('/ride-request-detail', arguments: {'request': request});
  }

  void rejectRequest(String requestId) {
    stopTimerForRequest(requestId);
    final idx = requests.indexWhere((r) => r.id == requestId);
    if (idx >= 0) requests.removeAt(idx);
    Get.snackbar('Request rejected', 'You rejected the request');
  }

  void toggleOnline(bool val) {
    isOnline.value = val;
  }

  @override
  void onClose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    super.onClose();
  }

  List<RequestModel> _sampleRequests() {
    final now = DateTime.now();
    return [
      RequestModel(
        id: 'req_1',
        passengerName: 'Ayesha Khan',
        passengerImage: 'assets/images/passenger1.jpg',
        rating: 4.98,
        pickupAddress: 'House 12, Model Town, Lahore',
        dropoffAddress: 'Gulberg, Lahore',
        phone: '+92300XXXXXXX',
        etaMinutes: 2,
        distanceKm: 1.2,
        offerAmount: 250.0,
        createdAt: now.subtract(const Duration(seconds: 10)),
      ),
      RequestModel(
        id: 'req_2',
        passengerName: 'Bilal Ahmed',
        passengerImage: 'assets/images/passenger2.jpg',
        rating: 4.9,
        pickupAddress: 'Main Boulevard, DHA',
        dropoffAddress: 'Airport Road, Lahore',
        phone: '+92301XXXXXXX',
        etaMinutes: 4,
        distanceKm: 3.6,
        offerAmount: 350.0,
        createdAt: now.subtract(const Duration(seconds: 5)),
      ),
    ];
  }
}

// Widgets
class OfferCountdownButton extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final VoidCallback? onPressed;
  final double Function(double) sw;

  const OfferCountdownButton({
    Key? key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.onPressed,
    required this.sw,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = (totalSeconds == 0)
        ? 0.0
        : (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
    final baseColor = const Color(0xFFF8DC25);
    final activeColor = const Color(0xFFFFC300);
    final color = Color.lerp(activeColor, baseColor, progress) ?? baseColor;

    return SizedBox(
      width: sw(160),
      height: sw(37),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(horizontal: sw(8), vertical: sw(4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw(10))),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (remainingSeconds > 0)
              SizedBox(
                width: sw(14),
                height: sw(14),
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: sw(2.2),
                  color: Colors.black,
                ),
              )
            else
              SizedBox(width: sw(14), height: sw(14)),
            SizedBox(width: sw(8)),
            Text(
              "Offer Your Fare",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: sw(12)),
            ),
            SizedBox(width: sw(6)),
            if (remainingSeconds > 0)
              Text(
                '$remainingSeconds s',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: sw(12)),
              )
          ],
        ),
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final RequestModel request;
  final int remainingSeconds;
  final VoidCallback onTapCard;
  final VoidCallback onOfferPressed;
  final double Function(double) sw;
  final double Function(double) sh;

  const RequestCard({
    Key? key,
    required this.request,
    required this.remainingSeconds,
    required this.onTapCard,
    required this.onOfferPressed,
    required this.sw,
    required this.sh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCard,
      child: Container(
        width: sw(420),
        height: sh(165),
        margin: EdgeInsets.symmetric(horizontal: sw(5), vertical: sh(5)),
        padding: EdgeInsets.all(sw(12)),
        decoration: BoxDecoration(
          color: const Color(0xFFE3E3E3),
          borderRadius: BorderRadius.circular(sw(20)),
        ),
        child: Row(
          children: [
            // Passenger image
            Container(
              width: sw(70),
              height: sh(70),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(FImages.profile_img_sample),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: sw(10)),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.passengerName,
                          style: TextStyle(
                            fontSize: sw(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: sw(8)),
                      Icon(Icons.star, size: sw(14), color: const Color(0xFFFFC300)),
                      SizedBox(width: sw(4)),
                      Text(
                        request.rating.toStringAsFixed(2),
                        style: TextStyle(fontSize: sw(14)),
                      ),
                    ],
                  ),

                  SizedBox(height: sh(8)),

                  // Pickup
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black87, fontSize: sw(14)),
                      children: [
                        const TextSpan(text: 'Pickup: ', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: request.pickupAddress),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: sh(6)),

                  // Dropoff
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black87, fontSize: sw(14)),
                      children: [
                        const TextSpan(text: 'Dropoff: ', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: request.dropoffAddress),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),

                  Spacer(),

                  // ETA and Distance row
                  Row(
                    children: [
                      Icon(Icons.access_time, size: sw(14)),
                      SizedBox(width: sw(6)),
                      Text('${request.etaMinutes} min', style: TextStyle(fontSize: sw(14))),
                      SizedBox(width: sw(20)),
                      Icon(Icons.location_on, size: sw(14)),
                      SizedBox(width: sw(6)),
                      Text('${request.distanceKm.toStringAsFixed(1)} km', style: TextStyle(fontSize: sw(14))),
                    ],
                  ),

                  SizedBox(height: sh(8)),

                  // Buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // PKR amount button
                      Container(
                        width: sw(145),
                        height: sh(37),
                        padding: EdgeInsets.symmetric(horizontal: sw(8), vertical: sh(6)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003566),
                          borderRadius: BorderRadius.circular(sw(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_offer, size: sw(18), color: Colors.white),
                            SizedBox(width: sw(6)),
                            Text(
                              'PKR ${request.offerAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: sw(14),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Offer button
                      OfferCountdownButton(
                        remainingSeconds: remainingSeconds,
                        totalSeconds: 60,
                        onPressed: onOfferPressed,
                        sw: sw,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverDrawer extends StatelessWidget {
  const DriverDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 440.0;
    double sw(double w) => w * screenWidth / baseWidth;

    return Drawer(
      width: sw(320),
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sw(20)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw(20)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: sw(36),
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, size: sw(40), color: Colors.grey[600]),
                  ),
                  SizedBox(width: sw(15)),
                  Text(
                    'Driver Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: sw(16)),
                  ),
                ],
              ),
            ),
            SizedBox(height: sw(30)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(Icons.dashboard, 'Dashboard', () => Get.back(), sw),
                  _drawerItem(Icons.schedule, 'Schedule Ride', () {}, sw),
                  _drawerItem(Icons.bar_chart, 'Performance', () {}, sw),
                  _drawerItem(Icons.account_balance_wallet, 'Wallet', () {}, sw),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(sw(20)),
              child: _drawerItem(Icons.logout, 'Logout', () {}, sw, isLogout: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, double Function(double) sw, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, size: sw(24), color: isLogout ? Colors.red : Colors.black),
      title: Text(title, style: TextStyle(fontSize: sw(16), color: isLogout ? Colors.red : Colors.black)),
      onTap: onTap,
    );
  }
}

// Main Screen
class RideRequestListScreen extends StatelessWidget {
  const RideRequestListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RideRequestListController());

    const baseWidth = 440.0;
    const baseHeight = 956.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    Widget _bottomItem(IconData icon, String label, bool selected) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: sw(24), color: selected ? Colors.blue : Colors.grey),
          SizedBox(height: sh(6)),
          Text(
            label,
            style: TextStyle(fontSize: sw(12), color: selected ? Colors.blue : Colors.grey),
          ),
        ],
      );
    }

    return Scaffold(
      drawer: const DriverDrawer(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: Stack(
              children: [
                // Menu icon - 33.85 from left, 37.1 from top
                Positioned(
                  top: sh(37.1),
                  left: sw(33.85),
                  child: GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Icon(Icons.menu, size: sw(24)),
                  ),
                ),

                // Dashboard title - centered
                Positioned(
                  top: sh(48),
                  left: sw(25),
                  width: sw(390),
                  child: Text(
                    'Driver Dashboard',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: sw(18), fontWeight: FontWeight.bold),
                  ),
                ),

                // Settings icon - 32 from top, 389 from left
                Positioned(
                  top: sh(32),
                  left: sw(389),
                  child: Icon(Icons.settings, size: sw(24)),
                ),

                // Online text - 100 from top, 33 from left
                Positioned(
                  top: sh(100),
                  left: sw(33),
                  child: Text(
                    'Online',
                    style: TextStyle(fontSize: sw(16), fontWeight: FontWeight.w600),
                  ),
                ),

                // Toggle button - 96 from top, 362 from left
                Positioned(
                  top: sh(96),
                  left: sw(362),
                  child: Obx(() => Switch(
                    value: c.isOnline.value,
                    onChanged: c.toggleOnline,
                  )),
                ),

                // Requests list - starting at 147 from top, 10 from left
                Positioned(
                  top: sh(147),
                  left: sw(10),
                  right: sw(10),
                  bottom: sh(90),
                  child: Obx(() {
                    if (c.requests.isEmpty) {
                      return Center(
                        child: Text(
                          'No requests at the moment',
                          style: TextStyle(fontSize: sw(16)),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: c.requests.length,
                      itemBuilder: (context, index) {
                        final r = c.requests[index];
                        final rem = c.remainingSeconds[r.id] ?? c.offerCountdownSeconds;
                        return Container(
                          margin: EdgeInsets.only(bottom: sh(10)),
                          child: RequestCard(
                            request: r,
                            remainingSeconds: rem,
                            onTapCard: () => c.acceptRequest(r),
                            onOfferPressed: () => c.acceptRequest(r),
                            sw: sw,
                            sh: sh,
                          ),
                        );
                      },
                    );
                  }),
                ),

                // Bottom navigation
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 40,
                  height: sh(90),
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: sw(12), vertical: sh(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _bottomItem(Icons.list, 'Requests List', true),
                        _bottomItem(Icons.schedule, 'Schedule Ride', false),
                        _bottomItem(Icons.bar_chart, 'Performance', false),
                        _bottomItem(Icons.account_balance_wallet, 'Wallet', false),
                      ],
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
}