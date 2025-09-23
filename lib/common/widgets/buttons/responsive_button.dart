import 'package:flutter/material.dart';

class ResponsiveButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? icon;
  final String? assetIcon;
  final Color? iconColor;
  final double? iconSize;
  final Widget? child; // 👈 new for custom UI (spinner, etc.)

  /// Screen scale functions
  final double Function(double w) sw;
  final double Function(double h) sh;
  final double baseWidth;
  final double screenWidth;

  const ResponsiveButton({
    super.key,
    this.text,
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
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: sw(width),
      height: sh(height),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sw(borderRadius)),
          ),
        ),
        child: child ??
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (assetIcon != null)
                  Image.asset(
                    assetIcon!,
                    width: sw(24),
                    height: sh(24),
                    color: iconColor,
                  )
                else if (icon != null)
                  Icon(
                    icon,
                    size: iconSize ?? sw(20),
                    color: iconColor ?? textColor,
                  ),
                if (assetIcon != null || icon != null) SizedBox(width: sw(8)),
                if (text != null)
                  Text(
                    text!,
                    style: textStyle ??
                        TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16 * screenWidth / baseWidth,
                        ),
                  ),
              ],
            ),
      ),
    );
  }
}
