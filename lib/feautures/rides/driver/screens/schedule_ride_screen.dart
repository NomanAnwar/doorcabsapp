import 'package:doorcab/feautures/rides/driver/screens/reuseable_widgets/driver_bottom_nav.dart';
import 'package:flutter/material.dart';

class ScheduleRideScreen extends StatelessWidget {
  const ScheduleRideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          Center(
            child: Text(
              'Schedule Ride Screen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// Custom Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DriverBottomNav(
              currentIndex: 1, // Schedule Ride is active
              isRequestsListActive: false,
            ),
          ),
        ],
      ),
    );
  }
}