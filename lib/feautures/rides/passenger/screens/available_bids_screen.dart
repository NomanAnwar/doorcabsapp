import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/positioned/positioned_scaled.dart';
import '../../../../common/widgets/buttons/f_primary_button.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/available_bids_controller.dart';

class AvailableBidsScreen extends StatelessWidget {
  const AvailableBidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AvailableBidsController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Back button
          PositionedScaled(
            top: 43,
            left: 23,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: Get.back,
            ),
          ),

          /// Scrollable bids list
          PositionedScaled(
            top: 88,
            left: 10,
            right: 10,
            bottom: 332,
            child: Obx(() => ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: c.bids.length,
              itemBuilder: (_, i) {
                final bid = c.bids[i];
                return _buildBidItem(bid, c);
              },
            )),
          ),

          /// Bottom container
          PositionedScaled(
            top: 624,
            left: 0,
            right: 0,
            child: Container(
              height: 332,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Stack(
                children: [
                  /// "x drivers viewing" text
                  PositionedScaled(
                    top: 21, // 645 - 624 = 21
                    left: 15,
                    child: Obx(() => Text(
                      "${c.viewingDrivers.value} drivers are viewing your request",
                      style: FTextTheme.lightTextTheme.bodyMedium,
                    )),
                  ),

                  /// Driver avatars row
                  PositionedScaled(
                    top: 18, // 642 - 624 = 18
                    left: 291,
                    width: 128,
                    height: 24,
                    child: Obx(() => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: c.driverAvatars.take(6).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 1),
                      itemBuilder: (_, index) {
                        final avatar = c.driverAvatars[index];
                        return CircleAvatar(
                          radius: 12,
                          backgroundImage: AssetImage(avatar),
                        );
                      },
                    )
                    ),
                  ),

                  /// Grey sub-container
                  PositionedScaled(
                    top: 54, // 678 - 624 = 54
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 241,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E3E3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Stack(
                        children: [
                          /// "Waiting for more bids..." text
                          PositionedScaled(
                            top: 22, // 700 - 678 = 22
                            left: 15,
                            child: const Text("Waiting for more bids..."),
                          ),

                          /// Countdown timer
                          PositionedScaled(
                            top: 25, // 703 - 678 = 25
                            right: 22,
                            child: Obx(() => Text(
                              "${c.remainingSeconds.value}s",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                          ),

                          /// Progress bar
                          PositionedScaled(
                            top: 51, // 729 - 678 = 51
                            left: 15,
                            right: 15,
                            child: Obx(() => LinearProgressIndicator(
                              value: c.remainingSeconds.value / 60,
                              color: FColors.secondaryColor,
                            )),
                          ),

                          /// Black container (Auto accept)
                          PositionedScaled(
                            top: 82, // 760 - 678 = 82
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 77,
                              decoration: BoxDecoration(
                                color: const Color(0xFF595959),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 14),
                                    child: Icon(Icons.shield, size: 34, color: Colors.white),
                                  ),
                                  const Text(
                                    "Auto accept offers",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 14),
                                    child: Obx(() => Switch(
                                      value: c.autoAccept.value,
                                      onChanged: (v) => c.autoAccept.value = v,
                                    )),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          /// Cancel request button
                          PositionedScaled(
                            top: 180, // 858 - 678 = 180
                            left: 41,
                            width: 358,
                            height: 48,
                            child: FPrimaryButton(
                              text: "Cancel Request",
                              onPressed: c.cancelRequest,
                              backgroundColor: const Color(0xFF595959),
                              designBorderRadius: 12,
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
        ],
      ),
    );
  }

  Widget _buildBidItem(Map<String, dynamic> bid, AvailableBidsController c) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 420,
      height: 145,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Stack(
        children: [
          /// Driver image
          PositionedScaled(
            top: 19, // 107 - 88 = 19
            left: 24,
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: bid['driver']['profileImage'] ?? "",
                  fit: BoxFit.cover,
                  width: 64,
                  height: 64,
                  placeholder: (_, __) => Image.asset("assets/images/profile_img_sample.png"),
                  errorWidget: (_, __, ___) => Image.asset("assets/images/profile_img_sample.png"),
                ),
              ),
            ),
          ),

          /// Driver badge
          PositionedScaled(
            top: 63, // 151.42 - 88 = 63
            left: 80.33 - 10, // adjust relative
            child: const Icon(Icons.verified, color: Colors.green, size: 12),
          ),

          /// Star + rating
          PositionedScaled(
            top: 95, // 183 - 88
            left: 23,
            child: const Icon(Icons.star, color: Colors.amber, size: 14),
          ),
          PositionedScaled(
            top: 99, // 187 - 88
            left: 42,
            child: Text(
              (bid['driver']['avgRating'] == null || bid['driver']['avgRating'].toString().isEmpty)
                  ? '0'
                  : bid['driver']['avgRating'].toString(),
              // bid['rating'].toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          PositionedScaled(
            top: 99,
            left: 62,
            child: Text(
              (bid['driver']?['total_ratings'] == null || bid['driver']['total_ratings'].toString().isEmpty)
                  ? '(0)'
                  : "(${bid['driver']['total_ratings']})",
              // "(${bid['totalRatings']})",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),

          /// Driver category
          PositionedScaled(
            top: 111, // 199 - 88
            left: 23,
            child: Text(
              bid['driver']['category'],
              // bid['category'],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),

          /// Driver name
          PositionedScaled(
            top: 23, // 111 - 88
            left: 104,
            child: Text(
                "${bid['driver']?['name']?['firstName'] ?? ''} ${bid['driver']?['name']?['lastName'] ?? ''}",
                // "name",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),

          /// Car model
          PositionedScaled(
            top: 46, // 134 - 88
            left: 104,
            child: Text(
              "${bid['driver']?['vehicleType'] ?? ''}, ${bid['driver']?['vehicle'] ?? ''}",
              // bid['car'],
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),

          /// Fare
          PositionedScaled(
            top: 98, // 186 - 88
            left: 110,
            child: Text(
              "PKR ${bid['fareOffered']}",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),

          /// ETA + distance
          PositionedScaled(
            top: 12, // 100 - 88
            right: 66,
            child: Text("${bid['eta'] ?? ''}"),
            // child: Text("${bid['eta']} min"),
          ),
          PositionedScaled(
            top: 12,
            right: 15,
            child: Text("${bid['distance'] ?? ''}"),
            // child: Text("${bid['distance']} km"),
          ),

          /// Accept button
          PositionedScaled(
            top: 34, // 122 - 88
            right: 20,
            width: 120,
            height: 30,
            child:
            // Obx(() {
              // final progress = bid['progress'].value as double;
              // return
                ElevatedButton(
                onPressed: () => c.acceptBid(bid),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FColors.secondaryColor,
                  // backgroundColor: FColors.secondaryColor.withOpacity(0.1 + 0.9 * progress),
                ),
                child: const Text("Accept"),
              ),
            // ;
            // }),
          ),

          /// Reject button
          PositionedScaled(
            top: 84, // 172 - 88
            right: 20,
            child: OutlinedButton(
              onPressed: () => c.rejectBid(bid),
              child: const Text("Reject"),
            ),
          ),
        ],
      ),
    );
  }
}
