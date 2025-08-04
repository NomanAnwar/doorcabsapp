import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class FElevatedButtonTheme {
  FElevatedButtonTheme._();

  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: FColors.white,
      backgroundColor: FColors.primaryColor,
      disabledForegroundColor: FColors.grey,
      disabledBackgroundColor: FColors.grey,
      side: const BorderSide(color: FColors.white),
      padding: const EdgeInsets.symmetric(vertical: 18),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: FColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    )
  );

  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: FColors.white,
      backgroundColor: FColors.primaryColor,
      disabledForegroundColor: FColors.grey,
      disabledBackgroundColor: FColors.grey,
      side: const BorderSide(color: FColors.white),
      padding: const EdgeInsets.symmetric(vertical: 18),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: FColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    )
  );

}