import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../utils/theme/custom_theme/elevatedButton_theme.dart';
import '../../../utils/theme/custom_theme/text_theme.dart';

class FElevatedButton extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final VoidCallback onPressed;

  const FElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: FElevatedButtonTheme.lightElevatedButtonTheme.style,
        child: Text(text, style: FTextTheme.darkTextTheme.titleMedium!.copyWith(),),
      ),
    );
  }
}
