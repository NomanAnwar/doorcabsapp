import 'package:doorcab/feautures/rides/driver/screens/reuseable_widgets/offer_button.dart';
import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../utils/constants/image_strings.dart';
import '../../models/request_model.dart';

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
        height: sh(170),
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
                  image: request.passengerImage.isNotEmpty
                      ? NetworkImage(request.passengerImage)
                      : AssetImage(FImages.profile_img_sample) as ImageProvider,
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
                        TextSpan(text: request.pickupAddress.address),
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
                        TextSpan(text: request.dropoffAddress[0].address),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // PKR amount button
                      Container(
                        width: sw(130),
                        height: sh(37),
                        padding: EdgeInsets.symmetric(horizontal: sw(8), vertical: sh(6)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003566),
                          borderRadius: BorderRadius.circular(sw(10)),
                        ),
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Icon(Icons.local_offer, size: sw(18), color: Colors.white),
                            Container(
                              width:sw(48),
                              height: sh(30),
                              // color: FColors.white,
                              padding: EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: FColors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Image.asset(
                                "assets/images/cash.png",
                              // width: sw(25),
                              // height: sh(25),
                                ),
                            ),
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