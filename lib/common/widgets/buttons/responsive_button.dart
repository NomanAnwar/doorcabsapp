import 'package:flutter/material.dart';

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? icon;
  final String? assetIcon; // <-- to support asset icons like PNGs
  final Color? iconColor;
  final double? iconSize;

  /// Screen scale functions
  final double Function(double w) sw;
  final double Function(double h) sh;
  final double baseWidth;
  final double screenWidth;

  const ResponsiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.sw,
    required this.sh,
    required this.baseWidth,
    required this.screenWidth,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.width = double.infinity,
    this.height = 48,
    this.borderRadius = 12,
    this.textStyle,
    this.icon,
    this.assetIcon,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: sw(width),
      height: sh(height),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: assetIcon != null
            ? Image.asset(
          assetIcon!,
          width: sw(24),
          height: sh(24),
          color: iconColor,
        )
            : (icon != null
            ? Icon(
          icon,
          size: iconSize ?? sw(20),
          color: iconColor ?? textColor,
        )
            : const SizedBox.shrink()),
        label: Text(
          text,
          style: textStyle ??
              TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 16 * screenWidth / baseWidth, // responsive font size
              ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sw(borderRadius)),
          ),
        ),
      ),
    );
  }
}
