import 'package:doorcab/utils/theme/custom_theme/text_theme.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class FElevatedButtonTheme {
  FElevatedButtonTheme._();

  // Light theme buttons
  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: FColors.secondaryColor,
      foregroundColor: FColors.textWhite,
      // textStyle: FTextTheme.lightTextTheme.headlineLarge!.copyWith(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      elevation: 0,
    ),
  );

  // Dark theme buttons
  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: FColors.buttonPrimary,
      foregroundColor: FColors.textWhite,
      // textStyle: FTextTheme.darkTextTheme.headlineLarge!.copyWith(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      elevation: 0,
    ),
  );
}
