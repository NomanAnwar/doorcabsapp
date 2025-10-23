import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/buttons/f_primary_button.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/theme/custom_theme/text_theme.dart';
import '../controllers/available_bids_controller.dart';

class AvailableBidsScreen extends StatelessWidget {
  const AvailableBidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AvailableBidsController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Reference device size (iPhone 16 Pro Max)
    const baseWidth = 440.0;
    const baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              /// Back button
              Positioned(
                top: sh(43),
                left: sw(23),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, size: sw(28)),
                  onPressed: Get.back,
                ),
              ),

              /// Scrollable bids list
              Positioned(
                top: sh(88),
                left: sw(10),
                right: sw(10),
                bottom: sh(332),
                child: Obx(() => ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: c.bids.length,
                  itemBuilder: (_, i) {
                    final bid = c.bids[i];
                    return _buildBidItem(bid, c, sw, sh);
                  },
                )),
              ),

              /// Bottom container
              Positioned(
                top: sh(624),
                left: 0,
                right: 0,
                child: Container(
                  height: sh(332),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(sw(14))),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: sw(6)
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      /// "x drivers viewing" text
                      Positioned(
                        top: sh(21),
                        left: sw(15),
                        width: sw(203),
                        child: Obx(() => Text(
                          "${c.viewingDrivers.value} drivers are viewing your request",
                          style: FTextTheme.lightTextTheme.labelSmall!
                              .copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: FTextTheme.lightTextTheme
                                .labelSmall!.fontSize! *
                                screenWidth /
                                baseWidth,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )),
                      ),

                      /// Driver avatars row
                      Positioned(
                        top: sh(18),
                        left: sw(291),
                        width: sw(108),
                        height: sh(24),
                        child: Obx(() => ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: c.driverAvatars.take(6).length,
                          separatorBuilder: (_, __) => SizedBox(width: sw(0)),
                          itemBuilder: (_, index) {
                            final avatar = c.driverAvatars[index];
                            return CircleAvatar(
                              radius: sw(12),
                              backgroundImage: AssetImage(avatar),
                            );
                          },
                        )),
                      ),

                      /// Grey sub-container
                      Positioned(
                        top: sh(54),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: sh(241),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3E3E3),
                            borderRadius: BorderRadius.circular(sw(14)),
                          ),
                          child: Stack(
                            children: [
                              /// "Waiting for more bids..." text
                              Positioned(
                                top: sh(22),
                                left: sw(15),
                                child: Text(
                                  "Accept an offer from a driver",
                                  style: FTextTheme.lightTextTheme.titleSmall!
                                      .copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: FTextTheme.lightTextTheme
                                        .titleSmall!.fontSize! *
                                        screenWidth /
                                        baseWidth,
                                  ),
                                ),
                              ),

                              /// Countdown timer
                              Positioned(
                                top: sh(25),
                                right: sw(22),
                                child: Obx(() => Text(
                                  "${c.remainingSeconds.value}s",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: sw(16),
                                  ),
                                )),
                              ),

                              /// Progress bar
                              Positioned(
                                top: sh(51),
                                left: sw(15),
                                right: sw(15),
                                child: Obx(() => LinearProgressIndicator(
                                  value: c.remainingSeconds.value / 60,
                                  color: FColors.primaryColor,
                                  backgroundColor: FColors.chipBg,
                                )),
                              ),

                              /// Black container (Auto accept)
                              Positioned(
                                top: sh(82),
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: sh(77),
                                  decoration: BoxDecoration(
                                    color: FColors.chipBg,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: sw(14)),
                                        child: SvgPicture.asset(
                                          'assets/images/forward.svg',
                                          width: sw(34),
                                          height: sh(34),
                                        ),
                                      ),
                                      Container(
                                        width: sw(300),
                                        height: sh(42),
                                        child: Text(
                                          "Auto Accept the nearest driver for PKR 250",
                                          maxLines: 2,
                                          style: FTextTheme.darkTextTheme.titleSmall!
                                              .copyWith(
                                            fontWeight: FontWeight.w500,
                                            fontSize: FTextTheme.darkTextTheme
                                                .titleSmall!.fontSize! *
                                                screenWidth /
                                                baseWidth,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(right: sw(14)),
                                        child: Obx(() => Transform.scale(
                                          scale: 0.9,
                                          child: Switch(
                                            padding: EdgeInsets.zero,
                                            activeColor: FColors.secondaryColor,
                                            inactiveTrackColor: FColors.primaryColor,
                                            value: c.autoAccept.value,
                                            onChanged: (v) => c.autoAccept.value = v,
                                          ),
                                        )),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              /// Cancel request button
                              Positioned(
                                top: sh(180),
                                left: sw(41),
                                width: sw(358),
                                height: sh(48),
                                child: FPrimaryButton(
                                  text: "Cancel Request",
                                  onPressed: c.cancelRequest,
                                  backgroundColor: FColors.chipBg,
                                  designBorderRadius: sw(12),
                                  textStyle: FTextTheme.darkTextTheme.titleSmall!
                                    .copyWith(
                                fontWeight: FontWeight.w500,
                                  fontSize: FTextTheme.darkTextTheme
                                      .titleSmall!.fontSize! *
                                      screenWidth /
                                      baseWidth,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBidItem(Map<String, dynamic> bid, AvailableBidsController c, double Function(double) sw, double Function(double) sh) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: sh(8)),
      width: sw(420),
      height: sh(145),
      decoration: BoxDecoration(
        color: FColors.phoneInputField,
        borderRadius: BorderRadius.circular(sw(12)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: sw(4)
          )
        ],
      ),
      child: Stack(
        children: [
          /// Driver image
          Positioned(
            top: sh(19),
            left: sw(24),
            child: CircleAvatar(
              radius: sw(32),
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: (bid['driver']['profileImage'] != null &&
                      bid['driver']['profileImage'].toString().isNotEmpty)
                      ? bid['driver']['profileImage'].toString()
                      : "https://via.placeholder.com/150",
                  fit: BoxFit.cover,
                  width: sw(64),
                  height: sh(64),
                  placeholder: (_, __) => Image.asset("assets/images/profile_img_sample.png"),
                  errorWidget: (_, __, ___) => Image.asset("assets/images/profile_img_sample.png"),
                ),
              ),
            ),
          ),

          /// Driver badge
          Positioned(
            top: sh(63),
            left: sw(80.33),
            child: Icon(Icons.verified, color: Colors.green, size: sw(12)),
          ),

          /// Star + rating
          Positioned(
            top: sh(95),
            left: sw(23),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: sw(14)),
                SizedBox(width: sw(5)),
                Text(
                  (bid['driver']['avgRating'] == null || bid['driver']['avgRating'].toString().isEmpty)
                      ? '0'
                      : bid['driver']['avgRating'].toString(),
                  style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                    fontSize: 10,
                  ),
                ),
                SizedBox(width: sw(4)),
                Text(
                  (bid['driver']?['total_ratings'] == null || bid['driver']['total_ratings'].toString().isEmpty)
                      ? '(0)'
                      : "(${bid['driver']['total_ratings']})",
                  style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),


          /// Driver category
          Positioned(
            top: sh(115),
            left: sw(23),
            child: Text(
              bid['driver']['category'],
              style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                  fontSize: 10,
              ),
            ),
          ),

          /// Driver name
          Positioned(
            top: sh(23),
            left: sw(104),
            child: Text(
              ("${bid['driver']?['name']?['firstName'] ?? ''} ${bid['driver']?['name']?['lastName'] ?? ''}").toUpperCase(),
              style: FTextTheme.lightTextTheme.bodyLarge,
            ),
          ),

          /// Car model
          Positioned(
            top: sh(46),
            left: sw(104),
            child: Text(
              "${bid['driver']?['vehicleType'] ?? ''}, ${bid['driver']?['vehicle'] ?? ''}",
              style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                fontSize: 10
              ),
            ),
          ),

          /// Fare
          Positioned(
            top: sh(95),
            left: sw(110),
            child: Row(
              children: [
                Text(
                  "PKR ",
                  style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                  ),
                ),
                Text(
                  "${bid['fareOffered']}",
                  style: FTextTheme.lightTextTheme.displaySmall!.copyWith(
                    fontWeight: FontWeight.w600
                  ),
                ),
              ],
            ),
          ),

          /// ETA + distance
          Positioned(
            top: sh(12),
            right: sw(25),
            child: Row(
              mainAxisSize: MainAxisSize.min, // ✅ keeps Row only as wide as needed
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "${bid['eta'] ?? ''}",
                  style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: sw(8)), // ✅ spacing between ETA and distance
                Text(
                  "${bid['distance'] ?? ''}",
                  style: FTextTheme.lightTextTheme.bodyLarge!.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),


          /// Accept button with progress
          Positioned(
            top: sh(34),
            right: sw(10),
            width: sw(133),
            height: sh(37),
            child: Obx(() {
              double progress = 0.0;
              int secondsLeft = 0;
              if (bid.containsKey('timer')) {
                try {
                  secondsLeft = (bid['timer'] as RxInt).value;
                  progress = ((20 - secondsLeft) / 20).clamp(0.0, 1.0);
                } catch (_) {
                  progress = 0.0;
                }
              } else if (bid.containsKey('progress')) {
                final p = bid['progress'];
                if (p is RxDouble) {
                  progress = (p.value).clamp(0.0, 1.0);
                } else if (p is double) {
                  progress = p.clamp(0.0, 1.0);
                }
              }

              final overlayColor = bid.containsKey('progressColor')
                  ? FColors.secondaryColor
                  : FColors.rideTypeBg;

              return GestureDetector(
                onTap: () => c.acceptBid(bid),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(sw(8)),
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      // base background
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: FColors.primaryColor,
                      ),

                      // colored filling progress
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          height: double.infinity,
                          color: overlayColor,
                        ),
                      ),

                      // label on top
                      Center(
                        child: Text(
                          "Accept",
                          style: FTextTheme.lightTextTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          /// Reject button
          Positioned(
            top: sh(84),
            right: sw(10),
            width: sw(133),
            height: sh(37),
            child: ElevatedButton(
              onPressed: () => c.rejectBid(bid),
              style: ElevatedButton.styleFrom(
                backgroundColor: FColors.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(sw(8)),
                ),
              ),
              child: Text(
                "Reject",
                style: FTextTheme.darkTextTheme.titleMedium?.copyWith(
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}