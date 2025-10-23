import 'package:doorcab/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import '../../../../../utils/theme/custom_theme/text_theme.dart';

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
    final double progress =
    ((totalSeconds - remainingSeconds) / totalSeconds).clamp(0.0, 1.0);

    const Color blue = FColors.secondaryColor;
    const Color yellow = FColors.primaryColor;
    final bool isEnding = remainingSeconds <= 60;
    final Color progressColor =
    isEnding ? yellow : Color.lerp(blue, yellow, progress) ?? blue;

    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(sw(10)),
        child: SizedBox(
          width: sw(160),
          height: sw(37),
          child: Stack(
            fit: StackFit.expand, // safer
            children: [
              Container(color: blue),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  color: progressColor,
                ),
              ),
              Center(
                child: Text(
                  "Offer Your Fare",
                  style: FTextTheme.lightTextTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}
