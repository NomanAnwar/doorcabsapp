import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class FElevatedButtonTheme {
  FElevatedButtonTheme._();

  // Light theme buttons
  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: FColors.buttonPrimary,
      foregroundColor: FColors.textWhite,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      elevation: 0,
    ),
  );

  // Dark theme buttons
  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: FColors.buttonPrimary,
      foregroundColor: FColors.textWhite,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      elevation: 0,
    ),
  );
}
