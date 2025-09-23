import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
      width: sw(140),
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
            // if (remainingSeconds > 0)
            //   SizedBox(
            //     width: sw(14),
            //     height: sw(14),
            //     child: CircularProgressIndicator(
            //       value: progress,
            //       strokeWidth: sw(2.2),
            //       color: Colors.black,
            //     ),
            //   )
            // else
            //   SizedBox(width: sw(14), height: sw(14)),
            // SizedBox(width: sw(8)),
            Text(
              "Offer Your Fare",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: sw(12)),
            ),
            // SizedBox(width: sw(6)),
            // if (remainingSeconds > 0)
            //   Text(
            //     '$remainingSeconds s',
            //     style: TextStyle(fontWeight: FontWeight.w600, fontSize: sw(12)),
            //   )
          ],
        ),
      ),
    );
  }
}