import 'package:doorcab/feautures/rides/driver/screens/reuseable_widgets/drawer.dart';
import 'package:doorcab/feautures/rides/driver/screens/reuseable_widgets/request_card.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ride_request_list_controller.dart';

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
                    child: Icon(Icons.menu, ),
                  ),
                ),

                // Dashboard title - centered
                Positioned(
                  top: sh(37.1),
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
                  top: sh(37.1),
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
                  top: sh(80),
                  left: sw(362),
                  child: Obx(() => Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      padding: EdgeInsets.zero,
                      activeColor: FColors.primaryColor,
                      inactiveThumbColor: FColors.secondaryColor,
                      inactiveTrackColor: FColors.white,
                      value: c.isOnline.value,
                      onChanged: c.toggleOnline,
                    ),
                  )),
                ),

                // Requests list - starting at 147 from top, 10 from left
                Positioned(
                  top: sh(157),
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