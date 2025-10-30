// lib/feautures/rides/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../controllers/chat_controller.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  String _formatTs(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final suf = dt.hour >= 12 ? "PM" : "AM";
    final min = dt.minute.toString().padLeft(2, '0');
    return "$month-$day-$year $hour:$min $suf";
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ChatController());
    final displayData = c.getDisplayData();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              // Back button
              Positioned(
                top: sh(30),
                left: sw(33),
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: sw(28),
                    height: sh(28),
                    child: Icon(
                      Icons.arrow_back,
                      size: sw(28),
                    ),
                  ),
                ),
              ),

              // Driver Details Card
              Positioned(
                top: sh(68),
                left: sw(10),
                right: sw(10),
                child: Container(
                  width: sw(420),
                  height: sh(120),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E3E3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Profile Image
                      Positioned(
                        top: sh(20),
                        left: sw(17),
                        child: Container(
                          width: sw(65),
                          height: sh(65),
                          child: ClipOval(
                            child: Image.network(
                              displayData['avatar'] ?? "assets/images/profile_img_sample.png",
                              fit: BoxFit.cover,
                              width: sw(65),
                              height: sh(65),
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    size: sw(30),
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Driver Badge
                      if (displayData['badge'] != null && displayData['badge']!.isNotEmpty)
                        Positioned(
                          top: sh(60),
                          left: sw(80),
                          child: Container(
                            width: sw(12),
                            height: sh(12),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                      // Name
                      Positioned(
                        top: sh(15),
                        left: sw(113),
                        child: Text(
                          displayData['name'] ?? "User",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16 * screenWidth / baseWidth,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      // Vehicle Type
                      if (displayData['car'] != null && displayData['car'] != 'Your Vehicle')
                        Positioned(
                          top: sh(35),
                          left: sw(113),
                          child: Text(
                            displayData['car']!,
                            style: TextStyle(
                              fontSize: 14 * screenWidth / baseWidth,
                            ),
                          ),
                        ),

                      // Rating Row
                      if (displayData['avgRating'] != null && displayData['avgRating']!.isNotEmpty)
                        Positioned(
                          top: displayData['car'] != null && displayData['car'] != 'Your Vehicle' ? sh(55) : sh(45),
                          left: sw(113),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: sw(14),
                              ),
                              SizedBox(width: sw(4)),
                              Text(
                                displayData['avgRating']!,
                                style: TextStyle(
                                  fontSize: 12 * screenWidth / baseWidth,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: sw(4)),
                              if (displayData['totalRatings'] != null && displayData['totalRatings']!.isNotEmpty)
                                Text(
                                  "(${displayData['totalRatings']!})",
                                  style: TextStyle(
                                    fontSize: 12 * screenWidth / baseWidth,
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // Driver Category
                      if (displayData['category'] != null && displayData['category']!.isNotEmpty)
                        Positioned(
                          top: _getCategoryTopPosition(displayData, sh),
                          left: sw(113),
                          child: Text(
                            displayData['category']!,
                            style: TextStyle(
                              fontSize: 12 * screenWidth / baseWidth,
                            ),
                          ),
                        ),

                      // Estimated Arrival Time
                      Positioned(
                        top: _getEtaTopPosition(displayData, sh),
                        left: sw(113),
                        child: Text(
                          "Estimated Arrival Time ${displayData['etaText'] ?? 'Calculating...'}",
                          style: TextStyle(
                            fontSize: 12 * screenWidth / baseWidth,
                          ),
                        ),
                      ),

                      // Call Button
                      if (displayData['phone'] != null && displayData['phone']!.isNotEmpty)
                        Positioned(
                          top: sh(30),
                          right: sw(25),
                          child: GestureDetector(
                            onTap: () {
                              final phone = displayData['phone']!;
                              launchUrl(Uri(scheme: 'tel', path: phone));
                            },
                            child: Container(
                              width: sw(30),
                              height: sh(30),
                              decoration: const BoxDecoration(
                                // color: Color(0xFF003566),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset("assets/images/call.png", width: sw(30), height: sh(30))
                              // Icon(
                              //   Icons.call,
                              //   color: Colors.white,
                              //   size: sw(16),
                              // ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Messages list - Use remaining space dynamically
              Positioned(
                top: sh(180),
                left: 0,
                right: 0,
                bottom: sh(70),
                child: Obx(
                      () => ListView.builder(
                    controller: c.scrollController,
                    padding: EdgeInsets.symmetric(horizontal: sw(10), vertical: sh(12)),
                    itemCount: c.messages.length,
                    itemBuilder: (_, i) {
                      final m = c.messages[i];
                      final isMe = m['from'] == 'me';

                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: sh(8)),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isMe) SizedBox(width: sw(10)),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  // Message Bubble
                                  Container(
                                    constraints: BoxConstraints(maxWidth: sw(280)),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: sw(14),
                                      vertical: sh(12),
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3E3E3),
                                      borderRadius: BorderRadius.only(
                                        topLeft: isMe ? Radius.circular(sw(10)) : Radius.zero,
                                        topRight: isMe ? Radius.zero : Radius.circular(sw(10)),
                                      ),
                                    ),
                                    child: Text(
                                      m['text'] ?? "",
                                      style: TextStyle(
                                        fontSize: 14 * screenWidth / baseWidth,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  // Timestamp
                                  Container(
                                    margin: EdgeInsets.only(top: sh(4)),
                                    padding: EdgeInsets.only(
                                      left: isMe ? 0 : sw(10),
                                      right: isMe ? sw(10) : 0,
                                    ),
                                    child: Text(
                                      _formatTs(m['ts']),
                                      style: TextStyle(
                                        fontSize: 11 * screenWidth / baseWidth,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isMe) SizedBox(width: sw(10)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Input field - Fixed at bottom
              Positioned(
                left: sw(10),
                right: sw(10),
                bottom: sh(10),
                child: Container(
                  width: sw(420),
                  height: sh(51),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E3E3),
                    borderRadius: BorderRadius.circular(sw(14)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: sw(16)),
                          child: TextField(
                            controller: c.inputCtrl,
                            style: TextStyle(
                              fontSize: 14 * screenWidth / baseWidth,
                            ),
                            decoration: InputDecoration(
                              hintText: "Write Message",
                              hintStyle: TextStyle(
                                color: Colors.black54,
                                fontSize: 14 * screenWidth / baseWidth,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: c.sendMessage,
                        child: Container(
                          margin: EdgeInsets.only(right: sw(12)),
                          width: sw(24),
                          height: sh(24),
                          child: Icon(
                            Icons.send,
                            color: const Color(0xFF003566),
                            size: sw(24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for dynamic positioning - updated to use sh function
  double _getCategoryTopPosition(Map<String, String?> displayData, double Function(double) sh) {
    double top = 75;
    if (displayData['avgRating'] == null || displayData['avgRating']!.isEmpty) {
      top -= 25;
    }
    if (displayData['car'] == null || displayData['car'] == 'Your Vehicle') {
      top -= 25;
    }
    return sh(top);
  }

  double _getEtaTopPosition(Map<String, String?> displayData, double Function(double) sh) {
    double top = 90;
    if (displayData['category'] == null || displayData['category']!.isEmpty) {
      top -= 10;
    }
    if (displayData['avgRating'] == null || displayData['avgRating']!.isEmpty) {
      top -= 15;
    }
    if (displayData['car'] == null || displayData['car'] == 'Your Vehicle') {
      top -= 15;
    }
    return sh(top);
  }
}