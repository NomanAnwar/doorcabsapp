import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart' show Get;

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
                  _drawerItem(Icons.account_balance_wallet, 'Rate', () {}, sw),
                  _drawerItem(Icons.account_balance_wallet, 'chat', () {}, sw),
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

class PassengerDrawer extends StatelessWidget {
  const PassengerDrawer({Key? key}) : super(key: key);

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
            // Header section (profile)
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
                    'Passenger Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: sw(16)),
                  ),
                ],
              ),
            ),
            SizedBox(height: sw(30)),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(Icons.home, 'Home', () => Get.back(), sw),
                  _drawerItem(Icons.home, 'Ride Type', () => Get.back(), sw),
                  _drawerItem(Icons.history, 'Ride History', () {}, sw),
                  _drawerItem(Icons.payment, 'Payments', () {}, sw),
                  _drawerItem(Icons.favorite, 'Saved Locations', () {}, sw),
                  _drawerItem(Icons.support, 'Support', () {}, sw),
                  _drawerItem(Icons.support, 'Rate', () {}, sw),
                  _drawerItem(Icons.support, 'chat', () {}, sw),
                ],
              ),
            ),

            // Logout at bottom
            Padding(
              padding: EdgeInsets.all(sw(20)),
              child: _drawerItem(Icons.logout, 'Logout', () {}, sw, isLogout: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
      IconData icon,
      String title,
      VoidCallback onTap,
      double Function(double) sw, {
        bool isLogout = false,
      }) {
    return ListTile(
      leading: Icon(icon, size: sw(24), color: isLogout ? Colors.red : Colors.black),
      title: Text(
        title,
        style: TextStyle(
          fontSize: sw(16),
          color: isLogout ? Colors.red : Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }
}
