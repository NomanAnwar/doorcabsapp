import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class FOutlinedButtonTheme{

  FOutlinedButtonTheme._();

  static final lightOutlinedButtonTheme = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: FColors.black,
        side: const BorderSide(color: FColors.primaryColor),
        textStyle: const TextStyle(fontSize: 16, color: FColors.black, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      )
  );

  static final darkOutlinedButtonTheme = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: FColors.white,
        side: const BorderSide(color: FColors.primaryColor),
        textStyle: const TextStyle(fontSize: 16, color: FColors.white, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      )
  );

}