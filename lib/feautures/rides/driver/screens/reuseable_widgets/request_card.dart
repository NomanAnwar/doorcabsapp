import 'package:doorcab/utils/constants/colors.dart';
import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import 'package:flutter/material.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../models/request_model.dart';

class RequestCard extends StatelessWidget {
  final RequestModel request;
  final VoidCallback onTapCard;
  final VoidCallback onOfferPressed;
  final double Function(double) sw;
  final double Function(double) sh;

  const RequestCard({
    Key? key,
    required this.request,
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
        height: sh(155),
        margin: EdgeInsets.symmetric(horizontal: sw(2), vertical: sh(2)),
        padding: EdgeInsets.symmetric(horizontal: sw(8), vertical: sh(6)),
        decoration: BoxDecoration(
          color: FColors.phoneInputField,
          borderRadius: BorderRadius.circular(sw(20)),
        ),
        child: Stack(
          children: [
            // Passenger Image
            Positioned(
              top: sh(10),
              left: sw(0),
              child: Container(
                width: sw(70),
                height: sh(70),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: request.passengerImage.isNotEmpty
                        ? NetworkImage(request.passengerImage)
                        : AssetImage(FImages.profile_img_sample)
                    as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Verified badge
            Positioned(
              top: sh(50),
              left: sw(63),
              child: Icon(Icons.verified, color: Colors.green, size: sw(12)),
            ),

            // Name + rating
            Positioned(
              top: sh(0),
              left: sw(85),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    request.passengerName.toUpperCase(),
                    style: FTextTheme.lightTextTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: sw(8)),
                  Row(
                    children: [
                      Icon(Icons.star,
                          size: sw(14), color: const Color(0xFFFFC300)),
                      SizedBox(width: sw(4)),
                      Text(
                        request.rating.toStringAsFixed(2),
                        style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(width: sw(4)),
                      Text(
                        '(25)',
                        style: FTextTheme.lightTextTheme.labelSmall!
                            .copyWith(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ETA + Distance
            Positioned(
              top: sh(80),
              right: sw(30),
              child: Row(
                children: [
                  Text(
                    '${request.etaMinutes} min',
                    style: FTextTheme.lightTextTheme.labelSmall!
                        .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: sw(10)),
                  Text(
                    '${request.distanceKm.toStringAsFixed(1)} km',
                    style: FTextTheme.lightTextTheme.labelSmall!
                        .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            // Pickup
            Positioned(
              top: sh(30),
              left: sw(85),
              right: sw(15),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Pickup: ',
                      style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: request.pickupAddress.address,
                      style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                          fontSize: 12, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            // Dropoff
            Positioned(
              top: sh(53),
              left: sw(85),
              right: sw(15),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Dropoff: ',
                      style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: request.dropoffAddress[0].address,
                      style: FTextTheme.lightTextTheme.labelSmall!.copyWith(
                          fontSize: 12, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            // PKR amount
            Positioned(
              bottom: sh(3),
              left: sw(5),
              child: Container(
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
                      decoration: BoxDecoration(
                        color: FColors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Image.asset("assets/images/cash.png"),
                    ),
                    SizedBox(width: sw(8)),
                    Text(
                      'PKR ${request.offerAmount.toStringAsFixed(0)}',
                      style: FTextTheme.lightTextTheme.headlineSmall!
                          .copyWith(fontWeight: FontWeight.w600, color: FColors.white),
                    ),
                  ],
                ),
              ),
            ),

            // Offer button (without timer)
            Positioned(
              bottom: sh(3),
              right: sw(5),
              child: GestureDetector(
                onTap: onOfferPressed,
                child: Container(
                  width: sw(185),
                  height: sh(37),
                  decoration: BoxDecoration(
                    color: FColors.primaryColor,
                    borderRadius: BorderRadius.circular(sw(10)),
                  ),
                  child: Center(
                    child: Text(
                      "Offer Your Fare",
                      style: FTextTheme.lightTextTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}