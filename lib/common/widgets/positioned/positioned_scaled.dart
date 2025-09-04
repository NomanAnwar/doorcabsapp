import 'package:flutter/material.dart';

class PositionedScaled extends StatelessWidget {
  final double? top, left, right, bottom;
  final double? width, height;
  final Widget child;

  const PositionedScaled({
    super.key,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.width,
    this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    const baseWidth = 440.0; // iPhone 16 Pro Max width
    const baseHeight = 956.0; // iPhone 16 Pro Max height

    // Scaling helpers
    double sw(double w) => w * screenSize.width / baseWidth;
    double sh(double h) => h * screenSize.height / baseHeight;

    Widget scaledChild = child;

    // If width/height provided → wrap in SizedBox
    if (width != null || height != null) {
      scaledChild = SizedBox(
        width: width != null ? sw(width!) : null,
        height: height != null ? sh(height!) : null,
        child: child,
      );
    }

    return Positioned(
      top: top != null ? sh(top!) : null,
      left: left != null ? sw(left!) : null,
      right: right != null ? sw(right!) : null,
      bottom: bottom != null ? sh(bottom!) : null,
      child: scaledChild,
    );
  }
}
