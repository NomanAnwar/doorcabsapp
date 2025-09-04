import 'package:flutter/material.dart';
import '../../../../utils/constants/colors.dart';

class FPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double? designWidth; // Renamed for clarity: this is the design value
  final double designHeight; // Renamed for clarity
  final double designBorderRadius; // Renamed for clarity
  final TextStyle? textStyle;
  final IconData? icon;
  final String? assetIcon;
  final Color? iconColor;

  const FPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = FColors.secondaryColor,
    this.textColor = Colors.white,
    this.designWidth, // Pass the design value (e.g., 360)
    this.designHeight = 48, // Pass the design value
    this.designBorderRadius = 14, // Pass the design value
    this.textStyle,
    this.icon,
    this.assetIcon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Get screen dimensions HERE, inside build.
    final screenSize = MediaQuery.of(context).size;
    const baseWidth = 440.0;

    // 2. Define scaling functions INTERNALLY.
    double sw(double w) => w * screenSize.width / baseWidth;

    // 3. NOW use the scaling functions to calculate the FINAL values.
    final double? finalWidth = designWidth != null ? sw(designWidth!) : null;
    final double finalHeight = sw(designHeight); // Scale the height
    final double finalBorderRadius = sw(designBorderRadius); // Scale the borderRadius
    final double finalFontSize = sw(16); // Scale the font size

    return SizedBox(
      // 4. Use the scaled values here
      width: finalWidth,
      height: finalHeight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: _buildIcon(sw),
        label: Text(
          text,
          style: textStyle ??
              TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: finalFontSize,
              ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(finalBorderRadius),
          ),
        ),
      ),
    );
  }

  // Helper method to build the icon - takes the scaling function as a parameter
  Widget _buildIcon(double Function(double) sw) {
    if (assetIcon != null) {
      return Image.asset(
        assetIcon!,
        width: sw(24), // Scale inside the method
        height: sw(24),
        color: iconColor,
      );
    } else if (icon != null) {
      return Icon(
        icon,
        size: sw(20), // Scale inside the method
        color: iconColor ?? textColor,
      );
    }
    return const SizedBox.shrink();
  }
}